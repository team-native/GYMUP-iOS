import Foundation
import XCTest
@testable import GYMUP

final class DevelopmentTokenProviderTests: NetworkingTestCase {
    func testRequestsAndCachesLocalDevelopmentTokenWithoutBearerHeader() async throws {
        var capturedRequests: [URLRequest] = []
        StubURLProtocol.install { request in
            capturedRequests.append(request)
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            let body = #"{"accessToken":"debug-token","tokenType":"Bearer","expiresAt":"2099-12-31T23:59:59Z"}"#
            return (response, Data(body.utf8))
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let environment = try APIEnvironment(baseURL: XCTUnwrap(URL(string: "http://localhost:8000")))
        let provider = DevelopmentBearerTokenProvider(
            environment: environment,
            session: URLSession(configuration: configuration)
        )

        let firstToken = try await provider.accessToken()
        let cachedToken = try await provider.accessToken()
        let request = try XCTUnwrap(capturedRequests.first)
        let body = try XCTUnwrap(request.httpBody)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])

        XCTAssertEqual(firstToken, "debug-token")
        XCTAssertEqual(cachedToken, firstToken)
        XCTAssertEqual(capturedRequests.count, 1)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/v1/auth/dev-token")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(object, ["userId": "local-user"])
    }
}
