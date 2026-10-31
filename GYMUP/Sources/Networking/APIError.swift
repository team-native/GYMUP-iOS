import Foundation

struct ServerErrorEnvelope: Decodable, Equatable {
    let detail: ServerErrorDetail
}

struct ServerErrorDetail: Decodable, Equatable {
    let code: String
    let message: String
}

enum APIClientError: Error, Equatable {
    case invalidBaseURL
    case invalidURL
    case invalidResponse
    case missingBearerToken
    case server(statusCode: Int, detail: ServerErrorDetail)
    case unexpectedStatusCode(Int)
}
