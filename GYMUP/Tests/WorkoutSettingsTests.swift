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

    func testRestTimeSaveKeepsLocalValueAndShowsServerMessageOnFailure() async throws {
        let scenario = try makeRestTimeScenario()
        defer {
            resetStubResponse()
            scenario.defaults.removePersistentDomain(forName: scenario.suite)
        }

        let didSave = await scenario.viewModel.save(seconds: scenario.selectedSeconds) {
            scenario.settings.restSeconds = $0
        }

        XCTAssertFalse(didSave)
        XCTAssertEqual(scenario.settings.restSeconds, scenario.selectedSeconds)
        let restored = WorkoutSettings(defaults: scenario.defaults, schedulesNotifications: false)
        XCTAssertEqual(restored.restSeconds, scenario.selectedSeconds)
        XCTAssertEqual(scenario.viewModel.errorMessage, scenario.serverMessage)
        XCTAssertEqual(scenario.viewModel.retrySeconds, scenario.selectedSeconds)
        XCTAssertTrue(scenario.viewModel.canRetry)
        XCTAssertEqual(scenario.requests.requests.count, 1)
        try assertRestTimeRequest(scenario.requests.requests[0], seconds: scenario.selectedSeconds)
    }

    func testRestTimeRetrySendsSameSecondsAfterFailure() async throws {
        let scenario = try makeRestTimeScenario()
        defer {
            resetStubResponse()
            scenario.defaults.removePersistentDomain(forName: scenario.suite)
        }

        let didSave = await scenario.viewModel.save(seconds: scenario.selectedSeconds) {
            scenario.settings.restSeconds = $0
        }
        let didRetry = await scenario.viewModel.retry()

        XCTAssertFalse(didSave)
        XCTAssertTrue(didRetry)
        XCTAssertEqual(scenario.settings.restSeconds, scenario.selectedSeconds)
        XCTAssertNil(scenario.viewModel.errorMessage)
        XCTAssertNil(scenario.viewModel.retrySeconds)
        XCTAssertFalse(scenario.viewModel.canRetry)
        XCTAssertEqual(scenario.requests.requests.count, 2)
        for request in scenario.requests.requests {
            try assertRestTimeRequest(request, seconds: scenario.selectedSeconds)
        }
    }

    private func makeRestTimeScenario() throws -> RestTimeScenario {
        let requests = RestTimeRequestRecorder()
        installRestTimeResponses(capturing: requests)
        let suite = "rest-time-api-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let settings = WorkoutSettings(defaults: defaults, schedulesNotifications: false)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let environment = try APIEnvironment(baseURL: XCTUnwrap(URL(string: "https://api.example.test")))
        let client = APIClient(
            environment: environment,
            session: session,
            tokenProvider: TestTokenProvider(token: "test-token")
        )
        let viewModel = ProfileRestTimeViewModel(service: UserSettingsAPIService(client: client))
        return RestTimeScenario(
            suite: suite,
            defaults: defaults,
            settings: settings,
            viewModel: viewModel,
            requests: requests
        )
    }

    private func installRestTimeResponses(capturing requests: RestTimeRequestRecorder) {
        var requestCount = 0
        StubURLProtocol.install { request in
            requests.requests.append(request)
            requestCount += 1
            let statusCode = requestCount == 1 ? 400 : 200
            let body = requestCount == 1
                ? #"{"detail":{"code":"OUT_OF_RANGE","message":"기본 휴식 시간 범위를 확인해 주세요."}}"#
                : #"{"defaultRestSeconds":135,"updatedAt":"2026-10-31T09:00:00Z"}"#
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
    }

    private func assertRestTimeRequest(_ request: URLRequest, seconds: Int) throws {
        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.url?.path, "/api/v1/users/me/settings/rest-time")
        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Int])
        XCTAssertEqual(payload, ["defaultRestSeconds": seconds])
    }

    private func resetStubResponse() {
        StubURLProtocol.install { _ in
            throw APIClientTestError.noResponseConfigured
        }
    }
}

private final class RestTimeRequestRecorder {
    var requests: [URLRequest] = []
}

private struct RestTimeScenario {
    let suite: String
    let defaults: UserDefaults
    let settings: WorkoutSettings
    let viewModel: ProfileRestTimeViewModel
    let requests: RestTimeRequestRecorder
    let selectedSeconds = 135
    let serverMessage = "기본 휴식 시간 범위를 확인해 주세요."
}
