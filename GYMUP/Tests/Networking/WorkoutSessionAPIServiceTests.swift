import Foundation
import XCTest
@testable import GYMUP

final class WorkoutSessionAPIServiceTests: NetworkingTestCase {
    func testRestSkipAndStartUseDocumentedStatuses() async throws {
        let paths = [
            "/api/v1/workouts/workout-1/rests/current/skip": (
                200,
                ["restId": "rest-1", "status": "SKIPPED", "nextSet": ["exerciseId": "exercise-2"]] as [String: Any]
            ),
            "/api/v1/workouts/workout-1/rests": (
                201,
                [
                    "restId": "rest-2",
                    "startedAt": "2026-10-31T09:00:00Z",
                    "endsAt": "2026-10-31T09:01:00Z",
                    "durationSeconds": 60,
                    "nextSet": ["exerciseId": "exercise-2"]
                ] as [String: Any]
            )
        ]
        var requests: [URLRequest] = []
        installJSONResponses(paths, recordRequest: { requests.append($0) })
        let service = try WorkoutSessionAPIService(client: makeClient(token: "test-token"))

        let skipped = try await service.skipCurrentRest(workoutId: "workout-1")
        let rest = try await service.startRest(
            workoutId: "workout-1",
            request: StartRestRequest(setId: "set-1", durationSeconds: 60)
        )

        XCTAssertEqual(requests.map(\.httpMethod), ["POST", "POST"])
        XCTAssertEqual(skipped.status, .skipped)
        XCTAssertEqual(rest.durationSeconds, 60)
        XCTAssertEqual(rest.nextSet, .object(["exerciseId": .string("exercise-2")]))
    }
    func testExerciseAdvanceAndSetCreationPreserveOpaqueResponses() async throws {
        let paths = [
            "/api/v1/workouts/workout-1/current-exercise": (
                200,
                [
                    "workoutId": "workout-1",
                    "currentExercise": ["exerciseId": "exercise-2"],
                    "nextExercise": ["exerciseId": "exercise-3"],
                    "status": "IN_PROGRESS"
                ] as [String: Any]
            ),
            "/api/v1/workouts/workout-1/sets": (
                201,
                [
                    "setId": "set-1",
                    "workoutId": "workout-1",
                    "exerciseId": "exercise-1",
                    "setIndex": 1,
                    "pr": false,
                    "nextAction": ["type": "REST"],
                    "rest": ["durationSeconds": 60]
                ] as [String: Any]
            )
        ]
        var requests: [URLRequest] = []
        installJSONResponses(paths, recordRequest: { requests.append($0) })
        let service = try WorkoutSessionAPIService(client: makeClient(token: "test-token"))

        let advanced = try await service.advanceExercise(
            workoutId: "workout-1",
            request: AdvanceWorkoutExerciseRequest(completedExerciseId: "exercise-1")
        )
        let setRequest = CreateWorkoutSetRequest(
            exerciseId: "exercise-1",
            setIndex: 1,
            weight: 40,
            reps: 8,
            completedAt: "2026-10-31T09:00:00Z"
        )
        let createdSet = try await service.createSet(
            workoutId: "workout-1",
            request: setRequest,
            idempotencyKey: "set-request-1"
        )
        XCTAssertEqual(requests[1].value(forHTTPHeaderField: "Idempotency-Key"), "set-request-1")
        XCTAssertEqual(advanced.currentExercise, .object(["exerciseId": .string("exercise-2")]))
        XCTAssertFalse(createdSet.isPersonalRecord)
        XCTAssertEqual(createdSet.nextAction, .object(["type": .string("REST")]))
        XCTAssertEqual(createdSet.rest, .object(["durationSeconds": .integer(60)]))
    }
    func testWorkoutStartUsesCreatedStatusAndOpaqueSnapshot() async throws {
        installJSONResponse(
            [
                "workoutId": "workout-1",
                "status": "IN_PROGRESS",
                "routineSnapshot": ["routineId": "routine-1"],
                "currentExercise": ["exerciseId": "exercise-1"],
                "startedAt": "2026-10-31T09:00:00Z"
            ],
            statusCode: 201
        )

        let request = StartWorkoutRequest(
            routineId: "routine-1",
            startedAt: "2026-10-31T09:00:00Z",
            timezone: "Asia/Seoul"
        )
        let service = try WorkoutSessionAPIService(client: makeClient(token: "test-token"))
        let response = try await service.startWorkout(request: request)

        XCTAssertEqual(response.status, .inProgress)
        XCTAssertEqual(response.routineSnapshot, .object(["routineId": .string("routine-1")]))
    }
}
