import Foundation

struct CreateGoalRequest: Codable, Equatable {
    let goalType: String
    let startDate: String
    let endDate: String
    let weeklyWorkoutTarget: Int
}

struct ActiveGoalProgressResponse: Decodable, Equatable {
    let growth: Int
}

protocol ActiveGoalProgressReading {
    func fetchActiveProgress() async throws -> ActiveGoalProgressResponse
}

struct GoalAPIService: ActiveGoalProgressReading {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func create(_ request: CreateGoalRequest) async throws {
        let endpoint = APIEndpoint(method: .post, path: "/api/v1/goals")
        let _: JSONValue = try await client.send(endpoint, body: request, as: JSONValue.self)
    }

    func fetchActiveProgress() async throws -> ActiveGoalProgressResponse {
        let endpoint = APIEndpoint(method: .get, path: "/api/v1/goals/active/progress")
        let response = try await client.send(endpoint, as: ActiveGoalProgressResponse.self)
        guard (0...100).contains(response.growth) else {
            throw APIClientError.invalidResponse
        }
        return response
    }
}
