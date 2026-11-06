import XCTest
@testable import GYMUP

final class WorkoutSessionServerRestTests: XCTestCase {
    @MainActor
    func testRecordedSetStartsServerRestAndUsesServerDeadline() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        let viewModel = makeViewModel(service: service, start: start)

        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)

        XCTAssertTrue(didComplete)
        XCTAssertTrue(try XCTUnwrap(viewModel.currentExercise?.sets.first).isCompleted)
        XCTAssertEqual(service.setRequests.count, 1)
        XCTAssertEqual(service.restRequests.count, 1)
        XCTAssertEqual(service.restRequests[0].request, StartRestRequest(setId: "set-1", durationSeconds: 75))
        XCTAssertEqual(viewModel.activeRestEndsAt, start.addingTimeInterval(75))
        XCTAssertTrue(viewModel.isServerManagedRest)
        XCTAssertNil(viewModel.pendingRestStart)
    }

    @MainActor
    func testNextSetPreviewUsesValidatedServerValuesAndKeepsLocalPlanUnchanged() async throws {
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
    func testNextSetPreviewFailureKeepsLocalFallbackAndRetryLoadsServerValues() async throws {
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

        service.nextSetResponse = NextWorkoutSetResponse(
            exerciseId: "exercise-1",
            exerciseName: "Bench Press",
            setIndex: 2,
            weight: 47.5,
            reps: 6,
            restEndsAt: ""
        )
        await viewModel.loadNextSetPreview()

        XCTAssertEqual(service.nextSetRequests, ["workout-1", "workout-1"])
        XCTAssertEqual(viewModel.nextSetPreview?.weight, 47.5)
        XCTAssertNil(viewModel.nextSetPreviewError)
    }

    @MainActor
    func testNextSetPreviewRejectsExerciseOrSetIndexMismatch() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        service.nextSetResponse = NextWorkoutSetResponse(
            exerciseId: "exercise-1",
            exerciseName: "Bench Press",
            setIndex: 3,
            weight: 47.5,
            reps: 6,
            restEndsAt: ""
        )
        let viewModel = makeViewModel(service: service, start: start)
        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(didComplete)

        await viewModel.loadNextSetPreview()

        XCTAssertNil(viewModel.nextSetPreview)
        XCTAssertEqual(viewModel.nextSetPreviewError, "다음 세트 정보를 불러오지 못했어요.")
        XCTAssertEqual(viewModel.currentSetIndex, 1)

        service.nextSetResponse = NextWorkoutSetResponse(
            exerciseId: "exercise-2",
            exerciseName: "Row",
            setIndex: 2,
            weight: 30,
            reps: 10,
            restEndsAt: ""
        )
        await viewModel.loadNextSetPreview()

        XCTAssertNil(viewModel.nextSetPreview)
        XCTAssertEqual(viewModel.nextSetPreviewError, "다음 세트 정보를 불러오지 못했어요.")
        XCTAssertEqual(service.nextSetRequests.count, 2)
    }

    @MainActor
    func testFailedRestStartKeepsSavedSetAndRetryAdoptsCurrentServerRest() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        service.nextRestStartError = serverError(message: "휴식 생성 오류")
        service.restStartCommitsBeforeThrow = true
        let viewModel = makeViewModel(service: service, start: start)

        let firstAttempt = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)

        XCTAssertFalse(firstAttempt)
        XCTAssertTrue(try XCTUnwrap(viewModel.currentExercise?.sets.first).isCompleted)
        XCTAssertFalse(viewModel.hasPendingServerSetSubmission)
        XCTAssertEqual(viewModel.serverActionErrorMessage, "휴식 생성 오류")
        XCTAssertFalse(viewModel.isResting)
        XCTAssertNotNil(viewModel.pendingRestStart)
        XCTAssertEqual(service.setRequests.count, 1)
        XCTAssertEqual(service.restRequests.count, 1)

        let didRetry = await viewModel.retryFailedServerAction()

        XCTAssertTrue(didRetry)
        XCTAssertEqual(service.currentRestRequests, ["workout-1"])
        XCTAssertEqual(service.restRequests.count, 1)
        XCTAssertEqual(service.setRequests.count, 1)
        XCTAssertTrue(viewModel.isResting)
        XCTAssertTrue(viewModel.isServerManagedRest)
        XCTAssertNil(viewModel.pendingRestStart)
        XCTAssertNil(viewModel.serverActionErrorMessage)
    }

    @MainActor
    func testRetryAfterCurrentRestAlreadyEndedDoesNotCreateAnotherRest() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        service.nextRestStartError = serverError(message: "응답을 받지 못했어요.")
        service.currentRestResponse = CurrentRestResponse(
            restId: "rest-1",
            status: "COMPLETED",
            startedAt: serverDate(start),
            endsAt: serverDate(start.addingTimeInterval(75)),
            remainingSeconds: 0,
            notificationAt: serverDate(start.addingTimeInterval(65))
        )
        let viewModel = makeViewModel(service: service, start: start)

        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertFalse(didComplete)

        let didRetry = await viewModel.retryFailedServerAction()

        XCTAssertTrue(didRetry)
        XCTAssertEqual(service.setRequests.count, 1)
        XCTAssertEqual(service.currentRestRequests.count, 1)
        XCTAssertEqual(service.restRequests.count, 1)
        XCTAssertNil(viewModel.pendingRestStart)
        XCTAssertFalse(viewModel.isResting)
    }

    @MainActor
    func testRetryAfterUnresolvedLookupRetriesRestOnlyWithSameRequest() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        let requestError = serverError(message: "첫 번째 휴식 요청 실패")
        service.nextRestStartError = requestError
        service.nextCurrentRestError = serverError(statusCode: 404, message: "휴식 상태 조회 실패")
        let viewModel = makeViewModel(service: service, start: start)

        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertFalse(didComplete)
        let originalRequest = try XCTUnwrap(viewModel.pendingRestStart?.request)

        let didRetry = await viewModel.retryFailedServerAction()

        XCTAssertTrue(didRetry)
        XCTAssertEqual(service.setRequests.count, 1)
        XCTAssertEqual(service.currentRestRequests.count, 1)
        XCTAssertEqual(service.restRequests.count, 2)
        XCTAssertEqual(service.restRequests[0].request, originalRequest)
        XCTAssertEqual(service.restRequests[1].request, originalRequest)
        XCTAssertTrue(viewModel.isResting)
    }

    @MainActor
    func testSkippingFailedRestStartKeepsSavedSetAndAllowsNextSet() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        service.nextRestStartError = serverError(message: "휴식 생성 오류")
        let viewModel = makeViewModel(service: service, start: start)

        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertFalse(didComplete)
        XCTAssertTrue(viewModel.skipPendingRestStart())
        XCTAssertTrue(viewModel.plan.exercises[0].sets[0].isCompleted)
        XCTAssertNil(viewModel.pendingRestStart)
        XCTAssertFalse(viewModel.isResting)

        let didCompleteNextSet = await viewModel.completeSet(exerciseIndex: 0, setIndex: 1, at: start.addingTimeInterval(90))

        XCTAssertTrue(didCompleteNextSet)
        XCTAssertEqual(service.setRequests.count, 2)
        XCTAssertEqual(service.restRequests.count, 1)
    }

    @MainActor
    func testFailedServerRestSkipLeavesTimerUntilRetrySucceeds() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        let viewModel = makeViewModel(service: service, start: start)
        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(didComplete)
        let originalEnd = try XCTUnwrap(viewModel.activeRestEndsAt)
        service.nextSkipError = serverError(message: "건너뛰기 실패")

        let didSkipFirstTry = await viewModel.requestServerRestSkip()

        XCTAssertFalse(didSkipFirstTry)
        XCTAssertEqual(viewModel.activeRestEndsAt, originalEnd)
        XCTAssertTrue(viewModel.isResting)
        XCTAssertEqual(viewModel.serverActionErrorMessage, "건너뛰기 실패")

        let didRetry = await viewModel.retryFailedServerAction()

        XCTAssertTrue(didRetry)
        XCTAssertEqual(service.skipRequests, ["workout-1", "workout-1"])
        XCTAssertFalse(viewModel.isResting)
        XCTAssertFalse(viewModel.isServerManagedRest)
    }

    @MainActor
    func testFailedServerRestExtensionLeavesTimerUntilRetrySucceeds() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        let viewModel = makeViewModel(service: service, start: start)
        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(didComplete)
        let originalEnd = try XCTUnwrap(viewModel.activeRestEndsAt)
        service.nextExtendError = serverError(message: "연장 실패")

        let didExtendFirstTry = await viewModel.requestServerRestExtension(by: 15)

        XCTAssertFalse(didExtendFirstTry)
        XCTAssertEqual(viewModel.activeRestEndsAt, originalEnd)
        XCTAssertEqual(viewModel.activeRestDurationSeconds, 75)
        XCTAssertEqual(viewModel.serverActionErrorMessage, "연장 실패")

        service.nextExtendResponse = ExtendCurrentRestResponse(
            restId: "rest-1",
            endsAt: serverDate(start.addingTimeInterval(90)),
            remainingSeconds: 90
        )
        let didRetry = await viewModel.retryFailedServerAction()

        XCTAssertTrue(didRetry)
        XCTAssertEqual(service.extendRequests.count, 2)
        XCTAssertEqual(service.extendRequests[0].0, "workout-1")
        XCTAssertEqual(service.extendRequests[0].1, 15)
        XCTAssertEqual(service.extendRequests[1].0, "workout-1")
        XCTAssertEqual(service.extendRequests[1].1, 15)
        XCTAssertEqual(viewModel.activeRestEndsAt, start.addingTimeInterval(90))
        XCTAssertEqual(viewModel.activeRestDurationSeconds, 90)
    }

    @MainActor
    func testForegroundRefreshUsesCurrentServerRestAndSkipsLookupWhenNotResting() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        let viewModel = makeViewModel(service: service, start: start)
        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(didComplete)
        service.currentRestResponse = CurrentRestResponse(
            restId: "rest-1",
            status: "ACTIVE",
            startedAt: serverDate(start),
            endsAt: serverDate(start.addingTimeInterval(50)),
            remainingSeconds: 50,
            notificationAt: serverDate(start.addingTimeInterval(45))
        )

        let didRefresh = await viewModel.refreshActiveServerRest(at: start)

        XCTAssertTrue(didRefresh)
        XCTAssertEqual(viewModel.activeRestEndsAt, start.addingTimeInterval(50))
        XCTAssertEqual(viewModel.activeRestDurationSeconds, 50)
        XCTAssertEqual(service.currentRestRequests.count, 1)

        viewModel.skipRest()
        let didRefreshWhenIdle = await viewModel.refreshActiveServerRest(at: start)
        XCTAssertTrue(didRefreshWhenIdle)
        XCTAssertEqual(service.currentRestRequests.count, 1)
    }

    @MainActor
    func testTimedSetUsesLocalRestWithoutCallingRestAPI() async throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let service = MockWorkoutSessionRestService(startDate: start)
        let viewModel = makeViewModel(service: service, start: start, measure: .seconds)

        let didComplete = await viewModel.completeSet(exerciseIndex: 0, setIndex: 0, at: start)

        XCTAssertTrue(didComplete)
        XCTAssertTrue(viewModel.isResting)
        XCTAssertFalse(viewModel.isServerManagedRest)
        XCTAssertTrue(service.setRequests.isEmpty)
        XCTAssertTrue(service.restRequests.isEmpty)

        await viewModel.loadNextSetPreview()

        XCTAssertTrue(service.nextSetRequests.isEmpty)
        XCTAssertNil(viewModel.nextSetPreviewError)
    }

    @MainActor
    private func makeViewModel(
        service: MockWorkoutSessionRestService,
        start: Date,
        measure: RoutineExerciseMeasure = .repetitions
    ) -> WorkoutSessionViewModel {
        let sets = [
            WorkoutSessionSet(weightKilograms: 40, repetitions: 8),
            WorkoutSessionSet(weightKilograms: 42.5, repetitions: 8)
        ]
        let exercises = [
            WorkoutSessionExercise(
                id: "exercise-1",
                name: "벤치 프레스",
                target: "가슴",
                restDurationSeconds: 75,
                formSteps: [],
                beginnerTip: "",
                sets: sets,
                measure: measure
            ),
            WorkoutSessionExercise(
                id: "exercise-2",
                name: "로우",
                target: "등",
                restDurationSeconds: 60,
                formSteps: [],
                beginnerTip: "",
                sets: [WorkoutSessionSet(weightKilograms: 30, repetitions: 10)]
            )
        ]
        let plan = WorkoutSessionPlan(
            id: "routine-1",
            name: "루틴",
            title: "루틴",
            estimatedDurationMinutes: 20,
            exercises: exercises
        )
        return WorkoutSessionViewModel(
            plan: plan,
            startedAt: start,
            serverWorkoutID: "workout-1",
            progressService: service,
            nextSetService: service
        )
    }

    private func serverError(statusCode: Int = 503, message: String) -> APIClientError {
        .server(statusCode: statusCode, detail: ServerErrorDetail(code: "TEMPORARY_FAILURE", message: message))
    }

    private func serverDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
