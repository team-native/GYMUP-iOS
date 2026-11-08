import Foundation
import XCTest
@testable import GYMUP

final class CurrentWeeklyGoalAPIServiceTests: NetworkingTestCase {
    func testResponseDecodesWeeklyGoalFields() throws {
        let json = #"{"weekStart":"2026-11-02","weekEnd":"2026-11-08","targetCount":4,"completedCount":2,"achieved":false}"#
        let response = try JSONDecoder().decode(CurrentWeeklyGoalResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.weekStart, "2026-11-02")
        XCTAssertEqual(response.weekEnd, "2026-11-08")
        XCTAssertEqual(response.targetCount, 4)
        XCTAssertEqual(response.completedCount, 2)
        XCTAssertFalse(response.achieved)
    }

    func testFetchUsesRouteTimezoneQueryAndDecodesResponse() async throws {
        var capturedRequest: URLRequest?
        installJSONResponse(
            [
                "weekStart": "2026-11-02",
                "weekEnd": "2026-11-08",
                "targetCount": 4,
                "completedCount": 4,
                "achieved": true
            ],
            recordRequest: { capturedRequest = $0 }
        )

        let response = try await CurrentWeeklyGoalAPIService(client: makeClient(token: "test-token"))
            .fetch(timeZoneIdentifier: "Asia/Seoul")

        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/goals/weekly/current")
        XCTAssertEqual(URLComponents(url: try XCTUnwrap(capturedRequest?.url), resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "timezone" })?.value, "Asia/Seoul")
        XCTAssertEqual(response.targetCount, 4)
        XCTAssertEqual(response.completedCount, 4)
        XCTAssertTrue(response.achieved)
    }
}
