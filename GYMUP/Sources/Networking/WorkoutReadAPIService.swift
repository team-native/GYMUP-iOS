import Foundation

struct ListWorkoutsQuery {
    let cursor: String?
    let size: Int
    let from: String
    let endDate: String
    let routineId: String

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: endDate),
            URLQueryItem(name: "routineId", value: routineId)
        ]
        if let cursor {
            items.insert(URLQueryItem(name: "cursor", value: cursor), at: 0)
        }
        return items
    }
}

struct WorkoutListItem: Codable, Equatable {
    let workoutId: String
    let date: String
    let routineName: String
    let duration: Int
    let totalSets: Int
    let volume: Double
}

struct ListWorkoutsResponse: Codable, Equatable {
    let items: [WorkoutListItem]
    let nextCursor: String?
}

struct NextWorkoutSetResponse: Codable, Equatable {
    let exerciseId: String
    let exerciseName: String
    let setIndex: Int
    let weight: Double
    let reps: Int
    let restEndsAt: String
}

protocol WorkoutNextSetReading {
    func nextSet(workoutId: String) async throws -> NextWorkoutSetResponse
}

protocol WorkoutListReading {
    @MainActor
    func list(_ query: ListWorkoutsQuery) async throws -> ListWorkoutsResponse
}

struct WorkoutReadAPIService: WorkoutNextSetReading, WorkoutListReading {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    @MainActor
    func list(_ query: ListWorkoutsQuery) async throws -> ListWorkoutsResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/workouts",
            queryItems: query.queryItems,
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: ListWorkoutsResponse.self)
    }

    func nextSet(workoutId: String) async throws -> NextWorkoutSetResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/workouts/\(workoutId)/next-set",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: NextWorkoutSetResponse.self)
    }

}
