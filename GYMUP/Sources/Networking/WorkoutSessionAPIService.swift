import Foundation

struct SkipCurrentRestResponse: Codable, Equatable {
    let restId: String
    let status: SkippedRestStatus
    let nextSet: JSONValue
}

enum SkippedRestStatus: String, Codable {
    case skipped = "SKIPPED"
}

struct StartRestRequest: Codable, Equatable {
    let setId: String
    let durationSeconds: Int
}

struct StartRestResponse: Codable, Equatable {
    let restId: String
    let startedAt: String
    let endsAt: String
    let durationSeconds: Int
    let nextSet: JSONValue
}

struct AdvanceWorkoutExerciseRequest: Codable, Equatable {
    let completedExerciseId: String
}

struct AdvanceWorkoutExerciseResponse: Codable, Equatable {
    let workoutId: String
    let currentExercise: JSONValue
    let nextExercise: JSONValue
    let status: String
}

struct CreateWorkoutSetRequest: Codable, Equatable {
    let exerciseId: String
    let setIndex: Int
    let weight: Double
    let reps: Int
    let completedAt: String
}

struct CreateWorkoutSetResponse: Codable, Equatable {
    let setId: String
    let workoutId: String
    let exerciseId: String
    let setIndex: Int
    let isPersonalRecord: Bool
    let nextAction: JSONValue
    let rest: JSONValue

    enum CodingKeys: String, CodingKey {
        case setId
        case workoutId
        case exerciseId
        case setIndex
        case isPersonalRecord = "pr"
        case nextAction
        case rest
    }
}

struct StartWorkoutRequest: Codable, Equatable {
    let routineId: String
    let startedAt: String
    let timezone: String
}

enum ActiveWorkoutStatus: String, Codable {
    case inProgress = "IN_PROGRESS"
}

struct StartWorkoutResponse: Codable, Equatable {
    let workoutId: String
    let status: ActiveWorkoutStatus
    let routineSnapshot: JSONValue
    let currentExercise: JSONValue
    let startedAt: String
}

struct WorkoutSessionAPIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func skipCurrentRest(workoutId: String) async throws -> SkipCurrentRestResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/workouts/\(workoutId)/rests/current/skip",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: SkipCurrentRestResponse.self)
    }

    func startRest(workoutId: String, request: StartRestRequest) async throws -> StartRestResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/workouts/\(workoutId)/rests",
            expectedStatusCode: 201
        )
        return try await client.send(endpoint, body: request, as: StartRestResponse.self)
    }

    func advanceExercise(
        workoutId: String,
        request: AdvanceWorkoutExerciseRequest
    ) async throws -> AdvanceWorkoutExerciseResponse {
        let endpoint = APIEndpoint(
            method: .patch,
            path: "/api/v1/workouts/\(workoutId)/current-exercise",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, body: request, as: AdvanceWorkoutExerciseResponse.self)
    }

    func createSet(
        workoutId: String,
        request: CreateWorkoutSetRequest,
        idempotencyKey: String? = nil
    ) async throws -> CreateWorkoutSetResponse {
        var headers: [String: String] = [:]
        if let idempotencyKey {
            headers["Idempotency-Key"] = idempotencyKey
        }
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/workouts/\(workoutId)/sets",
            headers: headers,
            expectedStatusCode: 201
        )
        return try await client.send(endpoint, body: request, as: CreateWorkoutSetResponse.self)
    }

    func startWorkout(request: StartWorkoutRequest) async throws -> StartWorkoutResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/workouts",
            expectedStatusCode: 201
        )
        return try await client.send(endpoint, body: request, as: StartWorkoutResponse.self)
    }
}
