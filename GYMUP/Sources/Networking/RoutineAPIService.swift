import Foundation

struct CreateRoutineExerciseRequest: Codable, Equatable {
    let exerciseId: String
    let sets: Int
    let reps: Int
    let weight: Double
    let restSeconds: Int
    let order: Int
}

struct CreateRoutineRequest: Codable, Equatable {
    let name: String
    let exercises: [CreateRoutineExerciseRequest]
}

struct CreatedRoutineExerciseResponse: Codable, Equatable {
    let exerciseId: String
    let sets: Int
    let reps: Int
    let weight: Double
    let restSeconds: Int
    let order: Int
}

struct CreateRoutineResponse: Codable, Equatable {
    let routineId: String
    let name: String
    let exercises: [CreatedRoutineExerciseResponse]
    let createdAt: String
}

struct UpdateRoutineExerciseRequest: Codable, Equatable {
    let exerciseId: String
    let sets: Int
    let reps: Int
    let weight: Double
    let restSeconds: Int
}

struct UpdateRoutineExercisesRequest: Codable, Equatable {
    let add: [CreateRoutineExerciseRequest]
    let update: [UpdateRoutineExerciseRequest]
    let removeExerciseIds: [String]
}

struct RoutineExerciseResponse: Codable, Equatable {
    let exerciseId: String
    let sets: Int
    let reps: Int
    let weight: Double
    let restSeconds: Int
    let order: Int
}

struct UpdateRoutineExercisesResponse: Codable, Equatable {
    let routineId: String
    let exercises: [RoutineExerciseResponse]
    let updatedAt: String
}

struct UpdateRoutineExerciseOrderRequest: Codable, Equatable {
    let exerciseIds: [String]
}

struct UpdateRoutineExerciseOrderResponse: Codable, Equatable {
    let routineId: String
    let orderedExercises: [RoutineExerciseResponse]
    let updatedAt: String
}

protocol RoutineCreating {
    func createRoutine(_ request: CreateRoutineRequest) async throws -> CreateRoutineResponse
}

protocol RoutineExerciseEditing {
    func updateExercises(
        routineId: String,
        request: UpdateRoutineExercisesRequest
    ) async throws -> UpdateRoutineExercisesResponse

    func updateExerciseOrder(
        routineId: String,
        request: UpdateRoutineExerciseOrderRequest
    ) async throws -> UpdateRoutineExerciseOrderResponse
}

struct UpdateRoutinePlaylistRequest: Codable, Equatable {
    let provider: String
    let playlistId: String
    let playlistName: String
    let externalUrl: String
}

struct RoutinePlaylistResponse: Codable, Equatable {
    let provider: String
    let playlistId: String
    let playlistName: String
    let externalUrl: String
}

struct UpdateRoutinePlaylistResponse: Codable, Equatable {
    let routineId: String
    let playlist: RoutinePlaylistResponse
    let updatedAt: String
}

struct RoutineAPIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func createRoutine(_ request: CreateRoutineRequest) async throws -> CreateRoutineResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/routines",
            expectedStatusCode: 201
        )
        return try await client.send(endpoint, body: request, as: CreateRoutineResponse.self)
    }

    func updateExercises(
        routineId: String,
        request: UpdateRoutineExercisesRequest
    ) async throws -> UpdateRoutineExercisesResponse {
        let endpoint = APIEndpoint(
            method: .patch,
            path: "/api/v1/routines/\(routineId)/exercises",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, body: request, as: UpdateRoutineExercisesResponse.self)
    }

    func updateExerciseOrder(
        routineId: String,
        request: UpdateRoutineExerciseOrderRequest
    ) async throws -> UpdateRoutineExerciseOrderResponse {
        let endpoint = APIEndpoint(
            method: .put,
            path: "/api/v1/routines/\(routineId)/exercises/order",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, body: request, as: UpdateRoutineExerciseOrderResponse.self)
    }

    func updatePlaylist(
        routineId: String,
        request: UpdateRoutinePlaylistRequest
    ) async throws -> UpdateRoutinePlaylistResponse {
        let endpoint = APIEndpoint(
            method: .put,
            path: "/api/v1/routines/\(routineId)/playlist",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, body: request, as: UpdateRoutinePlaylistResponse.self)
    }
}

extension RoutineAPIService: RoutineCreating, RoutineExerciseEditing {}
