import Foundation

struct PlateCalculatorRequest: Codable, Equatable {
    let targetWeight: Double
    let barWeight: Double
    let availablePlates: [JSONValue]
}

struct PlateWeightCount: Codable, Equatable {
    let weight: Double
    let count: Int
}

struct PlateCalculatorResponse: Codable, Equatable {
    let achievable: Bool
    let eachSide: [PlateWeightCount]
    let actualWeight: Double
    let remainder: Double
}

struct PlateCalculatorAPIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func calculate(_ request: PlateCalculatorRequest) async throws -> PlateCalculatorResponse {
        let endpoint = APIEndpoint(
            method: .post,
            path: "/api/v1/tools/plate-calculator",
            expectedStatusCode: 200
        )
        return try await client.send(endpoint, body: request, as: PlateCalculatorResponse.self)
    }
}
