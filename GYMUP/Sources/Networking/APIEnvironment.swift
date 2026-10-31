import Foundation

struct APIEnvironment: Equatable {
    let baseURL: URL

    init(baseURL: URL) throws {
        guard
            let scheme = baseURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            baseURL.host != nil,
            baseURL.user == nil,
            baseURL.password == nil,
            baseURL.query == nil,
            baseURL.fragment == nil
        else {
            throw APIClientError.invalidBaseURL
        }

        self.baseURL = baseURL
    }

    func url(for endpoint: APIEndpoint) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIClientError.invalidBaseURL
        }

        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        let endpointPath = endpoint.path.hasPrefix("/") ? endpoint.path : "/\(endpoint.path)"
        components.path = "\(basePath)\(endpointPath)"

        if !endpoint.queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + endpoint.queryItems
        }

        guard let url = components.url else {
            throw APIClientError.invalidURL
        }
        return url
    }
}
