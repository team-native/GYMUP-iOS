import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class HistoryServerPhotoDetailViewModel {
    let photo: HistoryServerPhoto

    private let service: PhotosDownloading?
    private(set) var downloadURL: URL?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(photo: HistoryServerPhoto, service: PhotosDownloading?) {
        self.photo = photo
        self.service = service
    }

    func loadIfNeeded() async {
        guard downloadURL == nil, errorMessage == nil, !isLoading else { return }
        await loadDownloadURL()
    }

    func retry() async {
        await loadDownloadURL()
    }

    private func loadDownloadURL() async {
        guard !isLoading else { return }
        guard let service else {
            errorMessage = "사진을 불러올 수 없어요. 잠시 후 다시 시도해 주세요."
            return
        }

        isLoading = true
        downloadURL = nil
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await service.downloadURL(photoId: photo.id)
            guard response.photoId == photo.id,
                  let url = Self.validatedDownloadURL(response),
                  let expiresAt = Self.date(from: response.expiresAt),
                  expiresAt > .now
            else {
                throw APIClientError.invalidResponse
            }
            downloadURL = url
        } catch is CancellationError {
            return
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    private static func validatedDownloadURL(_ response: PhotoDownloadURLResponse) -> URL? {
        guard let components = URLComponents(string: response.downloadUrl),
              components.scheme?.lowercased() == "https",
              components.host != nil,
              components.user == nil,
              components.password == nil
        else {
            return nil
        }
        return components.url
    }

    private static func date(from value: String) -> Date? {
        let options: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime]
        ]
        for formatOptions in options {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = formatOptions
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private static func message(for error: Error) -> String {
        if let apiError = error as? APIClientError,
           case let .server(_, detail) = apiError {
            return detail.message
        }
        return "사진을 불러오지 못했어요. 다시 시도해 주세요."
    }
}

struct HistoryServerPhotoDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: HistoryServerPhotoDetailViewModel

    init(photo: HistoryServerPhoto, service: PhotosDownloading?) {
        _viewModel = State(initialValue: HistoryServerPhotoDetailViewModel(photo: photo, service: service))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("사진 닫기")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            photoContent

            Text(HistoryDateText.string(viewModel.photo.capturedAt, format: "yyyy년 M월 d일"))
                .font(GymupTypography.uiStrong)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .accessibilityIdentifier("history.serverPhoto.date")
        }
        .background(Color.black.ignoresSafeArea())
        .task { await viewModel.loadIfNeeded() }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var photoContent: some View {
        if let downloadURL = viewModel.downloadURL {
            AsyncImage(url: downloadURL) { phase in
                switch phase {
                case .empty:
                    loadingContent(label: "사진 불러오는 중")
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("서버 운동 사진")
                case .failure:
                    retryContent(message: "사진을 불러오지 못했어요.")
                @unknown default:
                    retryContent(message: "사진을 불러오지 못했어요.")
                }
            }
        } else if let errorMessage = viewModel.errorMessage {
            retryContent(message: errorMessage)
        } else {
            loadingContent(label: "사진 URL 가져오는 중")
        }
    }

    private func loadingContent(label: String) -> some View {
        ProgressView {
            Text(label)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(.white)
        }
            .tint(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(label)
    }

    private func retryContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
                .accessibilityHidden(true)
            Text(message)
                .font(GymupTypography.uiBody)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                Task { await viewModel.retry() }
            }
            .font(GymupTypography.uiStrong)
            .foregroundStyle(.white)
            .frame(minWidth: 44, minHeight: 44)
            .disabled(viewModel.isLoading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
