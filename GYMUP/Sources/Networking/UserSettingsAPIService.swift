import Foundation

struct UpdateDefaultRestTimeRequest: Codable, Equatable {
    let defaultRestSeconds: Int
}

struct UpdateDefaultRestTimeResponse: Codable, Equatable {
    let defaultRestSeconds: Int
    let updatedAt: String
}

struct UserSettingsAPIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func updateDefaultRestTime(seconds: Int) async throws -> UpdateDefaultRestTimeResponse {
        let endpoint = APIEndpoint(
            method: .patch,
            path: "/api/v1/users/me/settings/rest-time",
            expectedStatusCode: 200
        )
        let request = UpdateDefaultRestTimeRequest(defaultRestSeconds: seconds)
        return try await client.send(endpoint, body: request, as: UpdateDefaultRestTimeResponse.self)
    }
}
