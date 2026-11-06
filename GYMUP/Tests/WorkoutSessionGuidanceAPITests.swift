import XCTest
@testable import GYMUP

final class WorkoutSessionGuidanceAPITests: XCTestCase {
    @MainActor
    func testFirstTimeStatusShowsPromptForFirstTimeExercise() async throws {
        let service = MockExerciseGuidanceService()
        service.firstTimeStatusResponse = firstTimeStatus(exerciseID: "bench-press", isFirstTime: true)
        let viewModel = makeViewModel(service: service)
        let exercise = try XCTUnwrap(viewModel.plan.exercises.first)

        XCTAssertTrue(exercise.hasPreviousPerformance)
        await viewModel.loadFirstTimeStatus(for: exercise.id)

        XCTAssertEqual(service.firstTimeStatusRequests, [exercise.id])
        XCTAssertTrue(viewModel.shouldShowFirstExercisePrompt(for: exercise))
    }

    @MainActor
    func testNonFirstTimeStatusHidesPromptDespiteMissingLocalRecord() async throws {
        let service = MockExerciseGuidanceService()
        service.firstTimeStatusResponse = firstTimeStatus(exerciseID: "incline-press", isFirstTime: false)
        let viewModel = makeViewModel(service: service)
        let exercise = try XCTUnwrap(viewModel.plan.exercises.dropFirst().first)

        XCTAssertFalse(exercise.hasPreviousPerformance)
        await viewModel.loadFirstTimeStatus(for: exercise.id)

        XCTAssertFalse(viewModel.shouldShowFirstExercisePrompt(for: exercise))
        XCTAssertNil(viewModel.firstTimeStatusErrors[exercise.id])
    }

    @MainActor
    func testPromptIsHiddenWhenGuideIsUnavailable() async throws {
        let service = MockExerciseGuidanceService()
        service.firstTimeStatusResponse = firstTimeStatus(
            exerciseID: "incline-press",
            isFirstTime: true,
            guideAvailable: false
        )
        let viewModel = makeViewModel(service: service)
        let exercise = try XCTUnwrap(viewModel.plan.exercises.dropFirst().first)

        await viewModel.loadFirstTimeStatus(for: exercise.id)

        XCTAssertFalse(viewModel.shouldShowFirstExercisePrompt(for: exercise))
    }

    @MainActor
    func testFirstTimeStatusErrorFallsBackToLocalHistory() async throws {
        let service = MockExerciseGuidanceService()
        service.firstTimeStatusError = serverError(message: "상태 조회 실패")
        let viewModel = makeViewModel(service: service)
        let exercise = try XCTUnwrap(viewModel.plan.exercises.dropFirst().first)

        await viewModel.loadFirstTimeStatus(for: exercise.id)

        XCTAssertNil(viewModel.firstTimeStatuses[exercise.id])
        XCTAssertEqual(viewModel.firstTimeStatusErrors[exercise.id], "상태 조회 실패")
        XCTAssertTrue(viewModel.shouldShowFirstExercisePrompt(for: exercise))
    }

    @MainActor
    func testGuideResponseProvidesServerContent() async throws {
        let service = MockExerciseGuidanceService()
        service.guideResponse = guide(exerciseID: "bench-press")
        let viewModel = makeViewModel(service: service)

        await viewModel.loadExerciseGuide(for: "bench-press")

        XCTAssertEqual(service.guideRequests, ["bench-press"])
        XCTAssertEqual(viewModel.exerciseGuide(for: "bench-press")?.targetMuscles, ["chest"])
        XCTAssertEqual(viewModel.exerciseGuide(for: "bench-press")?.keyPoints, ["brace"])
        XCTAssertEqual(viewModel.exerciseGuide(for: "bench-press")?.commonMistakes, ["bounce"])
        XCTAssertNil(viewModel.exerciseGuideError(for: "bench-press"))
    }

    @MainActor
    func testGuideErrorKeepsLocalGuideAvailableAndRetryLoadsServerGuide() async throws {
        let service = MockExerciseGuidanceService()
        service.nextGuideError = serverError(message: "가이드 조회 실패")
        let viewModel = makeViewModel(service: service)

        await viewModel.loadExerciseGuide(for: "bench-press")

        XCTAssertNil(viewModel.exerciseGuide(for: "bench-press"))
        XCTAssertEqual(viewModel.exerciseGuideError(for: "bench-press"), "가이드 조회 실패")
        XCTAssertFalse(try XCTUnwrap(viewModel.plan.exercises.first).formSteps.isEmpty)

        service.guideResponse = guide(exerciseID: "bench-press")
        await viewModel.loadExerciseGuide(for: "bench-press")

        XCTAssertEqual(viewModel.exerciseGuide(for: "bench-press")?.keyPoints, ["brace"])
        XCTAssertNil(viewModel.exerciseGuideError(for: "bench-press"))
        XCTAssertEqual(service.guideRequests, ["bench-press", "bench-press"])
    }

    @MainActor
    func testGuideResponseWithDifferentExerciseIDIsRejected() async {
        let service = MockExerciseGuidanceService()
        service.guideResponse = guide(exerciseID: "incline-press")
        let viewModel = makeViewModel(service: service)

        await viewModel.loadExerciseGuide(for: "bench-press")

        XCTAssertNil(viewModel.exerciseGuide(for: "bench-press"))
        XCTAssertEqual(viewModel.exerciseGuideError(for: "bench-press"), "자세 가이드를 불러오지 못했어요.")
    }

    @MainActor
    private func makeViewModel(service: MockExerciseGuidanceService) -> WorkoutSessionViewModel {
        WorkoutSessionViewModel(
            routineID: "upper-a",
            goalSettings: nil,
            exerciseGuidanceService: service
        )
    }

    private func firstTimeStatus(
        exerciseID: String,
        isFirstTime: Bool,
        guideAvailable: Bool = true
    ) -> ExerciseFirstTimeStatusResponse {
        ExerciseFirstTimeStatusResponse(
            exerciseId: exerciseID,
            isFirstTime: isFirstTime,
            guideAvailable: guideAvailable
        )
    }

    private func guide(exerciseID: String) -> ExerciseGuideResponse {
        ExerciseGuideResponse(
            exerciseId: exerciseID,
            mediaUrl: "https://cdn.example.test/guide.mp4",
            targetMuscles: ["chest"],
            keyPoints: ["brace"],
            commonMistakes: ["bounce"]
        )
    }

    private func serverError(message: String) -> APIClientError {
        .server(statusCode: 503, detail: ServerErrorDetail(code: "TEMPORARY_FAILURE", message: message))
    }
}

@MainActor
private final class MockExerciseGuidanceService: ExerciseGuidanceReading {
    var firstTimeStatusResponse: ExerciseFirstTimeStatusResponse?
    var guideResponse: ExerciseGuideResponse?
    var firstTimeStatusError: Error?
    var nextGuideError: Error?
    private(set) var firstTimeStatusRequests: [String] = []
    private(set) var guideRequests: [String] = []

    func firstTimeStatus(exerciseId: String) async throws -> ExerciseFirstTimeStatusResponse {
        firstTimeStatusRequests.append(exerciseId)
        if let firstTimeStatusError { throw firstTimeStatusError }
        guard let firstTimeStatusResponse else { throw APIClientError.invalidResponse }
        return firstTimeStatusResponse
    }

    func guide(exerciseId: String) async throws -> ExerciseGuideResponse {
        guideRequests.append(exerciseId)
        if let nextGuideError {
            self.nextGuideError = nil
            throw nextGuideError
        }
        guard let guideResponse else { throw APIClientError.invalidResponse }
        return guideResponse
    }
}
