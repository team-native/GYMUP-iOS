import Foundation

struct WorkoutDetailSet: Codable, Equatable {
    let reps: Int
    let weight: Double
    let pr: Bool
}

struct WorkoutDetailExercise: Codable, Equatable {
    let sets: [WorkoutDetailSet]
}

struct WorkoutDetailResponse: Codable, Equatable {
    let workoutId: String
    let routine: JSONValue
    let duration: Int
    let totalSets: Int
    let volume: Double
    let exercises: [WorkoutDetailExercise]
}

struct WorkoutSummaryResponse: Codable, Equatable {
    let duration: Int
    let totalSets: Int
    let volume: Double
    let prs: JSONValue
    let growthDelta: JSONValue
    let xp: Int
    let levelUp: JSONValue
    let avatarGrowth: JSONValue
    let progressShotAvailable: Bool
}

struct CompleteWorkoutRequest: Codable, Equatable {
    let endedAt: String
    let expectedVersion: Int
}

enum CompletedWorkoutStatus: String, Codable {
    case completed = "COMPLETED"
}

struct CompleteWorkoutResponse: Codable, Equatable {
    let workoutId: String
    let status: CompletedWorkoutStatus
    let duration: Int
    let totalSets: Int
    let volume: Double
    let prs: JSONValue
    let xp: Int
    let growthDelta: JSONValue
}

struct WorkoutHistoryAPIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func detail(workoutId: String) async throws -> WorkoutDetailResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/workouts/\(workoutId)",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: WorkoutDetailResponse.self)
    }

    func summary(workoutId: String) async throws -> WorkoutSummaryResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/workouts/\(workoutId)/summary",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: WorkoutSummaryResponse.self)
    }

    func complete(workoutId: String, request: CompleteWorkoutRequest) async throws -> CompleteWorkoutResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/workouts/\(workoutId)/complete",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, body: request, as: CompleteWorkoutResponse.self)
    }
}
