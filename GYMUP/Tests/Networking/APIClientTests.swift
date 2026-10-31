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

    func testMaterializesBodyStreamAndPreservesRequestMetadata() throws {
        let body = Data(#"{"value":"streamed"}"#.utf8)
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://api.example.test/upload")))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("request-456", forHTTPHeaderField: "Idempotency-Key")
        request.httpBodyStream = InputStream(data: body)

        let normalizedRequest = try StubURLProtocol.materializeBodyStream(in: request)

        XCTAssertEqual(normalizedRequest.httpBody, body)
        XCTAssertNil(normalizedRequest.httpBodyStream)
        XCTAssertEqual(normalizedRequest.url, request.url)
        XCTAssertEqual(normalizedRequest.httpMethod, "PATCH")
        XCTAssertEqual(normalizedRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(normalizedRequest.value(forHTTPHeaderField: "Idempotency-Key"), "request-456")
    }

    func testReadsAnAlreadyOpenBodyStreamFromItsCurrentPosition() throws {
        let stream = InputStream(data: Data("discarded-body".utf8))
        stream.open()
        defer { stream.close() }
        var prefix = [UInt8](repeating: 0, count: 10)
        let prefixBytesRead = prefix.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return 0
            }
            return stream.read(baseAddress, maxLength: buffer.count)
        }
        XCTAssertEqual(prefixBytesRead, 10)

        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://api.example.test/upload")))
        request.httpBodyStream = stream
        let normalizedRequest = try StubURLProtocol.materializeBodyStream(in: request)

        XCTAssertEqual(normalizedRequest.httpBody, Data("body".utf8))
        XCTAssertNil(normalizedRequest.httpBodyStream)
    }

    func testReportsZeroBytesBeforeBodyStreamReachesEOF() throws {
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://api.example.test/upload")))
        request.httpBodyStream = EmptyBeforeEOFRequestBodyStream(data: Data())

        XCTAssertThrowsError(try StubURLProtocol.materializeBodyStream(in: request)) { error in
            guard case let APIClientTestError.requestBodyStreamReadFailed(message) = error else {
                XCTFail("Expected request body stream read failure, got \(error)")
                return
            }
            XCTAssertEqual(message, "InputStream stopped before reaching the end of the stream.")
        }
    }

    func testReportsBodyStreamReadFailure() throws {
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://api.example.test/upload")))
        request.httpBodyStream = FailingRequestBodyStream(data: Data())

        XCTAssertThrowsError(try StubURLProtocol.materializeBodyStream(in: request)) { error in
            guard case let APIClientTestError.requestBodyStreamReadFailed(message) = error else {
                XCTFail("Expected request body stream read failure, got \(error)")
                return
            }
            XCTAssertEqual(message, "fixture stream read failure")
        }
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

private final class FailingRequestBodyStream: InputStream {
    override init(data: Data) {
        super.init(data: data)
    }

    override func open() {}

    override func close() {}

    override var streamStatus: Stream.Status {
        .open
    }

    override var hasBytesAvailable: Bool {
        true
    }

    override var streamError: Error? {
        NSError(
            domain: "NetworkingTest",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "fixture stream read failure"]
        )
    }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        -1
    }
}

private final class EmptyBeforeEOFRequestBodyStream: InputStream {
    override init(data: Data) {
        super.init(data: data)
    }

    override func open() {}

    override func close() {}

    override var streamStatus: Stream.Status {
        .open
    }

    override var hasBytesAvailable: Bool {
        true
    }

    override var streamError: Error? {
        nil
    }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        0
    }
}
