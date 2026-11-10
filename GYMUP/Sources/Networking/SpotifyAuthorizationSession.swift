import AuthenticationServices
import Foundation
import UIKit

@MainActor
final class SpotifyAuthorizationSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<URL, Error>?
    private let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor? = nil) throws {
        guard let anchor = anchor ?? Self.activePresentationAnchor() else {
            throw PlaylistProviderError.authorizationFailed("로그인 화면을 열 수 없어요. 앱을 다시 활성화한 뒤 시도해 주세요.")
        }
        self.anchor = anchor
    }

    func authorize(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = ASWebAuthenticationSession(url: url, callback: .customScheme(callbackScheme)) { [weak self] url, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let url {
                        self.finish(.success(url))
                    } else {
                        self.finish(.failure(error ?? PlaylistProviderError.authorizationFailed("Spotify 로그인이 취소됐어요.")))
                    }
                }
            }
            session.presentationContextProvider = self
            self.session = session
            guard session.start() else {
                finish(.failure(PlaylistProviderError.authorizationFailed("Spotify 로그인 화면을 열지 못했어요.")))
                return
            }
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { anchor }

    private func finish(_ result: Result<URL, Error>) {
        session = nil
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }

    private static func activePresentationAnchor() -> ASPresentationAnchor? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}
