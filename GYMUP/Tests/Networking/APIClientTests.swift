import Foundation
import XCTest
@testable import GYMUP

final class APIClientTests: NetworkingTestCase {
    func testBuildsJSONRequestWithBearerAndCallerHeaders() async throws {
        let body = TestRequest(value: "sample")
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            return (response, Data(#"{"result":"saved"}"#.utf8))
        }

        let endpoint = APIEndpoint(
            method: .put,
            path: "/api/v1/users/me/onboarding",
            headers: ["Idempotency-Key": "request-123"]
        )
        let response = try await makeClient(token: "test-token").send(endpoint, body: body, as: TestResponse.self)

        XCTAssertEqual(response, TestResponse(result: "saved"))
        XCTAssertEqual(capturedRequest?.httpMethod, "PUT")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/users/me/onboarding")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Idempotency-Key"), "request-123")
        XCTAssertEqual(try JSONDecoder().decode(TestRequest.self, from: XCTUnwrap(capturedRequest?.httpBody)), body)
    }
    func testPreservesServerErrorCodeAndMessage() async throws {
        StubURLProtocol.install { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, Data(#"{"detail":{"code":"OUT_OF_RANGE","message":"Rest time is invalid."}}"#.utf8))
        }

        do {
            _ = try await makeClient(token: "test-token").send(
                APIEndpoint(method: .patch, path: "/api/v1/users/me/settings/rest-time"),
                body: TestRequest(value: "sample"),
                as: TestResponse.self
            )
            XCTFail("Expected the server error to be thrown")
        } catch let error as APIClientError {
            XCTAssertEqual(
                error,
                .server(
                    statusCode: 400,
                    detail: ServerErrorDetail(code: "OUT_OF_RANGE", message: "Rest time is invalid.")
                )
            )
        }
    }
    func testRejectsUnexpectedSuccessfulStatusCodeWhenEndpointSpecifiesOne() async throws {
        do {
            _ = try await makeClient(token: "test-token").send(
                APIEndpoint(method: .post, path: "/api/v1/workouts", expectedStatusCode: 201),
                body: TestRequest(value: "sample"),
                as: TestResponse.self
            )
            XCTFail("Expected a status-code mismatch")
        } catch let error as APIClientError {
            XCTAssertEqual(error, .unexpectedStatusCode(200))
        }
    }
    func testDoesNotSendAuthenticatedRequestWithoutToken() async throws {
        var requestWasSent = false
        StubURLProtocol.install { request in
            requestWasSent = true
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, Data(#"{"result":"ok"}"#.utf8))
        }

        do {
            _ = try await makeClient(token: nil).send(
                APIEndpoint(method: .get, path: "/api/v1/test"),
                as: TestResponse.self
            )
            XCTFail("Expected a missing token error")
        } catch let error as APIClientError {
            XCTAssertEqual(error, .missingBearerToken)
        }

        XCTAssertFalse(requestWasSent)
    }
    func testBuildsURLWithBasePathAndQueryItems() throws {
        let baseURL = try XCTUnwrap(URL(string: "https://api.example.test/gateway/"))
        let environment = try APIEnvironment(baseURL: baseURL)
        let endpoint = APIEndpoint(
            method: .get,
            path: "api/v1/workouts",
            queryItems: [URLQueryItem(name: "cursor", value: "next-page"), URLQueryItem(name: "limit", value: "20")]
        )

        let components = try XCTUnwrap(URLComponents(url: environment.url(for: endpoint), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.path, "/gateway/api/v1/workouts")
        XCTAssertEqual(components.queryItems, endpoint.queryItems)
    }
    func testRejectsURLWithoutHTTPHost() throws {
        let fileURL = try XCTUnwrap(URL(string: "file:///tmp/api"))

        XCTAssertThrowsError(try APIEnvironment(baseURL: fileURL)) { error in
            XCTAssertEqual(error as? APIClientError, .invalidBaseURL)
        }
    }
}
