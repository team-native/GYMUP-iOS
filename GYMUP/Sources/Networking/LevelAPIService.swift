import Foundation

struct UserLevelResponse: Decodable, Equatable {
    let level: Int
    let currentXp: Int
    let nextLevelXp: Int
    let progressPercent: Double
    let lastLevelUpAt: String
}

protocol UserLevelReading {
    func fetch() async throws -> UserLevelResponse
}

struct LevelAPIService: UserLevelReading {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetch() async throws -> UserLevelResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/users/me/level",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: UserLevelResponse.self)
    }
}
