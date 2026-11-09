import Foundation
import XCTest
@testable import GYMUP

final class WorkoutPhotoUploadAPITests: NetworkingTestCase {
    func testUploadUsesSignedURLHeadersAndDoesNotForwardBearerToken() async throws {
        var capturedRequests: [URLRequest] = []
        let imageData = Data([0xFF, 0xD8, 0x00, 0xFE, 0xD9])
        StubURLProtocol.install { request in
            let materializedRequest = try StubURLProtocol.materializeBodyStream(in: request)
            capturedRequests.append(materializedRequest)
            let isMetadataRequest = materializedRequest.httpMethod == "POST"
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(materializedRequest.url),
                    statusCode: isMetadataRequest ? 201 : 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            let body = #"""
            {
              "photoId": "photo-1",
              "uploadUrl": "https://storage.example.test/signed-upload",
              "uploadHeaders": {
                "Content-Type": "image/jpeg",
                "x-upload-signature": "signed-value"
              },
              "expiresAt": "2030-01-01T00:00:00Z"
            }
            """#
            return (response, isMetadataRequest ? Data(body.utf8) : Data())
        }

        let service = PhotosAPIService(
            client: try makeClient(token: "app-secret-token"),
            uploadSession: makeUploadSession()
        )
        let upload = try await service.requestWorkoutPhotoUpload(
            workoutId: "workout-1",
            request: RequestWorkoutPhotoUploadRequest(
                fileName: "workout-progress.jpg",
                contentType: "image/jpeg",
                size: imageData.count
            )
        )
        try await service.uploadWorkoutPhoto(
            imageData,
            using: upload,
            now: Date(timeIntervalSince1970: 1_800_000_000)
        )

        XCTAssertEqual(capturedRequests.map(\.httpMethod), ["POST", "PUT"])
        XCTAssertEqual(capturedRequests[0].url?.path, "/api/v1/workouts/workout-1/photos")
        XCTAssertEqual(
            capturedRequests[0].value(forHTTPHeaderField: "Authorization"),
            "Bearer app-secret-token"
        )
        XCTAssertEqual(
            capturedRequests[1].url?.absoluteString,
            "https://storage.example.test/signed-upload"
        )
        XCTAssertNil(capturedRequests[1].value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(capturedRequests[1].value(forHTTPHeaderField: "Content-Type"), "image/jpeg")
        XCTAssertEqual(capturedRequests[1].value(forHTTPHeaderField: "x-upload-signature"), "signed-value")
        XCTAssertEqual(capturedRequests[1].httpBody, imageData)
    }

    func testStorageRetryReusesIssuedURLWithoutCreatingMetadataAgain() async throws {
        var capturedRequests: [URLRequest] = []
        var putAttempts = 0
        StubURLProtocol.install { request in
            let materializedRequest = try StubURLProtocol.materializeBodyStream(in: request)
            capturedRequests.append(materializedRequest)
            if materializedRequest.httpMethod == "POST" {
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: try XCTUnwrap(request.url),
                        statusCode: 201,
                        httpVersion: nil,
                        headerFields: nil
                    )
                )
                let body = #"""
                {
                  "photoId": "photo-2",
                  "uploadUrl": "https://storage.example.test/retry-upload",
                  "uploadHeaders": {"x-upload-signature": "same-signature"},
                  "expiresAt": "2030-01-01T00:00:00Z"
                }
                """#
                return (response, Data(body.utf8))
            }

            putAttempts += 1
            let statusCode = putAttempts == 1 ? 503 : 204
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            return (response, Data())
        }

        let service = PhotosAPIService(
            client: try makeClient(token: "app-secret-token"),
            uploadSession: makeUploadSession()
        )
        let upload = try await service.requestWorkoutPhotoUpload(
            workoutId: "workout-2",
            request: RequestWorkoutPhotoUploadRequest(
                fileName: "progress.jpg",
                contentType: "image/jpeg",
                size: 4
            )
        )
        let imageData = Data([1, 2, 3, 4])

        do {
            try await service.uploadWorkoutPhoto(
                imageData,
                using: upload,
                now: Date(timeIntervalSince1970: 1_800_000_000)
            )
            XCTFail("The first storage attempt should fail with a retryable server response.")
        } catch let error as WorkoutPhotoStorageUploadError {
            XCTAssertEqual(error, .httpStatus(503))
            XCTAssertTrue(error.isRetryable)
        }
        try await service.uploadWorkoutPhoto(
            imageData,
            using: upload,
            now: Date(timeIntervalSince1970: 1_800_000_000)
        )

        XCTAssertEqual(capturedRequests.filter { $0.httpMethod == "POST" }.count, 1)
        let putRequests = capturedRequests.filter { $0.httpMethod == "PUT" }
        XCTAssertEqual(putRequests.count, 2)
        XCTAssertEqual(
            putRequests.map { $0.url?.absoluteString },
            Array(repeating: "https://storage.example.test/retry-upload", count: 2)
        )
        XCTAssertEqual(putRequests.map(\.httpBody), [imageData, imageData])
        XCTAssertTrue(
            putRequests.allSatisfy { $0.value(forHTTPHeaderField: "x-upload-signature") == "same-signature" }
        )
        XCTAssertTrue(putRequests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == nil })
    }

    func testStorageUploadRejectsExpiredURLBeforeSendingRequest() async throws {
        var requestCount = 0
        StubURLProtocol.install { request in
            requestCount += 1
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            let body = #"""
            {
              "photoId": "photo-3",
              "uploadUrl": "https://storage.example.test/expired",
              "uploadHeaders": {},
              "expiresAt": "2020-01-01T00:00:00Z"
            }
            """#
            return (response, Data(body.utf8))
        }

        let service = PhotosAPIService(
            client: try makeClient(token: "app-secret-token"),
            uploadSession: makeUploadSession()
        )
        let upload = try await service.requestWorkoutPhotoUpload(
            workoutId: "workout-3",
            request: RequestWorkoutPhotoUploadRequest(
                fileName: "progress.jpg",
                contentType: "image/jpeg",
                size: 1
            )
        )

        do {
            try await service.uploadWorkoutPhoto(
                Data([1]),
                using: upload,
                now: Date(timeIntervalSince1970: 1_800_000_000)
            )
            XCTFail("An expired signed URL must not be used.")
        } catch let error as WorkoutPhotoStorageUploadError {
            XCTAssertEqual(error, .expired)
            XCTAssertFalse(error.isRetryable)
        }

        XCTAssertEqual(requestCount, 1, "Only the metadata request should have been sent.")
    }

    func testStorageUploadRejectsCrossOriginRedirect() async throws {
        var capturedRequests: [URLRequest] = []
        StubURLProtocol.install { request in
            capturedRequests.append(request)
            let isMetadataRequest = request.httpMethod == "POST"
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: isMetadataRequest ? 201 : 307,
                    httpVersion: nil,
                    headerFields: isMetadataRequest
                        ? nil
                        : ["Location": "https://attacker.example.test/collect"]
                )
            )
            let body = #"""
            {
              "photoId": "photo-4",
              "uploadUrl": "https://storage.example.test/redirect",
              "uploadHeaders": {"x-upload-signature": "secret-signature"},
              "expiresAt": "2030-01-01T00:00:00Z"
            }
            """#
            return (response, isMetadataRequest ? Data(body.utf8) : Data())
        }

        let service = PhotosAPIService(
            client: try makeClient(token: "app-secret-token"),
            uploadSession: makeUploadSession()
        )
        let upload = try await service.requestWorkoutPhotoUpload(
            workoutId: "workout-4",
            request: RequestWorkoutPhotoUploadRequest(
                fileName: "progress.jpg",
                contentType: "image/jpeg",
                size: 1
            )
        )

        do {
            try await service.uploadWorkoutPhoto(
                Data([1]),
                using: upload,
                now: Date(timeIntervalSince1970: 1_800_000_000)
            )
            XCTFail("A redirect to a different origin must be rejected.")
        } catch let error as WorkoutPhotoStorageUploadError {
            XCTAssertEqual(error, .httpStatus(307))
            XCTAssertFalse(error.isRetryable)
        }

        XCTAssertEqual(capturedRequests.count, 2)
        XCTAssertEqual(capturedRequests.last?.url?.host, "storage.example.test")
    }

    private func makeUploadSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        let redirectDelegate = WorkoutPhotoStorageUploadRedirectDelegate()
        return URLSession(configuration: configuration, delegate: redirectDelegate, delegateQueue: nil)
    }
}
