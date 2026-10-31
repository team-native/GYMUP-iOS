import Foundation
import XCTest
@testable import GYMUP

final class PhotoAPIServiceTests: NetworkingTestCase {
    func testPhotosListUsesDocumentedQueryAndDecodesPage() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let json = #"""
            {
              "items": [
                {
                  "photoId": "photo-1",
                  "workoutId": "workout-1",
                  "capturedAt": "2026-10-31T09:00:00Z",
                  "thumbnailUrl": "https://cdn.example.test/photo.jpg"
                }
              ],
              "nextCursor": "cursor-2"
            }
            """#
            let data = Data(json.utf8)
            return (response, data)
        }

        let response = try await PhotosAPIService(client: makeClient(token: "test-token")).list(
            ListPhotosQuery(
                cursor: "cursor-1",
                size: 20,
                from: "2026-10-01",
                endDate: "2026-10-31",
                sort: "recent"
            )
        )
        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/photos")
        XCTAssertEqual(
            URLComponents(url: try XCTUnwrap(capturedRequest?.url), resolvingAgainstBaseURL: false)?.queryItems,
            [
                URLQueryItem(name: "cursor", value: "cursor-1"),
                URLQueryItem(name: "size", value: "20"),
                URLQueryItem(name: "from", value: "2026-10-01"),
                URLQueryItem(name: "to", value: "2026-10-31"),
                URLQueryItem(name: "sort", value: "recent")
            ]
        )
        XCTAssertEqual(response.items.first?.photoId, "photo-1")
        XCTAssertEqual(response.nextCursor, "cursor-2")
    }

    func testPhotoDownloadURLServiceUsesDocumentedRoute() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let data = Data(
                #"{"photoId":"photo-1","downloadUrl":"https://cdn.example.test/full.jpg","expiresAt":"2026-10-31T10:00:00Z"}"#.utf8
            )
            return (response, data)
        }

        let result = try await PhotosAPIService(client: makeClient(token: "test-token"))
            .downloadURL(photoId: "photo-1")

        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/photos/photo-1/download-url")
        XCTAssertEqual(result.photoId, "photo-1")
        XCTAssertEqual(result.downloadUrl, "https://cdn.example.test/full.jpg")
    }

    func testRoutinePlaylistServiceUsesDocumentedPUTContract() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let json = #"""
            {
              "routineId": "routine-1",
              "playlist": {
                "provider": "spotify",
                "playlistId": "playlist-1",
                "playlistName": "Lift",
                "externalUrl": "https://open.spotify.com/playlist/playlist-1"
              },
              "updatedAt": "2026-10-31T09:00:00Z"
            }
            """#
            let data = Data(json.utf8)
            return (response, data)
        }

        let request = UpdateRoutinePlaylistRequest(
            provider: "spotify",
            playlistId: "playlist-1",
            playlistName: "Lift",
            externalUrl: "https://open.spotify.com/playlist/playlist-1"
        )
        let result = try await RoutineAPIService(client: makeClient(token: "test-token"))
            .updatePlaylist(routineId: "routine-1", request: request)

        XCTAssertEqual(capturedRequest?.httpMethod, "PUT")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/routines/routine-1/playlist")
        XCTAssertEqual(result.playlist.playlistId, "playlist-1")
        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let decodedRequest = try JSONDecoder().decode(UpdateRoutinePlaylistRequest.self, from: body)
        XCTAssertEqual(decodedRequest, request)
    }

    func testPhotoStampAndFilterServicesUseAcceptedStatusesAndDTOs() async throws {
        var capturedRequests: [URLRequest] = []
        StubURLProtocol.install { request in
            capturedRequests.append(request)
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 202, httpVersion: nil, headerFields: nil)
            )
            let jobId = request.url?.path.hasSuffix("/stamps") == true ? "stamp-job" : "filter-job"
            let body = #"{"jobId":"\#(jobId)","photoId":"photo-1","status":"PROCESSING"}"#
            return (response, Data(body.utf8))
        }

        let service = PhotosAPIService(client: try makeClient(token: "test-token"))
        let stamp = try await service.createStamp(
            photoId: "photo-1",
            request: CreatePhotoStampRequest(layoutId: "minimal", fields: ["routine", "duration", "sets"])
        )
        let filter = try await service.applyFilter(
            photoId: "photo-1",
            request: CreatePhotoFilterRequest(
                preset: "warm",
                adjustments: PhotoFilterAdjustments(contrast: 1, shadow: 2, sharpness: 3, highlight: 4, tone: 5)
            )
        )

        XCTAssertEqual(capturedRequests.map(\.httpMethod), ["POST", "POST"])
        XCTAssertEqual(capturedRequests.map { $0.url?.path }, [
            "/api/v1/photos/photo-1/stamps",
            "/api/v1/photos/photo-1/filters"
        ])
        XCTAssertEqual(stamp.status, .processing)
        XCTAssertEqual(filter.status, .processing)

        let stampBody = try XCTUnwrap(capturedRequests.first?.httpBody)
        let stampObject = try XCTUnwrap(JSONSerialization.jsonObject(with: stampBody) as? [String: Any])
        XCTAssertEqual(stampObject["layoutId"] as? String, "minimal")
        XCTAssertEqual(stampObject["fields"] as? [String], ["routine", "duration", "sets"])

        let filterBody = try XCTUnwrap(capturedRequests.last?.httpBody)
        let filterObject = try XCTUnwrap(JSONSerialization.jsonObject(with: filterBody) as? [String: Any])
        XCTAssertEqual(filterObject["preset"] as? String, "warm")
        XCTAssertEqual((filterObject["adjustments"] as? [String: Double])?["tone"], 5)
    }

    func testWorkoutPhotoUploadUsesCreatedStatusAndPreservesHeaders() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 201, httpVersion: nil, headerFields: nil)
            )
            let body = #"""
            {
              "photoId": "photo-1",
              "uploadUrl": "https://storage.example.test/upload",
              "uploadHeaders": {
                "Content-Type": "image/jpeg",
                "x-upload-token": "abc"
              },
              "expiresAt": "2026-10-31T10:00:00Z"
            }
            """#
            return (response, Data(body.utf8))
        }

        let result = try await PhotosAPIService(client: makeClient(token: "test-token")).requestWorkoutPhotoUpload(
            workoutId: "workout-1",
            request: RequestWorkoutPhotoUploadRequest(
                fileName: "progress.jpg",
                contentType: "image/jpeg",
                size: 512_000
            )
        )

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/workouts/workout-1/photos")
        XCTAssertEqual(result.photoId, "photo-1")
        XCTAssertEqual(
            result.uploadHeaders,
            .object(["Content-Type": .string("image/jpeg"), "x-upload-token": .string("abc")])
        )
    }
}
