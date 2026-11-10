import Foundation

struct SpotifyPlaylistPage: Decodable {
    let next: String?
    let items: [SpotifyPlaylist]
}

private struct SpotifyPlaylist: Decodable {
    let id: String
    let name: String
    let externalURLs: SpotifyExternalURLs?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case externalURLs = "external_urls"
    }
}

struct SpotifyExternalURLs: Decodable {
    let spotify: String?
}

struct SpotifyTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
