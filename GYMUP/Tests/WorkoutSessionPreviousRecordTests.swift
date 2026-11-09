import XCTest
@testable import GYMUP

final class WorkoutSessionPreviousRecordTests: XCTestCase {
    @MainActor
    func testSuccessfulResponseUpdatesPreviousRecordAndDisplay() async throws {
        let record = response(hasPreviousRecord: true, weight: 60, reps: 8, setIndex: 3)
        let loader = PreviousRecordLoaderStub(outcomes: [.success(record)])
        let viewModel = makeViewModel(loader: loader)

        await viewModel.loadPreviousRecord(for: "bench-press")

        let exercise = try XCTUnwrap(viewModel.plan.exercises.first { $0.id == "bench-press" })
        XCTAssertFalse(exercise.usesSampleHistory)
        XCTAssertEqual(exercise.previousPerformanceTitle(for: 0), "이전 · 10월 30일 60kg × 8")
        XCTAssertEqual(exercise.previousPerformance(for: 2), "60 × 8")
        XCTAssertNil(exercise.previousPerformance(for: 1))
        XCTAssertNil(viewModel.previousRecordError(for: "bench-press"))
        XCTAssertEqual(loader.requests, ["bench-press"])
    }

    @MainActor
    func testCompleteNoHistoryResponseClearsSampleRecord() async throws {
        let noHistory = response(hasPreviousRecord: false, weight: 0, reps: 0, setIndex: 0)
        let loader = PreviousRecordLoaderStub(outcomes: [.success(noHistory)])
        let viewModel = makeViewModel(loader: loader)

        await viewModel.loadPreviousRecord(for: "bench-press")

        let exercise = try XCTUnwrap(viewModel.plan.exercises.first { $0.id == "bench-press" })
        XCTAssertFalse(exercise.usesSampleHistory)
        XCTAssertNil(exercise.previousRecord)
        XCTAssertEqual(exercise.previousPerformanceTitle(for: 0), "이전 기록 없음")
        XCTAssertNil(exercise.previousPerformance(for: 0))
        XCTAssertFalse(exercise.hasPreviousPerformance)
        XCTAssertNil(viewModel.previousRecordError(for: "bench-press"))
    }

    @MainActor
    func testRequestFailureKeepsSampleDisplayAndSurfacesServerMessage() async throws {
        let serverError = APIClientError.server(
            statusCode: 503,
            detail: ServerErrorDetail(code: "SERVICE_UNAVAILABLE", message: "기록 조회 서버 오류")
        )
        let loader = PreviousRecordLoaderStub(outcomes: [.failure(serverError)])
        let viewModel = makeViewModel(loader: loader)

        await viewModel.loadPreviousRecord(for: "bench-press")

        let exercise = try XCTUnwrap(viewModel.plan.exercises.first { $0.id == "bench-press" })
        XCTAssertTrue(exercise.usesSampleHistory)
        XCTAssertNil(exercise.previousRecord)
        XCTAssertEqual(exercise.previousPerformanceTitle(for: 0), "이전 · 10월 8일 60kg × 8")
        XCTAssertEqual(exercise.previousPerformance(for: 0), "60 × 8")
        XCTAssertEqual(viewModel.previousRecordError(for: "bench-press"), "기록 조회 서버 오류")
        XCTAssertFalse(viewModel.isLoadingPreviousRecord(for: "bench-press"))
    }

    @MainActor
    func testRetrySuccessReplacesSampleAndClearsError() async throws {
        let record = response(hasPreviousRecord: true, weight: 72.5, reps: 6, setIndex: 4)
        let loader = PreviousRecordLoaderStub(outcomes: [
            .failure(.invalidResponse),
            .success(record)
        ])
        let viewModel = makeViewModel(loader: loader)

        await viewModel.loadPreviousRecord(for: "bench-press")
        XCTAssertEqual(viewModel.previousRecordError(for: "bench-press"), "이전 기록을 불러오지 못했어요.")
        XCTAssertEqual(viewModel.currentExercise?.previousPerformanceTitle(for: 0), "이전 · 10월 8일 60kg × 8")

        await viewModel.loadPreviousRecord(for: "bench-press")

        let exercise = try XCTUnwrap(viewModel.plan.exercises.first { $0.id == "bench-press" })
        XCTAssertFalse(exercise.usesSampleHistory)
        XCTAssertEqual(exercise.previousPerformanceTitle(for: 0), "이전 · 10월 30일 72.5kg × 6")
        XCTAssertEqual(exercise.previousPerformance(for: 3), "72.5 × 6")
        XCTAssertNil(viewModel.previousRecordError(for: "bench-press"))
        XCTAssertEqual(loader.requests, ["bench-press", "bench-press"])
    }

    @MainActor
    private func makeViewModel(loader: PreviousRecordLoaderStub) -> WorkoutSessionViewModel {
        WorkoutSessionViewModel(
            routineID: "upper-a",
            goalSettings: nil,
            previousRecordService: loader
        )
    }

    private func response(
        hasPreviousRecord: Bool,
        weight: Double,
        reps: Int,
        setIndex: Int
    ) -> PreviousExerciseRecordResponse {
        PreviousExerciseRecordResponse(
            exerciseId: "bench-press",
            hasPreviousRecord: hasPreviousRecord,
            weight: weight,
            reps: reps,
            setIndex: setIndex,
            performedAt: "2026-10-30T09:00:00Z"
        )
    }
}

@MainActor
private final class PreviousRecordLoaderStub: WorkoutPreviousRecordLoading {
    private var outcomes: [Result<PreviousExerciseRecordResponse, APIClientError>]
    private(set) var requests: [String] = []

    init(outcomes: [Result<PreviousExerciseRecordResponse, APIClientError>]) {
        self.outcomes = outcomes
    }

    func fetchPreviousRecord(for exerciseID: String) async throws -> PreviousExerciseRecordResponse {
        requests.append(exerciseID)
        guard !outcomes.isEmpty else { throw APIClientError.invalidResponse }
        return try outcomes.removeFirst().get()
    }
}
