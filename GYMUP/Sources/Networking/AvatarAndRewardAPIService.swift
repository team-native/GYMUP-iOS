import Foundation

struct WorkoutRewardResponse: Decodable, Equatable {
    let workoutId: String
    let experiencePoints: Int
    let growthDelta: Int
    let bonuses: JSONValue
    let grantedAt: String

    enum CodingKeys: String, CodingKey {
        case workoutId
        case experiencePoints = "xp"
        case growthDelta
        case bonuses
        case grantedAt
    }
}

protocol WorkoutRewardReading {
    func fetch(workoutId: String) async throws -> WorkoutRewardResponse
}

struct WorkoutRewardAPIService: WorkoutRewardReading {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetch(workoutId: String) async throws -> WorkoutRewardResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/rewards/workouts/\(workoutId)",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: WorkoutRewardResponse.self)
    }
}

struct AvatarItemsQuery {
    let status: String
    let cursor: String?
    let size: Int

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "size", value: String(size))
        ]
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return items
    }
}

struct AvatarItemsResponse: Decodable, Equatable {
    let items: [JSONValue]
    let nextCursor: String?
}

struct AvatarGrowthStageResponse: Decodable, Equatable {
    let growth: Int
    let stage: String
    let minGrowth: Int
    let maxGrowth: Int
    let modelKey: String
    let morphValue: Double
}

struct AvatarResponse: Decodable, Equatable {
    let level: Int
    let growth: Int
    let stage: String
    let modelKey: String
    let morphValue: Double
    let equippedItems: [JSONValue]
    let weeklyGoal: Int
}

protocol AvatarReading {
    func fetchAvatar() async throws -> AvatarResponse
    func fetchGrowthStage() async throws -> AvatarGrowthStageResponse
    func fetchItems(_ query: AvatarItemsQuery) async throws -> AvatarItemsResponse
}

struct AvatarAPIService: AvatarReading {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchAvatar() async throws -> AvatarResponse {
        let endpoint = APIEndpoint(method: .get, path: "/api/v1/avatar", expectedStatusCode: 200)
        return try await client.send(endpoint, as: AvatarResponse.self)
    }

    func fetchGrowthStage() async throws -> AvatarGrowthStageResponse {
        let endpoint = APIEndpoint(method: .get, path: "/api/v1/avatar/growth-stage", expectedStatusCode: 200)
        return try await client.send(endpoint, as: AvatarGrowthStageResponse.self)
    }

    func fetchItems(_ query: AvatarItemsQuery) async throws -> AvatarItemsResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/avatar/items",
            queryItems: query.queryItems,
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: AvatarItemsResponse.self)
    }
}
