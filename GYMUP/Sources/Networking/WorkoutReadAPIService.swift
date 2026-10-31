import Foundation

struct ListWorkoutsQuery {
    let cursor: String
    let size: Int
    let from: String
    let endDate: String
    let routineId: String

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "cursor", value: cursor),
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: endDate),
            URLQueryItem(name: "routineId", value: routineId)
        ]
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
    let nextCursor: String
}

struct NextWorkoutSetResponse: Codable, Equatable {
    let exerciseId: String
    let exerciseName: String
    let setIndex: Int
    let weight: Double
    let reps: Int
    let restEndsAt: String
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

struct WorkoutReadAPIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

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
}
