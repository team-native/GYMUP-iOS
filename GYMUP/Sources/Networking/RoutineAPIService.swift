import Foundation

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
