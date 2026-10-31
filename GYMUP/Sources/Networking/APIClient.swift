import Foundation

protocol BearerTokenProviding {
    func accessToken() async throws -> String?
}

struct APIClient {
    private let environment: APIEnvironment
    private let session: URLSession
    private let tokenProvider: BearerTokenProviding
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        environment: APIEnvironment,
        session: URLSession = .shared,
        tokenProvider: BearerTokenProviding,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.environment = environment
        self.session = session
        self.tokenProvider = tokenProvider
        self.encoder = encoder
        self.decoder = decoder
    }

    func send<Body: Encodable, Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Body,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        let bodyData = try encoder.encode(body)
        return try await send(endpoint, bodyData: bodyData, as: responseType)
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        try await send(endpoint, bodyData: nil, as: responseType)
    }

    private func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        bodyData: Data?,
        as responseType: Response.Type
    ) async throws -> Response {
        let url = try environment.url(for: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bodyData {
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        for (name, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        if endpoint.requiresBearerToken {
            guard let token = try await tokenProvider.accessToken(), !token.isEmpty else {
                throw APIClientError.missingBearerToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200..<300).contains(response.statusCode) else {
            if let envelope = try? decoder.decode(ServerErrorEnvelope.self, from: data) {
                throw APIClientError.server(statusCode: response.statusCode, detail: envelope.detail)
            }
            throw APIClientError.unexpectedStatusCode(response.statusCode)
        }

        if let expectedStatusCode = endpoint.expectedStatusCode, response.statusCode != expectedStatusCode {
            throw APIClientError.unexpectedStatusCode(response.statusCode)
        }

        return try decoder.decode(responseType, from: data)
    }
}
