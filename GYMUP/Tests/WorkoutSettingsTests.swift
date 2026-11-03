import Foundation
import XCTest
@testable import GYMUP

@MainActor
final class WorkoutSettingsTests: XCTestCase {
    func testSettingsSurviveRecreation() throws {
        let suite = "settings-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = WorkoutSettings(defaults: defaults, schedulesNotifications: false)
        settings.restSeconds = 120
        settings.preferences.hapticsEnabled = false
        settings.preferences.restTimerEnabled = false
        settings.preferences.workoutReminderEnabled = false
        settings.schedule.weekdays = [3, 7]
        let restored = WorkoutSettings(defaults: defaults, schedulesNotifications: false)
        XCTAssertEqual(restored.restSeconds, 120)
        XCTAssertFalse(restored.preferences.hapticsEnabled)
        XCTAssertFalse(restored.preferences.restTimerEnabled)
        XCTAssertFalse(restored.preferences.workoutReminderEnabled)
        XCTAssertEqual(restored.schedule.weekdays, [3, 7])
    }

    func testReminderComponentsUseSelectedWeekdaysAndTimeOnly() throws {
        let time = try XCTUnwrap(Calendar.current.date(from: DateComponents(hour: 21, minute: 35)))
        let components = WorkoutSettings.reminderComponents(schedule: ProfileReminderSchedule(weekdays: [1, 4], time: time))
        XCTAssertEqual(components.map(\.weekday), [4, 1])
        XCTAssertTrue(components.allSatisfy { $0.hour == 21 && $0.minute == 35 && $0.day == nil })
        XCTAssertTrue(WorkoutSettings.reminderComponents(schedule: ProfileReminderSchedule(weekdays: [], time: time)).isEmpty)
    }

    func testRestTimeSavePreservesLocalValueAndServerMessageAndRetriesSameSeconds() async throws {
        var capturedRequests: [URLRequest] = []
        var requestCount = 0
        let serverMessage = "기본 휴식 시간 범위를 확인해 주세요."
        StubURLProtocol.install { request in
            capturedRequests.append(request)
            requestCount += 1
            let statusCode = requestCount == 1 ? 400 : 200
            let body: String
            if requestCount == 1 {
                body = #"{"detail":{"code":"OUT_OF_RANGE","message":"기본 휴식 시간 범위를 확인해 주세요."}}"#
            } else {
                body = #"{"defaultRestSeconds":135,"updatedAt":"2026-10-31T09:00:00Z"}"#
            }
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, Data(body.utf8))
        }
        defer {
            StubURLProtocol.install { _ in
                throw APIClientTestError.noResponseConfigured
            }
        }

        let suite = "rest-time-api-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = WorkoutSettings(defaults: defaults, schedulesNotifications: false)
        let selectedSeconds = 135
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = APIClient(
            environment: try APIEnvironment(baseURL: XCTUnwrap(URL(string: "https://api.example.test"))),
            session: session,
            tokenProvider: TestTokenProvider(token: "test-token")
        )
        let viewModel = ProfileRestTimeViewModel(service: UserSettingsAPIService(client: client))

        let didSave = await viewModel.save(seconds: selectedSeconds) { settings.restSeconds = $0 }

        XCTAssertFalse(didSave)
        XCTAssertEqual(settings.restSeconds, selectedSeconds)
        XCTAssertEqual(
            WorkoutSettings(defaults: defaults, schedulesNotifications: false).restSeconds,
            selectedSeconds
        )
        XCTAssertEqual(viewModel.errorMessage, serverMessage)
        XCTAssertEqual(viewModel.retrySeconds, selectedSeconds)
        XCTAssertTrue(viewModel.canRetry)
        XCTAssertEqual(capturedRequests.count, 1)

        let didRetry = await viewModel.retry()

        XCTAssertTrue(didRetry)
        XCTAssertEqual(settings.restSeconds, selectedSeconds)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.retrySeconds)
        XCTAssertFalse(viewModel.canRetry)
        XCTAssertEqual(capturedRequests.count, 2)

        let requestPayloads = try capturedRequests.map { request -> [String: Int] in
            let body = try XCTUnwrap(request.httpBody)
            return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Int])
        }
        XCTAssertEqual(capturedRequests.map(\.httpMethod), ["PATCH", "PATCH"])
        XCTAssertEqual(
            capturedRequests.map { $0.url?.path },
            ["/api/v1/users/me/settings/rest-time", "/api/v1/users/me/settings/rest-time"]
        )
        XCTAssertEqual(requestPayloads, [["defaultRestSeconds": selectedSeconds], ["defaultRestSeconds": selectedSeconds]])
    }
}
