import Foundation
import XCTest
@testable import GYMUP

final class UserAPIServiceTests: NetworkingTestCase {
    func testOnboardingServiceUsesDocumentedPUTContract() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let json = #"""
            {
              "userId": "user-1",
              "profileCompleted": true,
              "experienceLevel": {"level": "starter"},
              "goalType": "strength",
              "weeklyWorkoutTarget": 3
            }
            """#
            return (response, Data(json.utf8))
        }
        let request = SaveOnboardingRequest(
            experienceLevel: .object(["level": .string("starter")]),
            goalType: .string("strength"),
            weeklyWorkoutTarget: 3
        )

        let response = try await OnboardingAPIService(client: makeClient(token: "test-token")).save(request)

        XCTAssertEqual(capturedRequest?.httpMethod, "PUT")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/users/me/onboarding")
        XCTAssertEqual(response.userId, "user-1")
        XCTAssertTrue(response.profileCompleted)
        XCTAssertEqual(response.experienceLevel, .object(["level": .string("starter")]))
        XCTAssertEqual(response.goalType, .string("strength"))
        XCTAssertEqual(response.weeklyWorkoutTarget, 3)
        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(object["weeklyWorkoutTarget"] as? Int, 3)
        XCTAssertEqual(Set(object.keys), Set(["experienceLevel", "goalType", "weeklyWorkoutTarget"]))
    }
    func testDefaultRestTimeServiceUsesSecondsAndDecodesTimestamp() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, Data(#"{"defaultRestSeconds":90,"updatedAt":"2026-10-31T09:00:00Z"}"#.utf8))
        }

        let response = try await UserSettingsAPIService(client: makeClient(token: "test-token"))
            .updateDefaultRestTime(seconds: 90)

        XCTAssertEqual(capturedRequest?.httpMethod, "PATCH")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/users/me/settings/rest-time")
        XCTAssertEqual(response, UpdateDefaultRestTimeResponse(defaultRestSeconds: 90, updatedAt: "2026-10-31T09:00:00Z"))
        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Int])
        XCTAssertEqual(object, ["defaultRestSeconds": 90])
    }
}
