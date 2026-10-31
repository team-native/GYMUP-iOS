import Foundation

struct ExerciseFirstTimeStatusResponse: Codable, Equatable {
    let exerciseId: String
    let isFirstTime: Bool
    let guideAvailable: Bool
}

struct ExerciseGuideResponse: Codable, Equatable {
    let exerciseId: String
    let mediaUrl: String
    let targetMuscles: [String]
    let keyPoints: [String]
    let commonMistakes: [String]
}

struct PreviousExerciseRecordQuery {
    let beforeWorkoutId: String?

    var queryItems: [URLQueryItem] {
        beforeWorkoutId.map { [URLQueryItem(name: "beforeWorkoutId", value: $0)] } ?? []
    }
}

struct PreviousExerciseRecordResponse: Codable, Equatable {
    let exerciseId: String
    let hasPreviousRecord: Bool
    let weight: Double
    let reps: Int
    let setIndex: Int
    let performedAt: String
}

struct ExerciseReadAPIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func firstTimeStatus(exerciseId: String) async throws -> ExerciseFirstTimeStatusResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/exercises/\(exerciseId)/first-time-status",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: ExerciseFirstTimeStatusResponse.self)
    }

    func guide(exerciseId: String) async throws -> ExerciseGuideResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/exercises/\(exerciseId)/guide",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: ExerciseGuideResponse.self)
    }

    func previousRecord(
        exerciseId: String,
        query: PreviousExerciseRecordQuery = PreviousExerciseRecordQuery(beforeWorkoutId: nil)
    ) async throws -> PreviousExerciseRecordResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/exercises/\(exerciseId)/previous-record",
            queryItems: query.queryItems,
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: PreviousExerciseRecordResponse.self)
    }
}
