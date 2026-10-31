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

enum APIClientTestError: Error, LocalizedError {
    case noResponseConfigured
    case requestBodyStreamReadFailed(String)

    var errorDescription: String? {
        switch self {
        case .noResponseConfigured:
            return "No URLProtocol response was configured."
        case let .requestBodyStreamReadFailed(message):
            return "Could not read request body stream: \(message)"
        }
    }
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
            let handlerRequest = try Self.materializeBodyStream(in: request)
            let (response, data) = try activeHandler(handlerRequest)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func materializeBodyStream(in request: URLRequest) throws -> URLRequest {
        guard request.httpBody == nil, let bodyStream = request.httpBodyStream else {
            return request
        }

        let shouldCloseStream = bodyStream.streamStatus == .notOpen
        if shouldCloseStream {
            bodyStream.open()
        }
        defer {
            if shouldCloseStream {
                bodyStream.close()
            }
        }

        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 16_384)

        while true {
            let bytesRead = buffer.withUnsafeMutableBufferPointer { bufferPointer in
                guard let baseAddress = bufferPointer.baseAddress else {
                    return 0
                }
                return bodyStream.read(baseAddress, maxLength: bufferPointer.count)
            }

            if bytesRead < 0 {
                let message = bodyStream.streamError?.localizedDescription
                    ?? "InputStream.read returned a negative result."
                throw APIClientTestError.requestBodyStreamReadFailed(message)
            }

            guard bytesRead > 0 else {
                if let streamError = bodyStream.streamError {
                    throw APIClientTestError.requestBodyStreamReadFailed(streamError.localizedDescription)
                }
                guard bodyStream.streamStatus == .atEnd else {
                    throw APIClientTestError.requestBodyStreamReadFailed(
                        "InputStream stopped before reaching the end of the stream."
                    )
                }
                break
            }

            body.append(contentsOf: buffer.prefix(bytesRead))
        }

        var materializedRequest = request
        materializedRequest.httpBody = body
        materializedRequest.httpBodyStream = nil
        return materializedRequest
    }
}

final class StubURLProtocol: StubURLProtocolBase {}
