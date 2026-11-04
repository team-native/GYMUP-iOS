import Foundation
import XCTest
@testable import GYMUP

final class PlateCalculatorAPIServiceTests: NetworkingTestCase {
    func testCalculatePostsDocumentedRequestAndDecodesSuccessResponse() async throws {
        var capturedRequest: URLRequest?
        installJSONResponse(
            [
                "achievable": true,
                "eachSide": [["weight": 20.0, "count": 2]],
                "actualWeight": 100.0,
                "remainder": 0.0
            ],
            recordRequest: { capturedRequest = $0 }
        )

        let request = PlateCalculatorRequest(
            targetWeight: 100,
            barWeight: 20,
            availablePlates: [25, 20, 15, 10, 5, 2.5, 1.25].map(JSONValue.number)
        )
        let service = try PlateCalculatorAPIService(client: makeClient(token: "test-token"))
        let response = try await service.calculate(request)

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/tools/plate-calculator")
        XCTAssertTrue(response.achievable)
        XCTAssertEqual(response.eachSide, [PlateWeightCount(weight: 20, count: 2)])
        XCTAssertEqual(response.actualWeight, 100)
        XCTAssertEqual(response.remainder, 0)

        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(object["targetWeight"] as? Double, 100)
        XCTAssertEqual(object["barWeight"] as? Double, 20)
        XCTAssertEqual(object["availablePlates"] as? [Double], [25, 20, 15, 10, 5, 2.5, 1.25])
    }
}
