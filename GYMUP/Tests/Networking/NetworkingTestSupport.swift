import Foundation
import XCTest
@testable import GYMUP

class NetworkingTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        StubURLProtocol.install { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, Data(#"{"result":"ok"}"#.utf8))
        }
    }

    override func tearDown() {
        StubURLProtocol.install { _ in
            throw APIClientTestError.noResponseConfigured
        }
        super.tearDown()
    }

    func makeClient(token: String?) throws -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let baseURL = try XCTUnwrap(URL(string: "https://api.example.test"))
        return APIClient(
            environment: try APIEnvironment(baseURL: baseURL),
            session: session,
            tokenProvider: TestTokenProvider(token: token)
        )
    }

    func installJSONResponse(
        _ object: Any,
        statusCode: Int = 200,
        recordRequest: @escaping (URLRequest) -> Void = { _ in }
    ) {
        StubURLProtocol.install { request in
            recordRequest(request)
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, try JSONSerialization.data(withJSONObject: object))
        }
    }

    func installJSONResponses(
        _ responses: [String: (Int, Any)],
        recordRequest: @escaping (URLRequest) -> Void = { _ in }
    ) {
        StubURLProtocol.install { request in
            recordRequest(request)
            let path = try XCTUnwrap(request.url?.path)
            let (statusCode, object) = try XCTUnwrap(responses[path])
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, try JSONSerialization.data(withJSONObject: object))
        }
    }
}

struct TestRequest: Codable, Equatable {
    let value: String
}

struct TestResponse: Decodable, Equatable {
    let result: String
}

struct TestTokenProvider: BearerTokenProviding {
    let token: String?

    func accessToken() async throws -> String? {
        token
    }
}

enum APIClientTestError: Error {
    case noResponseConfigured
}

class StubURLProtocolBase: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    private static var handler: Handler = { _ in throw APIClientTestError.noResponseConfigured }

    static func install(_ newHandler: @escaping Handler) {
        lock.lock()
        defer { lock.unlock() }
        handler = newHandler
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        let activeHandler = Self.handler
        Self.lock.unlock()

        do {
            let (response, data) = try activeHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class StubURLProtocol: StubURLProtocolBase {}
