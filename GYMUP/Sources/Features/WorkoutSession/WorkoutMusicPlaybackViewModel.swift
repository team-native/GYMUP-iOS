import Foundation
import MusicKit
import Observation
import SpotifyiOS

@Observable
@MainActor
final class WorkoutMusicPlaybackViewModel {
    private let catalog = PlaylistCatalogViewModel()
    private let spotify = SpotifyPlaylistProvider()
    private let appleMusic = AppleMusicPlaybackService()
    private let spotifyRemote = SpotifyAppRemotePlayback()

    private(set) var items: [PlaylistCatalogItem] = []
    private(set) var isLoading = false
    private(set) var isPlaying = false
    private(set) var errorMessage: String?
    private(set) var needsSpotifyConnection = false
    var selectedProvider: PlaylistProvider = .appleMusic
    var selectedPlaylistID: String?

    func load(provider: PlaylistProvider) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        needsSpotifyConnection = false
        defer { isLoading = false }

        if provider == .spotify, SpotifyPlaylistConfiguration.from() == nil {
            items = []
            errorMessage = "Spotify Client ID 설정이 필요해요. 앱 설정에서 Client ID를 등록해 주세요."
            return
        }

        await catalog.load(provider: provider)
        items = catalog.items
        errorMessage = catalog.errorMessage
        needsSpotifyConnection = catalog.needsSpotifyConnection
        if selectedPlaylistID == nil || !items.contains(where: { $0.playlistId == selectedPlaylistID }) {
            selectedPlaylistID = items.first?.playlistId
        }
    }

    func connectSpotify() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        await catalog.connectSpotify()
        items = catalog.items
        errorMessage = catalog.errorMessage
        needsSpotifyConnection = catalog.needsSpotifyConnection
        selectedPlaylistID = items.first?.playlistId
    }

    func retry() async {
        await load(provider: selectedProvider)
    }

    func togglePlayback() async {
        if isPlaying {
            switch selectedProvider {
            case .appleMusic:
                appleMusic.pause()
            case .spotify:
                spotifyRemote.pause()
            }
            isPlaying = false
            return
        }

        guard let selectedPlaylistID else {
            errorMessage = "먼저 재생할 플레이리스트를 선택해 주세요."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch selectedProvider {
            case .appleMusic:
                try await appleMusic.play(playlistID: selectedPlaylistID)
                isPlaying = true
            case .spotify:
                let accessToken = try await spotify.playbackAccessToken()
                guard let configuration = SpotifyPlaylistConfiguration.from() else {
                    throw PlaylistProviderError.notConfigured("Spotify Client ID 설정이 필요해요.")
                }
                try await spotifyRemote.play(
                    playlistURI: "spotify:playlist:\(selectedPlaylistID)",
                    accessToken: accessToken,
                    configuration: configuration
                )
                isPlaying = true
            }
        } catch {
            isPlaying = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "음악을 재생하지 못했어요."
        }
    }
}

@MainActor
private struct AppleMusicPlaybackService {
    private let player = ApplicationMusicPlayer.shared

    func play(playlistID: String) async throws {
        let authorization = await MusicAuthorization.request()
        guard authorization == .authorized else {
            throw PlaylistProviderError.authorizationDenied("Apple Music 사용 권한을 허용해 주세요.")
        }

        var request = MusicLibraryRequest<MusicKit.Playlist>()
        request.limit = 100
        let response = try await request.response()
        guard let playlist = response.items.first(where: { $0.id.rawValue == playlistID }) else {
            throw PlaylistProviderError.playlistLoadFailed("선택한 Apple Music 플레이리스트를 찾지 못했어요.")
        }

        player.queue = .init(for: [playlist])
        try await player.play()
    }

    func pause() {
        player.pause()
    }
}

@MainActor
private final class SpotifyAppRemotePlayback: NSObject, @preconcurrency SPTAppRemoteDelegate {
    private var appRemote: SPTAppRemote?
    private var pendingPlaylistURI: String?
    private var completion: ((Result<Void, Error>) -> Void)?

    func play(
        playlistURI: String,
        accessToken: String,
        configuration: SpotifyPlaylistConfiguration
    ) async throws {
        guard completion == nil else { return }
        if let appRemote, appRemote.isConnected {
            guard let playerAPI = appRemote.playerAPI else {
                throw PlaylistProviderError.playlistLoadFailed("Spotify 재생 제어를 사용할 수 없어요.")
            }
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                playerAPI.play(playlistURI) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            return
        }
        let sdkConfiguration = SPTConfiguration(clientID: configuration.clientID, redirectURL: configuration.redirectURI)
        let remote = SPTAppRemote(configuration: sdkConfiguration, logLevel: .error)
        remote.delegate = self
        remote.connectionParameters.accessToken = accessToken
        pendingPlaylistURI = playlistURI

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            completion = { result in continuation.resume(with: result) }
            appRemote = remote
            remote.connect()
        }
    }

    func pause() {
        appRemote?.playerAPI?.pause(nil)
    }

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        guard let pendingPlaylistURI else {
            finish(.failure(PlaylistProviderError.playlistLoadFailed("재생할 Spotify 플레이리스트를 찾지 못했어요.")))
            return
        }
        guard let playerAPI = appRemote.playerAPI else {
            finish(.failure(PlaylistProviderError.playlistLoadFailed("Spotify 재생 제어를 사용할 수 없어요.")))
            return
        }
        playerAPI.play(pendingPlaylistURI) { [weak self] _, error in
            if let error {
                self?.finish(.failure(error))
            } else {
                self?.finish(.success(()))
            }
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        if let error { finish(.failure(error)) }
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        finish(.failure(error ?? PlaylistProviderError.playlistLoadFailed("Spotify 앱에 연결하지 못했어요.")))
    }

    private func finish(_ result: Result<Void, Error>) {
        let callback = completion
        completion = nil
        pendingPlaylistURI = nil
        callback?(result)
    }
}
