import Foundation
import XCTest
@testable import GYMUP

final class WorkoutAPIServiceTests: NetworkingTestCase {
    func testExerciseStatisticsDecodesPointsAndOpaqueSummary() async throws {
        var capturedRequest: URLRequest?
        installJSONResponse(
            [
                "exerciseId": "exercise-1",
                "metric": "volume",
                "points": [["date": "2026-10-31", "value": 1250.5]],
                "summary": ["average": 625.25, "trend": "up"]
            ],
            recordRequest: { capturedRequest = $0 }
        )

        let query = ExerciseStatisticsQuery(
            metric: "volume",
            from: "2026-10-01",
            endDate: "2026-10-31",
            interval: "week"
        )
        let service = try ExerciseStatisticsAPIService(client: makeClient(token: "test-token"))
        let response = try await service.statistics(exerciseId: "exercise-1", query: query)

        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/statistics/exercises/exercise-1")
        XCTAssertEqual(response.points, [ExerciseStatisticPoint(date: "2026-10-31", value: 1250.5)])
        XCTAssertEqual(response.summary, .object(["average": .number(625.25), "trend": .string("up")]))
    }
    func testWorkoutDetailDecodesTypedSetsAndOpaqueRoutine() async throws {
        installJSONResponse([
            "workoutId": "workout-1",
            "routine": ["routineId": "routine-1"],
            "duration": 1800,
            "totalSets": 10,
            "volume": 3200.0,
            "exercises": [["sets": [["reps": 8, "weight": 40.0, "pr": false]]]]
        ])

        let service = try WorkoutHistoryAPIService(client: makeClient(token: "test-token"))
        let detail = try await service.detail(workoutId: "workout-1")

        XCTAssertEqual(detail.routine, .object(["routineId": .string("routine-1")]))
        XCTAssertEqual(detail.exercises.first?.sets.first?.reps, 8)
        XCTAssertFalse(detail.exercises[0].sets[0].isPersonalRecord)
    }
    func testWorkoutSummaryPreservesOpaqueFields() async throws {
        installJSONResponse([
            "duration": 1800,
            "totalSets": 10,
            "volume": 3200.0,
            "prs": [["exerciseId": "exercise-1"]],
            "growthDelta": ["strength": 2],
            "xp": 50,
            "levelUp": ["level": 4],
            "avatarGrowth": ["arm": 1],
            "progressShotAvailable": true
        ])

        let service = try WorkoutHistoryAPIService(client: makeClient(token: "test-token"))
        let summary = try await service.summary(workoutId: "workout-1")

        XCTAssertEqual(summary.experiencePoints, 50)
        XCTAssertEqual(summary.levelUp, .object(["level": .integer(4)]))
        XCTAssertEqual(summary.prs, .array([.object(["exerciseId": .string("exercise-1")])]))
    }
    func testWorkoutCompletionUsesDocumentedRequestAndResponse() async throws {
        var capturedRequest: URLRequest?
        installJSONResponse(
            [
                "workoutId": "workout-1",
                "status": "COMPLETED",
                "duration": 1800,
                "totalSets": 10,
                "volume": 3200.0,
                "prs": [["exerciseId": "exercise-1"]],
                "xp": 50,
                "growthDelta": ["strength": 2]
            ],
            recordRequest: { capturedRequest = $0 }
        )

        let request = CompleteWorkoutRequest(endedAt: "2026-10-31T09:30:00Z", expectedVersion: 3)
        let service = try WorkoutHistoryAPIService(client: makeClient(token: "test-token"))
        let response = try await service.complete(workoutId: "workout-1", request: request)

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(response.status, .completed)
        XCTAssertEqual(response.experiencePoints, 50)
        XCTAssertEqual(response.growthDelta, .object(["strength": .integer(2)]))
        let body = try XCTUnwrap(capturedRequest?.httpBody)
        XCTAssertEqual(try JSONDecoder().decode(CompleteWorkoutRequest.self, from: body), request)
    }
    func testPlateCalculatorUsesTypedWeightsAndOpaquePlateItems() async throws {
        var capturedRequest: URLRequest?
        installJSONResponse(
            ["achievable": true, "eachSide": [["weight": 20.0, "count": 1]], "actualWeight": 60.0, "remainder": 0.0],
            recordRequest: { capturedRequest = $0 }
        )

        let availablePlate = JSONValue.object(["weight": .number(20), "count": .integer(2)])
        let request = PlateCalculatorRequest(targetWeight: 60, barWeight: 20, availablePlates: [availablePlate])
        let service = try PlateCalculatorAPIService(client: makeClient(token: "test-token"))
        let response = try await service.calculate(request)

        XCTAssertEqual(capturedRequest?.url?.path, "/api/v1/tools/plate-calculator")
        XCTAssertTrue(response.achievable)
        XCTAssertEqual(response.eachSide, [PlateWeightCount(weight: 20, count: 1)])
        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual((object["availablePlates"] as? [[String: Any]])?.first?["weight"] as? Double, 20)
    }
    func testWorkoutListDecodesPagedItemsAndNextSet() async throws {
        let paths = [
            "/api/v1/workouts": (
                200,
                [
                    "items": [[
                        "workoutId": "workout-1",
                        "date": "2026-10-31",
                        "routineName": "Upper",
                        "duration": 1800,
                        "totalSets": 12,
                        "volume": 3600.5
                    ]],
                    "nextCursor": "cursor-2"
                ] as [String: Any]
            ),
            "/api/v1/workouts/workout-1/next-set": (
                200,
                [
                    "exerciseId": "exercise-1",
                    "exerciseName": "Bench Press",
                    "setIndex": 2,
                    "weight": 40.0,
                    "reps": 8,
                    "restEndsAt": "2026-10-31T09:30:00Z"
                ] as [String: Any]
            )
        ]
        installJSONResponses(paths)
        let service = try WorkoutReadAPIService(client: makeClient(token: "test-token"))

        let query = ListWorkoutsQuery(
            cursor: "cursor-1",
            size: 10,
            from: "2026-10-01",
            endDate: "2026-10-31",
            routineId: "routine-1"
        )
        let list = try await service.list(query)
        let nextSet = try await service.nextSet(workoutId: "workout-1")

        XCTAssertEqual(list.items.first?.volume, 3600.5)
        XCTAssertEqual(list.nextCursor, "cursor-2")
        XCTAssertEqual(nextSet.setIndex, 2)
    }
    func testCurrentRestAndExtensionDecodeResponses() async throws {
        let paths = [
            "/api/v1/workouts/workout-1/rests/current": (
                200,
                [
                    "restId": "rest-1",
                    "status": "ACTIVE",
                    "startedAt": "2026-10-31T09:00:00Z",
                    "endsAt": "2026-10-31T09:01:00Z",
                    "remainingSeconds": 60,
                    "notificationAt": "2026-10-31T09:00:50Z"
                ] as [String: Any]
            ),
            "/api/v1/workouts/workout-1/rests/current/extend": (
                200,
                ["restId": "rest-1", "endsAt": "2026-10-31T09:01:15Z", "remainingSeconds": 75] as [String: Any]
            )
        ]
        var requests: [URLRequest] = []
        installJSONResponses(paths, recordRequest: { requests.append($0) })
        let service = try WorkoutReadAPIService(client: makeClient(token: "test-token"))

        let current = try await service.currentRest(workoutId: "workout-1")
        let extended = try await service.extendCurrentRest(workoutId: "workout-1", by: 15)

        XCTAssertEqual(current.remainingSeconds, 60)
        XCTAssertEqual(extended.remainingSeconds, 75)
        let request = try JSONDecoder().decode(
            ExtendCurrentRestRequest.self,
            from: try XCTUnwrap(requests.last?.httpBody)
        )
        XCTAssertEqual(request.seconds, 15)
    }
    func testExerciseReadServicesDecodeGuidesAndPreviousRecord() async throws {
        let paths = [
            "/api/v1/exercises/exercise-1/first-time-status": (
                200,
                ["exerciseId": "exercise-1", "isFirstTime": true, "guideAvailable": true] as [String: Any]
            ),
            "/api/v1/exercises/exercise-1/guide": (
                200,
                [
                    "exerciseId": "exercise-1",
                    "mediaUrl": "https://cdn.example.test/guide.mp4",
                    "targetMuscles": ["chest"],
                    "keyPoints": ["brace"],
                    "commonMistakes": ["bounce"]
                ] as [String: Any]
            ),
            "/api/v1/exercises/exercise-1/previous-record": (
                200,
                [
                    "exerciseId": "exercise-1",
                    "hasPreviousRecord": true,
                    "weight": 50.0,
                    "reps": 8,
                    "setIndex": 3,
                    "performedAt": "2026-10-30T09:00:00Z"
                ] as [String: Any]
            )
        ]
        var requests: [URLRequest] = []
        installJSONResponses(paths, recordRequest: { requests.append($0) })
        let service = try ExerciseReadAPIService(client: makeClient(token: "test-token"))

        let status = try await service.firstTimeStatus(exerciseId: "exercise-1")
        let guide = try await service.guide(exerciseId: "exercise-1")
        let query = PreviousExerciseRecordQuery(beforeWorkoutId: "workout-1")
        let record = try await service.previousRecord(exerciseId: "exercise-1", query: query)

        XCTAssertTrue(status.isFirstTime)
        XCTAssertEqual(guide.targetMuscles, ["chest"])
        XCTAssertEqual(record.weight, 50)
        XCTAssertEqual(requests[2].url?.query, "beforeWorkoutId=workout-1")
    }
}
