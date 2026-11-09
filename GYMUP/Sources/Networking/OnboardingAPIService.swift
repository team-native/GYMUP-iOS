import Foundation

struct SaveOnboardingRequest: Codable, Equatable {
    let experienceLevel: JSONValue
    let goalType: JSONValue
    let weeklyWorkoutTarget: Int
}

struct SaveOnboardingResponse: Codable, Equatable {
    let userId: String
    let profileCompleted: Bool
    let experienceLevel: JSONValue
    let goalType: JSONValue
    let weeklyWorkoutTarget: Int
}

struct OnboardingAPIService {
    private let client: APIClient
    private let goalService: GoalAPIService

    init(client: APIClient) {
        self.client = client
        goalService = GoalAPIService(client: client)
    }

    func save(_ request: SaveOnboardingRequest) async throws -> SaveOnboardingResponse {
        let endpoint = APIEndpoint(method: .put, path: "/api/v1/users/me/onboarding", expectedStatusCode: 200)
        return try await client.send(endpoint, body: request, as: SaveOnboardingResponse.self)
    }

    func createGoal(_ request: CreateGoalRequest) async throws {
        try await goalService.create(request)
    }
}
