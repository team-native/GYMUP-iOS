import CryptoKit
import Foundation
import MusicKit
import Security

enum PlaylistProvider: String, CaseIterable, Codable, Identifiable {
    case appleMusic = "apple_music"
    case spotify

    var id: Self { self }
    var displayName: String { self == .appleMusic ? "Apple Music" : "Spotify" }
}

struct PlaylistCatalogItem: Identifiable, Equatable {
    let provider: PlaylistProvider
    let playlistId: String
    let name: String
    let externalUrl: String

    var id: String { "\(provider.rawValue):\(playlistId)" }

    var reference: RoutinePlaylistReference {
        RoutinePlaylistReference(
            provider: provider,
            playlistId: playlistId,
            playlistName: name,
            externalUrl: externalUrl
        )
    }
}

struct AppleMusicPlaylistProvider {
    func fetchPlaylists() async throws -> [PlaylistCatalogItem] {
        let authorization = await MusicAuthorization.request()
        guard authorization == .authorized else {
            throw PlaylistProviderError.authorizationDenied("Apple Music 라이브러리 접근이 허용되지 않았어요.")
        }

        var request = MusicLibraryRequest<MusicKit.Playlist>()
        request.limit = 100
        let response = try await request.response()
        return response.items.compactMap { playlist in
            guard let url = playlist.url,
                  !playlist.id.rawValue.isEmpty,
                  !playlist.name.isEmpty else { return nil }
            return PlaylistCatalogItem(
                provider: .appleMusic,
                playlistId: playlist.id.rawValue,
                name: playlist.name,
                externalUrl: url.absoluteString
            )
        }
    }
}

struct SpotifyPlaylistConfiguration {
    let clientID: String
    let redirectURI: URL

    var redirectScheme: String? { redirectURI.scheme }

    static func from(bundle: Bundle = .main) -> SpotifyPlaylistConfiguration? {
        guard let rawClientID = bundle.object(forInfoDictionaryKey: "GYMUP_SPOTIFY_CLIENT_ID") as? String,
              let rawRedirectURI = bundle.object(forInfoDictionaryKey: "GYMUP_SPOTIFY_REDIRECT_URI") as? String else {
            return nil
        }
        let clientID = rawClientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let redirectValue = rawRedirectURI.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clientID.isEmpty,
              !clientID.hasPrefix("$("),
              let redirectURI = URL(string: redirectValue),
              let scheme = redirectURI.scheme,
              !scheme.isEmpty,
              !redirectValue.hasPrefix("$(") else { return nil }
        return SpotifyPlaylistConfiguration(clientID: clientID, redirectURI: redirectURI)
    }
}

struct SpotifyPlaylistProvider {
    private let configuration: SpotifyPlaylistConfiguration?
    private let session: URLSession
    private let credentialStore: SpotifyCredentialStore

    init(
        configuration: SpotifyPlaylistConfiguration? = .from(),
        session: URLSession = .shared,
        credentialStore: SpotifyCredentialStore = .shared
    ) {
        self.configuration = configuration
        self.session = session
        self.credentialStore = credentialStore
    }

    var isConfigured: Bool { configuration != nil }

    func isConnected() async -> Bool {
        await credentialStore.load() != nil
    }

    func connect() async throws {
        guard let configuration, let callbackScheme = configuration.redirectScheme else {
            throw PlaylistProviderError.notConfigured("Spotify Client ID 설정이 필요해요.")
        }

        let verifier = try Self.randomString(length: 64)
        let challenge = Self.codeChallenge(for: verifier)
        let state = try Self.randomString(length: 32)
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI.absoluteString),
            URLQueryItem(name: "scope", value: "playlist-read-private"),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "state", value: state)
        ]
        guard let authorizationURL = components?.url else {
            throw PlaylistProviderError.authorizationFailed("Spotify 로그인 주소를 만들지 못했어요.")
        }

        let callbackURL = try await SpotifyAuthorizationSession().authorize(
            url: authorizationURL,
            callbackScheme: callbackScheme
        )
        guard let callback = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              callback.scheme == callbackScheme,
              callback.queryItems?.first(where: { $0.name == "state" })?.value == state else {
            throw PlaylistProviderError.authorizationFailed("Spotify 로그인 응답을 확인하지 못했어요.")
        }
        if let error = callback.queryItems?.first(where: { $0.name == "error" })?.value {
            throw PlaylistProviderError.authorizationFailed(error == "access_denied"
                ? "Spotify 플레이리스트 접근을 허용하지 않았어요."
                : "Spotify 로그인에 실패했어요.")
        }
        guard let code = callback.queryItems?.first(where: { $0.name == "code" })?.value,
              !code.isEmpty else {
            throw PlaylistProviderError.authorizationFailed("Spotify 인증 코드를 받지 못했어요.")
        }

        let token = try await exchangeAuthorizationCode(code, verifier: verifier, configuration: configuration)
        try await credentialStore.save(token)
    }

    func disconnect() async throws {
        try await credentialStore.remove()
    }

    func fetchPlaylists() async throws -> [PlaylistCatalogItem] {
        guard let configuration else {
            throw PlaylistProviderError.notConfigured("Spotify Client ID 설정이 필요해요.")
        }
        var credentials = try await validCredentials(configuration: configuration)
        var offset = 0
        var results: [PlaylistCatalogItem] = []

        var didRefreshAfterUnauthorized = false
        while true {
            var components = URLComponents(string: "https://api.spotify.com/v1/me/playlists")
            components?.queryItems = [
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "offset", value: String(offset))
            ]
            guard let url = components?.url else {
                throw PlaylistProviderError.playlistLoadFailed("Spotify 플레이리스트 주소를 만들지 못했어요.")
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaylistProviderError.playlistLoadFailed("Spotify 응답을 확인하지 못했어요.")
            }
            if httpResponse.statusCode == 401 {
                guard !didRefreshAfterUnauthorized else {
                    throw PlaylistProviderError.notConnected("Spotify 연결이 만료됐어요. 다시 연결해 주세요.")
                }
                didRefreshAfterUnauthorized = true
                credentials = try await refreshCredentials(credentials, configuration: configuration)
                continue
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw PlaylistProviderError.playlistLoadFailed(Self.message(for: httpResponse.statusCode))
            }
            let page = try JSONDecoder().decode(SpotifyPlaylistPage.self, from: data)
            results.append(contentsOf: page.items.compactMap { item in
                guard let externalURL = item.externalURLs?.spotify,
                      URL(string: externalURL)?.scheme == "https",
                      !item.id.isEmpty,
                      !item.name.isEmpty else { return nil }
                return PlaylistCatalogItem(
                    provider: .spotify,
                    playlistId: item.id,
                    name: item.name,
                    externalUrl: externalURL
                )
            })
            guard page.next != nil, !page.items.isEmpty else { break }
            offset += page.items.count
        }
        return results
    }

    private func validCredentials(configuration: SpotifyPlaylistConfiguration) async throws -> SpotifyCredentials {
        guard let credentials = await credentialStore.load() else {
            throw PlaylistProviderError.notConnected("Spotify 계정을 연결해 주세요.")
        }
        guard credentials.expiresAt.timeIntervalSinceNow > 60 else {
            return try await refreshCredentials(credentials, configuration: configuration)
        }
        return credentials
    }

    private func refreshCredentials(
        _ credentials: SpotifyCredentials,
        configuration: SpotifyPlaylistConfiguration
    ) async throws -> SpotifyCredentials {
        let data = Self.formData([
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: credentials.refreshToken),
            URLQueryItem(name: "client_id", value: configuration.clientID)
        ])
        let response = try await requestToken(data: data)
        let refreshed = SpotifyCredentials(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken ?? credentials.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn))
        )
        try await credentialStore.save(refreshed)
        return refreshed
    }

    private func exchangeAuthorizationCode(
        _ code: String,
        verifier: String,
        configuration: SpotifyPlaylistConfiguration
    ) async throws -> SpotifyCredentials {
        let data = Self.formData([
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI.absoluteString),
            URLQueryItem(name: "code_verifier", value: verifier)
        ])
        let response = try await requestToken(data: data)
        guard let refreshToken = response.refreshToken else {
            throw PlaylistProviderError.authorizationFailed("Spotify refresh token을 받지 못했어요.")
        }
        return SpotifyCredentials(
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn))
        )
    }

    private func requestToken(data: Data) async throws -> SpotifyTokenResponse {
        guard let tokenURL = URL(string: "https://accounts.spotify.com/api/token") else {
            throw PlaylistProviderError.authorizationFailed("Spotify token 주소가 올바르지 않아요.")
        }
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = data
        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw PlaylistProviderError.authorizationFailed("Spotify 토큰 요청에 실패했어요.")
        }
        return try JSONDecoder().decode(SpotifyTokenResponse.self, from: responseData)
    }

    private static func formData(_ items: [URLQueryItem]) -> Data {
        var components = URLComponents()
        components.queryItems = items
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    private static func randomString(length: Int) throws -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".utf8)
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw PlaylistProviderError.authorizationFailed("PKCE challenge를 안전하게 만들지 못했어요.")
        }
        let randomBytes = bytes.map { alphabet[Int($0) % alphabet.count] }
        guard let value = String(bytes: randomBytes, encoding: .utf8) else {
            throw PlaylistProviderError.authorizationFailed("PKCE challenge를 안전하게 만들지 못했어요.")
        }
        return value
    }

    private static func codeChallenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8)))
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func message(for statusCode: Int) -> String {
        switch statusCode {
        case 403: "Spotify에서 플레이리스트 접근이 거부됐어요. 권한을 확인해 주세요."
        case 429: "Spotify 요청이 많아요. 잠시 후 다시 시도해 주세요."
        default: "Spotify 플레이리스트를 불러오지 못했어요. 다시 시도해 주세요."
        }
    }
}

enum PlaylistProviderError: Error, LocalizedError {
    case notConfigured(String)
    case notConnected(String)
    case authorizationDenied(String)
    case authorizationFailed(String)
    case playlistLoadFailed(String)

    var errorDescription: String? {
        switch self {
        case let .notConfigured(message), let .notConnected(message), let .authorizationDenied(message),
             let .authorizationFailed(message), let .playlistLoadFailed(message): message
        }
    }
}

struct SpotifyCredentials: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

actor SpotifyCredentialStore {
    static let shared = SpotifyCredentialStore()

    private let service = "com.teamnative.gymup.spotify"
    private let account = "playlist-read-private"

    func load() -> SpotifyCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(SpotifyCredentials.self, from: data)
    }

    func save(_ credentials: SpotifyCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            attributes.forEach { newItem[$0.key] = $0.value }
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw PlaylistProviderError.authorizationFailed("Spotify token을 안전하게 저장하지 못했어요.") }
        } else if status != errSecSuccess {
            throw PlaylistProviderError.authorizationFailed("Spotify token을 안전하게 저장하지 못했어요.")
        }
    }

    func remove() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PlaylistProviderError.authorizationFailed("Spotify 연결 정보를 삭제하지 못했어요.")
        }
    }
}
