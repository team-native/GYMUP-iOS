import XCTest
@testable import GYMUP

final class WorkoutSessionServerProgressTests: XCTestCase {
    @MainActor
    func testServerSetFailurePreservesCompletionAndRetryReusesRequestAndIdempotencyKey() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionProgressService()
        service.nextSetError = APIClientError.server(
            statusCode: 503,
            detail: ServerErrorDetail(code: "TEMPORARY_FAILURE", message: "서버에서 받은 오류")
        )
        let viewModel = WorkoutSessionViewModel(
            plan: serverBackedPlan(),
            startedAt: start,
            serverWorkoutID: "workout-1",
            progressService: service
        )

        let firstAttempt = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)

        XCTAssertFalse(firstAttempt)
        XCTAssertFalse(try XCTUnwrap(viewModel.currentExercise?.sets.first).isCompleted)
        XCTAssertTrue(viewModel.hasPendingServerSetSubmission)
        XCTAssertEqual(viewModel.serverActionErrorMessage, "서버에서 받은 오류")

        let retry = await viewModel.retryFailedServerAction()

        XCTAssertTrue(retry)
        XCTAssertTrue(try XCTUnwrap(viewModel.currentExercise?.sets.first).isCompleted)
        XCTAssertFalse(viewModel.hasPendingServerSetSubmission)
        XCTAssertEqual(service.setRequests.count, 2)
        XCTAssertEqual(service.setRequests[0].workoutID, "workout-1")
        XCTAssertEqual(service.setRequests[1].workoutID, "workout-1")
        XCTAssertEqual(service.setRequests[0].request, service.setRequests[1].request)
        XCTAssertEqual(service.setRequests[0].idempotencyKey, service.setRequests[1].idempotencyKey)
        XCTAssertEqual(service.setRequests[0].request.exerciseId, "exercise-1")
        XCTAssertEqual(service.setRequests[0].request.setIndex, 1)
        XCTAssertEqual(service.setRequests[0].request.weight, 40)
        XCTAssertEqual(service.setRequests[0].request.reps, 8)
        XCTAssertEqual(service.setRequests[0].request.completedAt, ISO8601DateFormatter().string(from: start))
    }

    @MainActor
    func testServerExerciseAdvanceFailureKeepsCurrentExerciseAndServerMessage() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionProgressService()
        service.nextAdvanceError = APIClientError.server(
            statusCode: 409,
            detail: ServerErrorDetail(code: "SETS_INCOMPLETE", message: "서버의 세트 검증 메시지")
        )
        let viewModel = WorkoutSessionViewModel(
            plan: serverBackedPlan(firstSetCompleted: true),
            startedAt: start,
            serverWorkoutID: "workout-1",
            progressService: service
        )

        let didAdvance = await viewModel.advanceToNextExercise()

        XCTAssertFalse(didAdvance)
        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
        XCTAssertEqual(viewModel.serverActionErrorMessage, "서버의 세트 검증 메시지")
        XCTAssertEqual(service.advanceRequests.count, 1)
        XCTAssertEqual(service.advanceRequests[0].workoutID, "workout-1")
        XCTAssertEqual(service.advanceRequests[0].request.completedExerciseId, "exercise-1")
    }

    @MainActor
    func testTimedServerSetSkipsSetEndpointAndDoesNotAdvanceWhenServerRejectsExerciseMove() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionProgressService()
        service.nextAdvanceError = APIClientError.server(
            statusCode: 409,
            detail: ServerErrorDetail(
                code: "SETS_INCOMPLETE",
                message: "운동의 세트가 아직 완료되지 않았어요."
            )
        )
        let viewModel = WorkoutSessionViewModel(
            plan: serverBackedPlan(measure: .seconds),
            startedAt: start,
            serverWorkoutID: "workout-1",
            progressService: service
        )

        let didCompleteTimedSet = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(didCompleteTimedSet)
        XCTAssertTrue(try XCTUnwrap(viewModel.currentExercise?.sets.first).isCompleted)
        XCTAssertTrue(service.setRequests.isEmpty)

        let didAdvance = await viewModel.advanceToNextExercise()
        XCTAssertFalse(didAdvance)
        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
        XCTAssertEqual(viewModel.serverActionErrorMessage, "운동의 세트가 아직 완료되지 않았어요.")
    }

    @MainActor
    func testServerBackedCompletedSetCannotBeLocallyUndone() throws {
        let viewModel = WorkoutSessionViewModel(
            plan: serverBackedPlan(firstSetCompleted: true),
            serverWorkoutID: "workout-1"
        )

        viewModel.toggleSetCompletion(exerciseIndex: 0, setIndex: 0)

        XCTAssertTrue(try XCTUnwrap(viewModel.currentExercise?.sets.first).isCompleted)
    }

    private func serverBackedPlan(
        measure: RoutineExerciseMeasure = .repetitions,
        firstSetCompleted: Bool = false
    ) -> WorkoutSessionPlan {
        let exercises = [
            WorkoutSessionExercise(
                id: "exercise-1",
                name: "첫 번째 운동",
                target: "가슴",
                restDurationSeconds: 60,
                formSteps: [],
                beginnerTip: "",
                sets: [WorkoutSessionSet(weightKilograms: 40, repetitions: 8, isCompleted: firstSetCompleted)],
                measure: measure
            ),
            WorkoutSessionExercise(
                id: "exercise-2",
                name: "두 번째 운동",
                target: "등",
                restDurationSeconds: 60,
                formSteps: [],
                beginnerTip: "",
                sets: [WorkoutSessionSet(weightKilograms: 30, repetitions: 10)]
            )
        ]
        return WorkoutSessionPlan(
            id: "routine-1",
            name: "루틴",
            title: "루틴",
            estimatedDurationMinutes: 20,
            exercises: exercises
        )
    }
}

private final class MockWorkoutSessionProgressService: WorkoutSessionProgressing {
    struct SetRequest {
        let workoutID: String
        let request: CreateWorkoutSetRequest
        let idempotencyKey: String?
    }

    struct AdvanceRequest {
        let workoutID: String
        let request: AdvanceWorkoutExerciseRequest
    }

    var setRequests: [SetRequest] = []
    var advanceRequests: [AdvanceRequest] = []
    var nextSetError: Error?
    var nextAdvanceError: Error?

    func createSet(
        workoutId: String,
        request: CreateWorkoutSetRequest,
        idempotencyKey: String?
    ) async throws -> CreateWorkoutSetResponse {
        setRequests.append(.init(workoutID: workoutId, request: request, idempotencyKey: idempotencyKey))
        if let error = nextSetError {
            nextSetError = nil
            throw error
        }
        return CreateWorkoutSetResponse(
            setId: "set-1",
            workoutId: workoutId,
            exerciseId: request.exerciseId,
            setIndex: request.setIndex,
            isPersonalRecord: false,
            nextAction: .object([:]),
            rest: .object([:])
        )
    }

    func advanceExercise(
        workoutId: String,
        request: AdvanceWorkoutExerciseRequest
    ) async throws -> AdvanceWorkoutExerciseResponse {
        advanceRequests.append(.init(workoutID: workoutId, request: request))
        if let error = nextAdvanceError {
            nextAdvanceError = nil
            throw error
        }
        return AdvanceWorkoutExerciseResponse(
            workoutId: workoutId,
            currentExercise: .object([:]),
            nextExercise: .object([:]),
            status: "IN_PROGRESS"
        )
    }
}
