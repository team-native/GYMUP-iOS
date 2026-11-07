import Foundation
import Observation

@Observable
@MainActor
final class HistoryAlbumViewModel {
    private let service: PhotosListing?
    private let nowProvider: () -> Date

    private(set) var serverPhotos: [HistoryServerPhoto] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(service: PhotosListing?, nowProvider: @escaping () -> Date = { .now }) {
        self.service = service
        self.nowProvider = nowProvider
    }

    func refresh() async {
        guard let service, !isLoading else { return }
        await load(using: service)
    }

    func retry() async {
        await refresh()
    }

    private func load(using service: PhotosListing) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            serverPhotos = try await fetchAll(using: service)
            errorMessage = nil
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    private func fetchAll(using service: PhotosListing) async throws -> [HistoryServerPhoto] {
        let dateRange = Self.dateRange(now: nowProvider())
        var cursor: String?
        var seenCursors = Set<String>()
        var photosByID: [String: HistoryServerPhoto] = [:]

        while true {
            let response = try await service.list(
                ListPhotosQuery(
                    cursor: cursor,
                    size: 100,
                    from: dateRange.from,
                    endDate: dateRange.to,
                    sort: "recent"
                )
            )

            for item in response.items {
                guard let photo = HistoryServerPhoto(response: item) else {
                    throw APIClientError.invalidResponse
                }
                photosByID[photo.id] = photo
            }

            guard let nextCursor = response.nextCursor else { break }
            guard !nextCursor.isEmpty,
                  seenCursors.insert(nextCursor).inserted
            else {
                throw APIClientError.invalidResponse
            }
            cursor = nextCursor
        }

        return photosByID.values.sorted { $0.capturedAt > $1.capturedAt }
    }

    private static func dateRange(now: Date) -> (from: String, to: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return ("1970-01-01", formatter.string(from: now))
    }

    private static func message(for error: Error) -> String {
        if let apiError = error as? APIClientError,
           case let .server(_, detail) = apiError {
            return detail.message
        }
        return "서버 사진을 불러오지 못했어요. 다시 시도해 주세요."
    }
}
