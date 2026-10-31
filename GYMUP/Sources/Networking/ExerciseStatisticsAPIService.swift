import Foundation

struct ExerciseStatisticsQuery {
    let metric: String
    let from: String
    let endDate: String
    let interval: String

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "metric", value: metric),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: endDate),
            URLQueryItem(name: "interval", value: interval)
        ]
    }
}

struct ExerciseStatisticPoint: Codable, Equatable {
    let date: String
    let value: Double
}

struct ExerciseStatisticsResponse: Codable, Equatable {
    let exerciseId: String
    let metric: String
    let points: [ExerciseStatisticPoint]
    let summary: JSONValue
}

struct ExerciseStatisticsAPIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func statistics(exerciseId: String, query: ExerciseStatisticsQuery) async throws -> ExerciseStatisticsResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/statistics/exercises/\(exerciseId)",
            queryItems: query.queryItems,
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: ExerciseStatisticsResponse.self)
    }
}
