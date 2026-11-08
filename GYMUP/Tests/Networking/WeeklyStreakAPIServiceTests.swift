import Foundation
import XCTest
@testable import GYMUP

final class WeeklyStreakAPIServiceTests: NetworkingTestCase {
    func testResponseDecodesRequiredFieldsAndNullableLastAchievedWeek() throws {
        let response = try decodeResponse(
            #"{"currentStreak":3,"longestStreak":7,"lastAchievedWeek":null,"status":"ACTIVE"}"#
        )

        XCTAssertEqual(response.currentStreak, 3)
        XCTAssertEqual(response.longestStreak, 7)
        XCTAssertNil(response.lastAchievedWeek)
        XCTAssertEqual(response.status, "ACTIVE")
    }

    func testResponseRequiresLastAchievedWeekKey() {
        let data = Data(#"{"currentStreak":3,"longestStreak":7,"status":"ACTIVE"}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(WeeklyStreakResponse.self, from: data))
    }

    func testFetchUsesWeeklyStreakRouteAndDecodesResponse() async throws {
        var capturedRequest: URLRequest?
        installJSONResponse(
            [
                "currentStreak": 3,
                "longestStreak": 7,
                "lastAchievedWeek": "2026-W44",
                "status": "ACTIVE"
            ],
            recordRequest: { capturedRequest = $0 }
        )

        let response = try await WeeklyStreakAPIService(client: makeClient(token: "test-token")).fetch()

        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/streaks/weekly")
        XCTAssertEqual(response.currentStreak, 3)
        XCTAssertEqual(response.longestStreak, 7)
        XCTAssertEqual(response.lastAchievedWeek, "2026-W44")
        XCTAssertEqual(response.status, "ACTIVE")
    }

    private func decodeResponse(_ json: String) throws -> WeeklyStreakResponse {
        try JSONDecoder().decode(WeeklyStreakResponse.self, from: Data(json.utf8))
    }
}
