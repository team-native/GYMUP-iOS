import XCTest
@testable import GYMUP

final class WorkoutSessionNextSetPreviewTests: XCTestCase {
    @MainActor
    func testPreviewUsesValidatedServerValuesAndKeepsLocalPlanUnchanged() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        service.nextSetResponse = NextWorkoutSetResponse(
            exerciseId: "exercise-1",
            exerciseName: "Bench Press",
            setIndex: 2,
            weight: 47.5,
            reps: 6,
            restEndsAt: "not-used-by-preview"
        )
        let viewModel = makeViewModel(service: service, start: start)
        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(didComplete)

        await viewModel.loadNextSetPreview()

        XCTAssertEqual(service.nextSetRequests, ["workout-1"])
        XCTAssertEqual(viewModel.nextSetPreview?.exerciseName, "Bench Press")
        XCTAssertEqual(viewModel.nextSetPreview?.setIndex, 2)
        XCTAssertEqual(viewModel.nextSetPreview?.weight, 47.5)
        XCTAssertEqual(viewModel.nextSetPreview?.reps, 6)
        XCTAssertNil(viewModel.nextSetPreviewError)
        XCTAssertEqual(viewModel.currentExercise?.sets[1].weightKilograms, 42.5)
        XCTAssertEqual(viewModel.currentExercise?.sets[1].repetitions, 8)
        XCTAssertEqual(viewModel.currentSetIndex, 1)
    }

    @MainActor
    func testPreviewFailureKeepsLocalFallbackAndRetryLoadsServerValues() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        service.nextSetError = serverError(message: "서버 미리보기 오류")
        let viewModel = makeViewModel(service: service, start: start)
        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(didComplete)

        await viewModel.loadNextSetPreview()

        XCTAssertNil(viewModel.nextSetPreview)
        XCTAssertEqual(viewModel.nextSetPreviewError, "서버 미리보기 오류")
        XCTAssertEqual(viewModel.currentExercise?.sets[1].weightKilograms, 42.5)
        XCTAssertEqual(viewModel.currentExercise?.sets[1].repetitions, 8)

        service.nextSetResponse = nextSetResponse()
        await viewModel.loadNextSetPreview()

        XCTAssertEqual(service.nextSetRequests, ["workout-1", "workout-1"])
        XCTAssertEqual(viewModel.nextSetPreview?.weight, 47.5)
        XCTAssertNil(viewModel.nextSetPreviewError)
    }

    @MainActor
    func testPreviewRejectsExerciseOrSetIndexMismatch() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        service.nextSetResponse = nextSetResponse(setIndex: 3)
        let viewModel = makeViewModel(service: service, start: start)
        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(didComplete)

        await viewModel.loadNextSetPreview()

        XCTAssertNil(viewModel.nextSetPreview)
        XCTAssertEqual(viewModel.nextSetPreviewError, "다음 세트 정보를 불러오지 못했어요.")
        XCTAssertEqual(viewModel.currentSetIndex, 1)

        service.nextSetResponse = nextSetResponse(exerciseID: "exercise-2")
        await viewModel.loadNextSetPreview()

        XCTAssertNil(viewModel.nextSetPreview)
        XCTAssertEqual(viewModel.nextSetPreviewError, "다음 세트 정보를 불러오지 못했어요.")
        XCTAssertEqual(service.nextSetRequests.count, 2)
    }

    @MainActor
    private func makeViewModel(
        service: MockWorkoutSessionRestService,
        start: Date
    ) -> WorkoutSessionViewModel {
        let currentExercise = WorkoutSessionExercise(
            id: "exercise-1",
            name: "벤치 프레스",
            target: "가슴",
            restDurationSeconds: 75,
            formSteps: [],
            beginnerTip: "",
            sets: [
                WorkoutSessionSet(weightKilograms: 40, repetitions: 8),
                WorkoutSessionSet(weightKilograms: 42.5, repetitions: 8)
            ]
        )
        let nextExercise = WorkoutSessionExercise(
            id: "exercise-2",
            name: "로우",
            target: "등",
            restDurationSeconds: 60,
            formSteps: [],
            beginnerTip: "",
            sets: [WorkoutSessionSet(weightKilograms: 30, repetitions: 10)]
        )
        let plan = WorkoutSessionPlan(
            id: "routine-1",
            name: "루틴",
            title: "루틴",
            estimatedDurationMinutes: 20,
            exercises: [currentExercise, nextExercise]
        )
        return WorkoutSessionViewModel(
            plan: plan,
            startedAt: start,
            serverWorkoutID: "workout-1",
            progressService: service,
            nextSetService: service
        )
    }

    private func nextSetResponse(
        exerciseID: String = "exercise-1",
        setIndex: Int = 2
    ) -> NextWorkoutSetResponse {
        NextWorkoutSetResponse(
            exerciseId: exerciseID,
            exerciseName: "Bench Press",
            setIndex: setIndex,
            weight: 47.5,
            reps: 6,
            restEndsAt: ""
        )
    }

    private func serverError(message: String) -> APIClientError {
        .server(
            statusCode: 503,
            detail: ServerErrorDetail(code: "TEMPORARY_FAILURE", message: message)
        )
    }
}
