import Foundation
import XCTest
@testable import GYMUP

final class APIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        StubURLProtocol.install { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, Data(#"{"result":"ok"}"#.utf8))
        }
    }

    override func tearDown() {
        StubURLProtocol.install { _ in
            throw APIClientTestError.noResponseConfigured
        }
        super.tearDown()
    }

    func testBuildsJSONRequestWithBearerAndCallerHeaders() async throws {
        let body = TestRequest(value: "sample")
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            return (response, Data(#"{"result":"saved"}"#.utf8))
        }

        let endpoint = APIEndpoint(
            method: .put,
            path: "/api/v1/users/me/onboarding",
            headers: ["Idempotency-Key": "request-123"]
        )
        let response = try await makeClient(token: "test-token").send(endpoint, body: body, as: TestResponse.self)

        XCTAssertEqual(response, TestResponse(result: "saved"))
        XCTAssertEqual(capturedRequest?.httpMethod, "PUT")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/users/me/onboarding")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Idempotency-Key"), "request-123")
        XCTAssertEqual(try JSONDecoder().decode(TestRequest.self, from: XCTUnwrap(capturedRequest?.httpBody)), body)
    }

    func testPreservesServerErrorCodeAndMessage() async throws {
        StubURLProtocol.install { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, Data(#"{"detail":{"code":"OUT_OF_RANGE","message":"Rest time is invalid."}}"#.utf8))
        }

        do {
            _ = try await makeClient(token: "test-token").send(
                APIEndpoint(method: .patch, path: "/api/v1/users/me/settings/rest-time"),
                body: TestRequest(value: "sample"),
                as: TestResponse.self
            )
            XCTFail("Expected the server error to be thrown")
        } catch let error as APIClientError {
            XCTAssertEqual(
                error,
                .server(
                    statusCode: 400,
                    detail: ServerErrorDetail(code: "OUT_OF_RANGE", message: "Rest time is invalid.")
                )
            )
        }
    }

    func testRejectsUnexpectedSuccessfulStatusCodeWhenEndpointSpecifiesOne() async throws {
        do {
            _ = try await makeClient(token: "test-token").send(
                APIEndpoint(method: .post, path: "/api/v1/workouts", expectedStatusCode: 201),
                body: TestRequest(value: "sample"),
                as: TestResponse.self
            )
            XCTFail("Expected a status-code mismatch")
        } catch let error as APIClientError {
            XCTAssertEqual(error, .unexpectedStatusCode(200))
        }
    }

    func testDoesNotSendAuthenticatedRequestWithoutToken() async throws {
        var requestWasSent = false
        StubURLProtocol.install { request in
            requestWasSent = true
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, Data(#"{"result":"ok"}"#.utf8))
        }

        do {
            _ = try await makeClient(token: nil).send(
                APIEndpoint(method: .get, path: "/api/v1/test"),
                as: TestResponse.self
            )
            XCTFail("Expected a missing token error")
        } catch let error as APIClientError {
            XCTAssertEqual(error, .missingBearerToken)
        }

        XCTAssertFalse(requestWasSent)
    }

    func testBuildsURLWithBasePathAndQueryItems() throws {
        let baseURL = try XCTUnwrap(URL(string: "https://api.example.test/gateway/"))
        let environment = try APIEnvironment(baseURL: baseURL)
        let endpoint = APIEndpoint(
            method: .get,
            path: "api/v1/workouts",
            queryItems: [URLQueryItem(name: "cursor", value: "next-page"), URLQueryItem(name: "limit", value: "20")]
        )

        let components = try XCTUnwrap(URLComponents(url: environment.url(for: endpoint), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.path, "/gateway/api/v1/workouts")
        XCTAssertEqual(components.queryItems, endpoint.queryItems)
    }

    func testRejectsURLWithoutHTTPHost() throws {
        let fileURL = try XCTUnwrap(URL(string: "file:///tmp/api"))

        XCTAssertThrowsError(try APIEnvironment(baseURL: fileURL)) { error in
            XCTAssertEqual(error as? APIClientError, .invalidBaseURL)
        }
    }

    func testOnboardingServiceUsesDocumentedPUTContract() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let data = Data(
                #"{"userId":"user-1","profileCompleted":true,"experienceLevel":{"level":"starter"},"goalType":"strength","weeklyWorkoutTarget":3}"#.utf8
            )
            return (response, data)
        }
        let request = SaveOnboardingRequest(
            experienceLevel: .object(["level": .string("starter")]),
            goalType: .string("strength"),
            weeklyWorkoutTarget: 3
        )

        let response = try await OnboardingAPIService(client: makeClient(token: "test-token")).save(request)

        XCTAssertEqual(capturedRequest?.httpMethod, "PUT")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/users/me/onboarding")
        XCTAssertEqual(response.userId, "user-1")
        XCTAssertTrue(response.profileCompleted)
        XCTAssertEqual(response.experienceLevel, .object(["level": .string("starter")]))
        XCTAssertEqual(response.goalType, .string("strength"))
        XCTAssertEqual(response.weeklyWorkoutTarget, 3)
        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(object["weeklyWorkoutTarget"] as? Int, 3)
        XCTAssertEqual(Set(object.keys), Set(["experienceLevel", "goalType", "weeklyWorkoutTarget"]))
    }

    func testDefaultRestTimeServiceUsesSecondsAndDecodesTimestamp() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, Data(#"{"defaultRestSeconds":90,"updatedAt":"2026-10-31T09:00:00Z"}"#.utf8))
        }

        let response = try await UserSettingsAPIService(client: makeClient(token: "test-token"))
            .updateDefaultRestTime(seconds: 90)

        XCTAssertEqual(capturedRequest?.httpMethod, "PATCH")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/users/me/settings/rest-time")
        XCTAssertEqual(response, UpdateDefaultRestTimeResponse(defaultRestSeconds: 90, updatedAt: "2026-10-31T09:00:00Z"))
        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Int])
        XCTAssertEqual(object, ["defaultRestSeconds": 90])
    }

    func testPhotosListUsesDocumentedQueryAndDecodesPage() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let data = Data(
                #"{"items":[{"photoId":"photo-1","workoutId":"workout-1","capturedAt":"2026-10-31T09:00:00Z","thumbnailUrl":"https://cdn.example.test/photo.jpg"}],"nextCursor":"cursor-2"}"#.utf8
            )
            return (response, data)
        }

        let response = try await PhotosAPIService(client: makeClient(token: "test-token")).list(
            ListPhotosQuery(cursor: "cursor-1", size: 20, from: "2026-10-01", to: "2026-10-31", sort: "recent")
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
            let data = Data(
                #"{"routineId":"routine-1","playlist":{"provider":"spotify","playlistId":"playlist-1","playlistName":"Lift","externalUrl":"https://open.spotify.com/playlist/playlist-1"},"updatedAt":"2026-10-31T09:00:00Z"}"#.utf8
            )
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
        XCTAssertEqual(try JSONDecoder().decode(UpdateRoutinePlaylistRequest.self, from: XCTUnwrap(capturedRequest?.httpBody)), request)
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
            let body = #"{"photoId":"photo-1","uploadUrl":"https://storage.example.test/upload","uploadHeaders":{"Content-Type":"image/jpeg","x-upload-token":"abc"},"expiresAt":"2026-10-31T10:00:00Z"}"#
            return (response, Data(body.utf8))
        }

        let result = try await PhotosAPIService(client: makeClient(token: "test-token")).requestWorkoutPhotoUpload(
            workoutId: "workout-1",
            request: RequestWorkoutPhotoUploadRequest(fileName: "progress.jpg", contentType: "image/jpeg", size: 512_000)
        )

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/workouts/workout-1/photos")
        XCTAssertEqual(result.photoId, "photo-1")
        XCTAssertEqual(
            result.uploadHeaders,
            .object(["Content-Type": .string("image/jpeg"), "x-upload-token": .string("abc")])
        )
    }

    func testExerciseStatisticsDecodesPointsAndOpaqueSummary() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let body = #"{"exerciseId":"exercise-1","metric":"volume","points":[{"date":"2026-10-31","value":1250.5}],"summary":{"average":625.25,"trend":"up"}}"#
            return (response, Data(body.utf8))
        }

        let result = try await ExerciseStatisticsAPIService(client: makeClient(token: "test-token")).statistics(
            exerciseId: "exercise-1",
            query: ExerciseStatisticsQuery(metric: "volume", from: "2026-10-01", to: "2026-10-31", interval: "week")
        )

        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/statistics/exercises/exercise-1")
        XCTAssertEqual(result.points, [ExerciseStatisticPoint(date: "2026-10-31", value: 1250.5)])
        XCTAssertEqual(
            result.summary,
            .object(["average": .number(625.25), "trend": .string("up")])
        )
    }

    func testWorkoutHistoryServicesDecodeOpaqueNestedValues() async throws {
        var capturedRequests: [URLRequest] = []
        StubURLProtocol.install { request in
            capturedRequests.append(request)
            let path = try XCTUnwrap(request.url?.path)
            let body: String
            if path.hasSuffix("/summary") {
                body = #"{"duration":1800,"totalSets":10,"volume":3200.0,"prs":[{"exerciseId":"exercise-1"}],"growthDelta":{"strength":2},"xp":50,"levelUp":{"level":4},"avatarGrowth":{"arm":1},"progressShotAvailable":true}"#
            } else if path.hasSuffix("/complete") {
                body = #"{"workoutId":"workout-1","status":"COMPLETED","duration":1800,"totalSets":10,"volume":3200.0,"prs":[{"exerciseId":"exercise-1"}],"xp":50,"growthDelta":{"strength":2}}"#
            } else {
                body = #"{"workoutId":"workout-1","routine":{"routineId":"routine-1"},"duration":1800,"totalSets":10,"volume":3200.0,"exercises":[{"sets":[{"reps":8,"weight":40.0,"pr":false}]}]}"#
            }
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, Data(body.utf8))
        }

        let service = WorkoutHistoryAPIService(client: try makeClient(token: "test-token"))
        let detail = try await service.detail(workoutId: "workout-1")
        let summary = try await service.summary(workoutId: "workout-1")
        let completed = try await service.complete(
            workoutId: "workout-1",
            request: CompleteWorkoutRequest(endedAt: "2026-10-31T09:30:00Z", expectedVersion: 3)
        )

        XCTAssertEqual(capturedRequests.map(\.httpMethod), ["GET", "GET", "POST"])
        XCTAssertEqual(capturedRequests.map { $0.url?.path }, [
            "/api/v1/workouts/workout-1",
            "/api/v1/workouts/workout-1/summary",
            "/api/v1/workouts/workout-1/complete"
        ])
        XCTAssertEqual(detail.routine, .object(["routineId": .string("routine-1")]))
        XCTAssertEqual(detail.exercises.first?.sets.first?.reps, 8)
        XCTAssertEqual(summary.prs, .array([.object(["exerciseId": .string("exercise-1")])]))
        XCTAssertEqual(summary.levelUp, .object(["level": .integer(4)]))
        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(completed.growthDelta, .object(["strength": .integer(2)]))
        let completeRequest = try XCTUnwrap(capturedRequests.last?.httpBody)
        XCTAssertEqual(
            try JSONDecoder().decode(CompleteWorkoutRequest.self, from: completeRequest),
            CompleteWorkoutRequest(endedAt: "2026-10-31T09:30:00Z", expectedVersion: 3)
        )
    }

    func testPlateCalculatorUsesTypedWeightsAndOpaquePlateItems() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.install { request in
            capturedRequest = request
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let body = #"{"achievable":true,"eachSide":[{"weight":20.0,"count":1}],"actualWeight":60.0,"remainder":0.0}"#
            return (response, Data(body.utf8))
        }

        let availablePlate = JSONValue.object(["weight": .number(20), "count": .integer(2)])
        let result = try await PlateCalculatorAPIService(client: makeClient(token: "test-token")).calculate(
            PlateCalculatorRequest(targetWeight: 60, barWeight: 20, availablePlates: [availablePlate])
        )

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/tools/plate-calculator")
        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let bodyObject = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(bodyObject["targetWeight"] as? Double, 60)
        let plates = try XCTUnwrap(bodyObject["availablePlates"] as? [[String: Any]])
        XCTAssertEqual(plates.first?["weight"] as? Double, 20)
        XCTAssertTrue(result.achievable)
        XCTAssertEqual(result.eachSide, [PlateWeightCount(weight: 20, count: 1)])
    }

    func testWorkoutSessionMutationsUseExpectedPathsStatusesAndIdempotencyHeader() async throws {
        var capturedRequests: [URLRequest] = []
        StubURLProtocol.install { request in
            capturedRequests.append(request)
            let path = try XCTUnwrap(request.url?.path)
            let statusCode = path.hasSuffix("/rests") || path == "/api/v1/workouts" || path.hasSuffix("/sets") ? 201 : 200
            let body: String
            if path.hasSuffix("/rests/current/skip") {
                body = #"{"restId":"rest-1","status":"SKIPPED","nextSet":{"exerciseId":"exercise-2"}}"#
            } else if path.hasSuffix("/rests") {
                body = #"{"restId":"rest-2","startedAt":"2026-10-31T09:00:00Z","endsAt":"2026-10-31T09:01:00Z","durationSeconds":60,"nextSet":{"exerciseId":"exercise-2"}}"#
            } else if path.hasSuffix("/current-exercise") {
                body = #"{"workoutId":"workout-1","currentExercise":{"exerciseId":"exercise-2"},"nextExercise":{"exerciseId":"exercise-3"},"status":"IN_PROGRESS"}"#
            } else if path.hasSuffix("/sets") {
                body = #"{"setId":"set-1","workoutId":"workout-1","exerciseId":"exercise-1","setIndex":1,"pr":false,"nextAction":{"type":"REST"},"rest":{"durationSeconds":60}}"#
            } else {
                body = #"{"workoutId":"workout-1","status":"IN_PROGRESS","routineSnapshot":{"routineId":"routine-1"},"currentExercise":{"exerciseId":"exercise-1"},"startedAt":"2026-10-31T09:00:00Z"}"#
            }
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: statusCode, httpVersion: nil, headerFields: nil)
            )
            return (response, Data(body.utf8))
        }

        let service = WorkoutSessionAPIService(client: try makeClient(token: "test-token"))
        let skipped = try await service.skipCurrentRest(workoutId: "workout-1")
        let rest = try await service.startRest(
            workoutId: "workout-1",
            request: StartRestRequest(setId: "set-1", durationSeconds: 60)
        )
        let advanced = try await service.advanceExercise(
            workoutId: "workout-1",
            request: AdvanceWorkoutExerciseRequest(completedExerciseId: "exercise-1")
        )
        let createdSet = try await service.createSet(
            workoutId: "workout-1",
            request: CreateWorkoutSetRequest(
                exerciseId: "exercise-1",
                setIndex: 1,
                weight: 40,
                reps: 8,
                completedAt: "2026-10-31T09:00:00Z"
            ),
            idempotencyKey: "set-request-1"
        )
        let started = try await service.startWorkout(
            request: StartWorkoutRequest(routineId: "routine-1", startedAt: "2026-10-31T09:00:00Z", timezone: "Asia/Seoul")
        )

        XCTAssertEqual(capturedRequests.map(\.httpMethod), ["POST", "POST", "PATCH", "POST", "POST"])
        XCTAssertEqual(capturedRequests.map { $0.url?.path }, [
            "/api/v1/workouts/workout-1/rests/current/skip",
            "/api/v1/workouts/workout-1/rests",
            "/api/v1/workouts/workout-1/current-exercise",
            "/api/v1/workouts/workout-1/sets",
            "/api/v1/workouts"
        ])
        XCTAssertEqual(capturedRequests.map { ($0.value(forHTTPHeaderField: "Idempotency-Key") ?? "") }, ["", "", "", "set-request-1", ""])
        XCTAssertEqual(skipped.status, .skipped)
        XCTAssertEqual(rest.nextSet, .object(["exerciseId": .string("exercise-2")]))
        XCTAssertEqual(advanced.currentExercise, .object(["exerciseId": .string("exercise-2")]))
        XCTAssertEqual(createdSet.nextAction, .object(["type": .string("REST")]))
        XCTAssertEqual(createdSet.rest, .object(["durationSeconds": .integer(60)]))
        XCTAssertEqual(started.status, .inProgress)
        XCTAssertEqual(started.routineSnapshot, .object(["routineId": .string("routine-1")]))
    }

    func testWorkoutListAndNextSetServicesDecodeDocumentedResponses() async throws {
        var capturedPaths: [String] = []
        StubURLProtocol.install { request in
            let path = try XCTUnwrap(request.url?.path)
            capturedPaths.append(path)
            let body: String
            if path == "/api/v1/workouts" {
                body = #"{"items":[{"workoutId":"workout-1","date":"2026-10-31","routineName":"Upper","duration":1800,"totalSets":12,"volume":3600.5}],"nextCursor":"cursor-2"}"#
            } else {
                body = #"{"exerciseId":"exercise-1","exerciseName":"Bench Press","setIndex":2,"weight":40.0,"reps":8,"restEndsAt":"2026-10-31T09:30:00Z"}"#
            }
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, Data(body.utf8))
        }

        let service = WorkoutReadAPIService(client: try makeClient(token: "test-token"))
        let workouts = try await service.list(
            ListWorkoutsQuery(cursor: "cursor-1", size: 10, from: "2026-10-01", to: "2026-10-31", routineId: "routine-1")
        )
        let nextSet = try await service.nextSet(workoutId: "workout-1")

        XCTAssertEqual(capturedPaths, ["/api/v1/workouts", "/api/v1/workouts/workout-1/next-set"])
        XCTAssertEqual(workouts.items.first?.volume, 3600.5)
        XCTAssertEqual(workouts.nextCursor, "cursor-2")
        XCTAssertEqual(nextSet.setIndex, 2)
        XCTAssertEqual(nextSet.reps, 8)
    }

    func testRestReadAndExtendServicesUseDocumentedContracts() async throws {
        var capturedRequests: [URLRequest] = []
        StubURLProtocol.install { request in
            capturedRequests.append(request)
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            let body = request.httpMethod == "GET"
                ? #"{"restId":"rest-1","status":"ACTIVE","startedAt":"2026-10-31T09:00:00Z","endsAt":"2026-10-31T09:01:00Z","remainingSeconds":60,"notificationAt":"2026-10-31T09:00:50Z"}"#
                : #"{"restId":"rest-1","endsAt":"2026-10-31T09:01:15Z","remainingSeconds":75}"#
            return (response, Data(body.utf8))
        }

        let service = WorkoutReadAPIService(client: try makeClient(token: "test-token"))
        let current = try await service.currentRest(workoutId: "workout-1")
        let extended = try await service.extendCurrentRest(workoutId: "workout-1", by: 15)

        XCTAssertEqual(capturedRequests.map(\.httpMethod), ["GET", "PATCH"])
        XCTAssertEqual(capturedRequests.map { $0.url?.path }, [
            "/api/v1/workouts/workout-1/rests/current",
            "/api/v1/workouts/workout-1/rests/current/extend"
        ])
        XCTAssertEqual(current.remainingSeconds, 60)
        XCTAssertEqual(extended.remainingSeconds, 75)
        let body = try XCTUnwrap(capturedRequests.last?.httpBody)
        XCTAssertEqual(try JSONDecoder().decode(ExtendCurrentRestRequest.self, from: body).seconds, 15)
    }

    func testExerciseReadServicesDecodeGuideStatusAndPreviousRecord() async throws {
        var capturedPaths: [String] = []
        var capturedQueries: [[URLQueryItem]] = []
        StubURLProtocol.install { request in
            let path = try XCTUnwrap(request.url?.path)
            capturedPaths.append(path)
            capturedQueries.append(
                URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
            )
            let body: String
            if path.hasSuffix("first-time-status") {
                body = #"{"exerciseId":"exercise-1","isFirstTime":true,"guideAvailable":true}"#
            } else if path.hasSuffix("/guide") {
                body = #"{"exerciseId":"exercise-1","mediaUrl":"https://cdn.example.test/guide.mp4","targetMuscles":["chest"],"keyPoints":["brace"],"commonMistakes":["bounce"]}"#
            } else {
                body = #"{"exerciseId":"exercise-1","hasPreviousRecord":true,"weight":50.0,"reps":8,"setIndex":3,"performedAt":"2026-10-30T09:00:00Z"}"#
            }
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, Data(body.utf8))
        }

        let service = ExerciseReadAPIService(client: try makeClient(token: "test-token"))
        let status = try await service.firstTimeStatus(exerciseId: "exercise-1")
        let guide = try await service.guide(exerciseId: "exercise-1")
        let record = try await service.previousRecord(exerciseId: "exercise-1", query: .init(beforeWorkoutId: "workout-1"))

        XCTAssertEqual(capturedPaths, [
            "/api/v1/exercises/exercise-1/first-time-status",
            "/api/v1/exercises/exercise-1/guide",
            "/api/v1/exercises/exercise-1/previous-record"
        ])
        XCTAssertTrue(status.isFirstTime)
        XCTAssertEqual(guide.targetMuscles, ["chest"])
        XCTAssertEqual(record.weight, 50)
        XCTAssertEqual(capturedQueries[2], [URLQueryItem(name: "beforeWorkoutId", value: "workout-1")])
    }

    private func makeClient(token: String?) throws -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let baseURL = try XCTUnwrap(URL(string: "https://api.example.test"))
        return APIClient(
            environment: try APIEnvironment(baseURL: baseURL),
            session: session,
            tokenProvider: TestTokenProvider(token: token)
        )
    }
}

private struct TestRequest: Codable, Equatable {
    let value: String
}

private struct TestResponse: Decodable, Equatable {
    let result: String
}

private struct TestTokenProvider: BearerTokenProviding {
    let token: String?

    func accessToken() async throws -> String? {
        token
    }
}

private enum APIClientTestError: Error {
    case noResponseConfigured
}

private final class StubURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    private static var handler: Handler = { _ in throw APIClientTestError.noResponseConfigured }

    static func install(_ newHandler: @escaping Handler) {
        lock.lock()
        defer { lock.unlock() }
        handler = newHandler
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        let activeHandler = Self.handler
        Self.lock.unlock()

        do {
            let (response, data) = try activeHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
