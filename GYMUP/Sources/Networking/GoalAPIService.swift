import Foundation

struct CreateGoalRequest: Codable, Equatable {
    let goalType: String
    let startDate: String
    let endDate: String
    let weeklyWorkoutTarget: Int
}

struct CompleteGoalRequest: Codable, Equatable {
    let expectedVersion: Int
}

struct CompleteGoalResponse: Decodable, Equatable {
    let goalId: String
    let status: String
    let peakFormUnlocked: Bool
    let rewards: JSONValue
    let completedAt: String
}

struct ActiveGoalProgressResponse: Decodable, Equatable {
    let goalId: String?
    let growth: Int
}

protocol ActiveGoalProgressReading {
    func fetchActiveProgress() async throws -> ActiveGoalProgressResponse
}

protocol GoalCompleting {
    func completeGoal(goalId: String, request: CompleteGoalRequest) async throws -> CompleteGoalResponse
}

struct GoalAPIService: ActiveGoalProgressReading, GoalCompleting {
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

    func completeGoal(goalId: String, request: CompleteGoalRequest) async throws -> CompleteGoalResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/goals/\(goalId)/complete",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, body: request, as: CompleteGoalResponse.self)
    }
}
