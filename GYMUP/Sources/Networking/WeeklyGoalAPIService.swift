import Foundation

struct CurrentWeeklyGoalResponse: Decodable, Equatable {
    let weekStart: String
    let weekEnd: String
    let targetCount: Int
    let completedCount: Int
    let achieved: Bool
}

protocol CurrentWeeklyGoalReading {
    func fetch(timeZoneIdentifier: String) async throws -> CurrentWeeklyGoalResponse
}

struct CurrentWeeklyGoalAPIService: CurrentWeeklyGoalReading {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetch(timeZoneIdentifier: String) async throws -> CurrentWeeklyGoalResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/goals/weekly/current",
            queryItems: [URLQueryItem(name: "timezone", value: timeZoneIdentifier)],
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: CurrentWeeklyGoalResponse.self)
    }
}
