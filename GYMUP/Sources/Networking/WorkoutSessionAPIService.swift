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

struct CurrentRestResponse: Codable, Equatable {
    let restId: String
    let status: String
    let startedAt: String
    let endsAt: String
    let remainingSeconds: Int
    let notificationAt: String
}

struct ExtendCurrentRestRequest: Codable, Equatable {
    let seconds: Int
}

struct ExtendCurrentRestResponse: Codable, Equatable {
    let restId: String
    let endsAt: String
    let remainingSeconds: Int
}

struct AdvanceWorkoutExerciseRequest: Codable, Equatable {
    let completedExerciseId: String
}

struct AdvanceWorkoutExerciseResponse: Codable, Equatable {
    let workoutId: String
    let currentExercise: JSONValue
    let nextExercise: JSONValue
    let status: String
    let version: Int?

    init(
        workoutId: String,
        currentExercise: JSONValue,
        nextExercise: JSONValue,
        status: String,
        version: Int? = nil
    ) {
        self.workoutId = workoutId
        self.currentExercise = currentExercise
        self.nextExercise = nextExercise
        self.status = status
        self.version = version
    }
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
    let version: Int?

    init(
        setId: String,
        workoutId: String,
        exerciseId: String,
        setIndex: Int,
        isPersonalRecord: Bool,
        nextAction: JSONValue,
        rest: JSONValue,
        version: Int? = nil
    ) {
        self.setId = setId
        self.workoutId = workoutId
        self.exerciseId = exerciseId
        self.setIndex = setIndex
        self.isPersonalRecord = isPersonalRecord
        self.nextAction = nextAction
        self.rest = rest
        self.version = version
    }

    enum CodingKeys: String, CodingKey {
        case setId
        case workoutId
        case exerciseId
        case setIndex
        case isPersonalRecord = "pr"
        case nextAction
        case rest
        case version
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
    let version: Int?

    init(
        workoutId: String,
        status: ActiveWorkoutStatus,
        routineSnapshot: JSONValue,
        currentExercise: JSONValue,
        startedAt: String,
        version: Int? = nil
    ) {
        self.workoutId = workoutId
        self.status = status
        self.routineSnapshot = routineSnapshot
        self.currentExercise = currentExercise
        self.startedAt = startedAt
        self.version = version
    }
}

protocol WorkoutStarting {
    func startWorkout(request: StartWorkoutRequest) async throws -> StartWorkoutResponse
}

protocol WorkoutSessionResting {
    func startRest(workoutId: String, request: StartRestRequest) async throws -> StartRestResponse

    func currentRest(workoutId: String) async throws -> CurrentRestResponse

    func skipCurrentRest(workoutId: String) async throws -> SkipCurrentRestResponse

    func extendCurrentRest(workoutId: String, by seconds: Int) async throws -> ExtendCurrentRestResponse
}

protocol WorkoutSessionProgressing: WorkoutSessionResting {
    func createSet(
        workoutId: String,
        request: CreateWorkoutSetRequest,
        idempotencyKey: String?
    ) async throws -> CreateWorkoutSetResponse

    func advanceExercise(
        workoutId: String,
        request: AdvanceWorkoutExerciseRequest
    ) async throws -> AdvanceWorkoutExerciseResponse
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

    func currentRest(workoutId: String) async throws -> CurrentRestResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/workouts/\(workoutId)/rests/current",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: CurrentRestResponse.self)
    }

    func extendCurrentRest(workoutId: String, by seconds: Int) async throws -> ExtendCurrentRestResponse {
        let endpoint = APIEndpoint(
            method: .patch,
            path: "/api/v1/workouts/\(workoutId)/rests/current/extend",
            expectedStatusCode: 200
        )
        return try await client.send(
            endpoint,
            body: ExtendCurrentRestRequest(seconds: seconds),
            as: ExtendCurrentRestResponse.self
        )
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

extension WorkoutSessionAPIService: WorkoutStarting {}
extension WorkoutSessionAPIService: WorkoutSessionProgressing {}
