import Foundation

struct WeeklyStreakResponse: Decodable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let lastAchievedWeek: String?
    let status: String

    private enum CodingKeys: String, CodingKey {
        case currentStreak
        case longestStreak
        case lastAchievedWeek
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        lastAchievedWeek = try container.decode(String?.self, forKey: .lastAchievedWeek)
        status = try container.decode(String.self, forKey: .status)
    }
}

protocol WeeklyStreakReading {
    func fetch() async throws -> WeeklyStreakResponse
}

struct WeeklyStreakAPIService: WeeklyStreakReading {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetch() async throws -> WeeklyStreakResponse {
        let endpoint = APIEndpoint(
            method: .get,
            path: "/api/v1/streaks/weekly",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, as: WeeklyStreakResponse.self)
    }
}
