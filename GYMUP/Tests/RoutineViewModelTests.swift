import XCTest
@testable import GYMUP

final class RoutineViewModelTests: XCTestCase {
    @MainActor
    func testRecommendationFilterAndReturnToMyRoutines() {
        let store = RoutineStore()
        let viewModel = RoutineViewModel(store: store)
        viewModel.mode = .recommended
        XCTAssertFalse(viewModel.routines.isEmpty)
        XCTAssertTrue(viewModel.routines.allSatisfy(\.isRecommended))
        XCTAssertFalse(viewModel.routines.contains(where: \.isEmpty))
        viewModel.mode = .mine
        XCTAssertEqual(viewModel.routines, store.routines)
        XCTAssertTrue(viewModel.routines.contains(where: \.isEmpty))
    }

    @MainActor
    func testServerWorkoutUsesCreatedRoutineIDAndKeepsReturnedWorkoutID() async throws {
        let store = RoutineStore()
        let creator = RoutineCreatorStub(serverRoutineID: "server-routine-1")
        let starter = WorkoutStarterStub(
            serverWorkoutID: "server-workout-1",
            failsFirstRequest: false
        )
        let viewModel = RoutineViewModel(
            store: store,
            routineCreator: creator,
            workoutStarter: starter
        )
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)

        let result = await viewModel.startServerWorkout(
            for: "upper-a",
            at: startedAt,
            timeZone: try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        )

        XCTAssertEqual(result, .started(serverWorkoutID: "server-workout-1", startedAt: startedAt))
        XCTAssertEqual(store.routine(id: "upper-a")?.serverRoutineId, "server-routine-1")
        let createRequests = await creator.recordedRequests()
        let startRequests = await starter.recordedRequests()
        XCTAssertEqual(createRequests.count, 1)
        XCTAssertEqual(startRequests.count, 1)
        XCTAssertEqual(startRequests.first?.routineId, "server-routine-1")
        XCTAssertEqual(startRequests.first?.timezone, "Asia/Seoul")
        XCTAssertEqual(startRequests.first?.startedAt, "2027-01-15T08:00:00.000Z")
    }

    @MainActor
    func testWorkoutRetryReusesPersistedRoutineIDAndShowsServerMessage() async {
        let store = RoutineStore()
        let creator = RoutineCreatorStub(serverRoutineID: "server-routine-1")
        let starter = WorkoutStarterStub(
            serverWorkoutID: "server-workout-1",
            failsFirstRequest: true
        )
        let viewModel = RoutineViewModel(
            store: store,
            routineCreator: creator,
            workoutStarter: starter
        )

        let firstResult = await viewModel.startServerWorkout(for: "upper-a")
        XCTAssertEqual(firstResult, .workoutStartFailed(message: "세션을 시작하지 못했어요."))
        XCTAssertEqual(store.routine(id: "upper-a")?.serverRoutineId, "server-routine-1")

        let retryResult = await viewModel.startServerWorkout(for: "upper-a")

        guard case .started(serverWorkoutID: "server-workout-1", _) = retryResult else {
            return XCTFail("Expected the retry to start the server workout.")
        }
        let createRequests = await creator.recordedRequests()
        let startRequests = await starter.recordedRequests()
        XCTAssertEqual(createRequests.count, 1)
        XCTAssertEqual(startRequests.map(\.routineId), ["server-routine-1", "server-routine-1"])
    }
}

private actor RoutineCreatorStub: RoutineCreating {
    private let serverRoutineID: String
    private var requests: [CreateRoutineRequest] = []

    init(serverRoutineID: String) {
        self.serverRoutineID = serverRoutineID
    }

    func createRoutine(_ request: CreateRoutineRequest) async throws -> CreateRoutineResponse {
        requests.append(request)
        let exercises = request.exercises.map {
            CreatedRoutineExerciseResponse(
                exerciseId: $0.exerciseId,
                sets: $0.sets,
                reps: $0.reps,
                weight: $0.weight,
                restSeconds: $0.restSeconds,
                order: $0.order
            )
        }
        return CreateRoutineResponse(
            routineId: serverRoutineID,
            name: request.name,
            exercises: exercises,
            createdAt: "2026-11-05T00:00:00Z"
        )
    }

    func recordedRequests() -> [CreateRoutineRequest] { requests }
}

private actor WorkoutStarterStub: WorkoutStarting {
    private let serverWorkoutID: String
    private let failsFirstRequest: Bool
    private var requests: [StartWorkoutRequest] = []

    init(serverWorkoutID: String, failsFirstRequest: Bool) {
        self.serverWorkoutID = serverWorkoutID
        self.failsFirstRequest = failsFirstRequest
    }

    func startWorkout(request: StartWorkoutRequest) async throws -> StartWorkoutResponse {
        requests.append(request)
        if failsFirstRequest && requests.count == 1 {
            throw APIClientError.server(
                statusCode: 409,
                detail: ServerErrorDetail(code: "ACTIVE_WORKOUT_EXISTS", message: "세션을 시작하지 못했어요.")
            )
        }
        return StartWorkoutResponse(
            workoutId: serverWorkoutID,
            status: .inProgress,
            routineSnapshot: .object(["routineId": .string(request.routineId)]),
            currentExercise: .object(["exerciseId": .string("bench")]),
            startedAt: request.startedAt
        )
    }

    func recordedRequests() -> [StartWorkoutRequest] { requests }
}
