import XCTest
@testable import GYMUP

final class HistoryAlbumViewModelTests: XCTestCase {
    @MainActor
    func testRefreshOmitsFirstCursorFollowsNextPageAndKeepsNullThumbnail() async throws {
        let olderPhoto = photo(
            id: "photo-older",
            date: "2026-10-31T09:00:00Z",
            thumbnail: "https://cdn.example.test/older.jpg"
        )
        let newerPhoto = photo(
            id: "photo-newer",
            date: "2026-11-08T09:00:00Z",
            thumbnail: nil
        )
        let service = PhotosListServiceStub(outcomes: [
            .success(ListPhotosResponse(items: [olderPhoto], nextCursor: "page-2")),
            .success(ListPhotosResponse(items: [newerPhoto], nextCursor: nil))
        ])
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-11-08T12:00:00Z"))
        let viewModel = HistoryAlbumViewModel(service: service, nowProvider: { now })

        await viewModel.refresh()

        XCTAssertEqual(service.requests.map(\.cursor), [nil, "page-2"])
        XCTAssertEqual(service.requests.map(\.size), [100, 100])
        XCTAssertEqual(service.requests.map(\.from), ["1970-01-01", "1970-01-01"])
        XCTAssertEqual(service.requests.map(\.endDate), ["2026-11-08", "2026-11-08"])
        XCTAssertEqual(service.requests.map(\.sort), ["recent", "recent"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.serverPhotos.map(\.id), ["photo-newer", "photo-older"])
        XCTAssertNil(viewModel.serverPhotos.first?.thumbnailURL)
        XCTAssertEqual(viewModel.serverPhotos.last?.thumbnailURL, URL(string: "https://cdn.example.test/older.jpg"))

        let albumData = HistoryServerPhotoData(photos: viewModel.serverPhotos)
        XCTAssertEqual(albumData.months.map(\.title), ["11월", "10월"])
    }

    @MainActor
    func testFailureKeepsPreviousServerPhotosAndLocalRecordsThenRetrySucceeds() async throws {
        let localRecord = try XCTUnwrap(HistorySampleData.records.first)
        let localStore = HistoryStore(records: [localRecord])
        let service = PhotosListServiceStub(outcomes: [
            .success(ListPhotosResponse(items: [photo(id: "photo-before-error")], nextCursor: nil)),
            .failure(.server(
                statusCode: 503,
                detail: ServerErrorDetail(code: "TEMPORARY", message: "사진을 불러오지 못했어요.")
            )),
            .success(ListPhotosResponse(items: [photo(id: "photo-after-retry")], nextCursor: nil))
        ])
        let viewModel = HistoryAlbumViewModel(service: service)

        await viewModel.refresh()
        await viewModel.refresh()

        XCTAssertEqual(viewModel.errorMessage, "사진을 불러오지 못했어요.")
        XCTAssertEqual(viewModel.serverPhotos.map(\.id), ["photo-before-error"])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(localStore.records, [localRecord])

        await viewModel.retry()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.serverPhotos.map(\.id), ["photo-after-retry"])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(localStore.records, [localRecord])
        XCTAssertEqual(service.requests.count, 3)
    }

    @MainActor
    func testNullTerminalCursorStopsAfterSinglePage() async {
        let service = PhotosListServiceStub(outcomes: [
            .success(ListPhotosResponse(items: [photo(id: "photo-only")], nextCursor: nil))
        ])
        let viewModel = HistoryAlbumViewModel(service: service)

        await viewModel.refresh()

        XCTAssertEqual(service.requests.count, 1)
        XCTAssertEqual(viewModel.serverPhotos.map(\.id), ["photo-only"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testHTTPThumbnailURLIsRejected() throws {
        let serverPhoto = try XCTUnwrap(
            HistoryServerPhoto(response: photo(
                id: "photo-insecure-thumbnail",
                thumbnail: "http://cdn.example.test/photo.jpg"
            ))
        )

        XCTAssertNil(serverPhoto.thumbnailURL)
    }

    private func photo(
        id: String,
        date: String = "2026-11-08T09:00:00Z",
        thumbnail: String? = nil
    ) -> PhotoListItem {
        PhotoListItem(
            photoId: id,
            workoutId: "workout-\(id)",
            capturedAt: date,
            thumbnailUrl: thumbnail
        )
    }
}

@MainActor
private final class PhotosListServiceStub: PhotosListing {
    enum Outcome {
        case success(ListPhotosResponse)
        case failure(APIClientError)
    }

    private var outcomes: [Outcome]
    private(set) var requests: [ListPhotosQuery] = []

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func list(_ query: ListPhotosQuery) async throws -> ListPhotosResponse {
        requests.append(query)
        guard !outcomes.isEmpty else { throw APIClientError.invalidResponse }
        switch outcomes.removeFirst() {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}
