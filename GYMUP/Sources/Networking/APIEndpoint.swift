import Foundation

enum APIHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint {
    let method: APIHTTPMethod
    let path: String
    var queryItems: [URLQueryItem]
    var headers: [String: String]
    var requiresBearerToken: Bool
    var expectedStatusCode: Int?

    init(
        method: APIHTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        requiresBearerToken: Bool = true,
        expectedStatusCode: Int? = nil
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.requiresBearerToken = requiresBearerToken
        self.expectedStatusCode = expectedStatusCode
    }
}
