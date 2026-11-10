import Foundation
import Observation

@Observable
@MainActor
final class PlaylistCatalogViewModel {
    private let appleMusic = AppleMusicPlaylistProvider()
    private let spotify = SpotifyPlaylistProvider()
    private(set) var items: [PlaylistCatalogItem] = []
    private(set) var isLoading = false
    private(set) var isSpotifyConnected = false
    private(set) var errorMessage: String?
    private(set) var needsSpotifyConnection = false

    func load(provider: PlaylistProvider) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        needsSpotifyConnection = false
        defer { isLoading = false }

        if provider == .spotify {
            isSpotifyConnected = await spotify.isConnected()
            guard isSpotifyConnected else {
                items = []
                needsSpotifyConnection = true
                return
            }
        }

        await fetch(provider: provider)
    }

    func connectSpotify() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await spotify.connect()
            isSpotifyConnected = true
            needsSpotifyConnection = false
            items = try await spotify.fetchPlaylists()
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func disconnectSpotify() async {
        do {
            try await spotify.disconnect()
            isSpotifyConnected = false
            items = []
            needsSpotifyConnection = true
            errorMessage = nil
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func retry(provider: PlaylistProvider) async {
        await load(provider: provider)
    }

    private func fetch(provider: PlaylistProvider) async {
        do {
            switch provider {
            case .appleMusic:
                items = try await appleMusic.fetchPlaylists()
            case .spotify:
                items = try await spotify.fetchPlaylists()
            }
        } catch {
            items = []
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "플레이리스트를 불러오지 못했어요. 다시 시도해 주세요."
    }
}
