import XCTest
@testable import GYMUP

final class HistoryServerWorkoutDetailTests: XCTestCase {
    @MainActor
    func testLoadMapsDocumentedMetricsAndSetFields() async throws {
        let workout = try makeWorkout()
        let response = WorkoutDetailResponse(
            workoutId: workout.id,
            routine: .object(["opaque": .string("preserved by API model")]),
            duration: 1_801,
            totalSets: 3,
            volume: 3_210.6,
            exercises: [
                WorkoutDetailExercise(sets: [
                    WorkoutDetailSet(reps: 8, weight: 40, isPersonalRecord: false),
                    WorkoutDetailSet(reps: 6, weight: 45, isPersonalRecord: true)
                ]),
                WorkoutDetailExercise(sets: [
                    WorkoutDetailSet(reps: 12, weight: 20, isPersonalRecord: false)
                ])
            ]
        )
        let service = WorkoutDetailServiceStub(outcomes: [.success(response)])
        let viewModel = HistoryServerWorkoutDetailViewModel(workout: workout, service: service)

        await viewModel.load()

        let detail = try XCTUnwrap(viewModel.detail)
        XCTAssertEqual(service.requestedWorkoutIDs, ["server-workout-1"])
        XCTAssertEqual(detail.durationMinutes, 31)
        XCTAssertEqual(detail.totalSets, 3)
        XCTAssertEqual(detail.volumeKilograms, 3_211)
        XCTAssertEqual(detail.exercises.map(\.ordinal), [1, 2])
        XCTAssertEqual(detail.exercises[0].sets.map(\.index), [1, 2])
        XCTAssertEqual(detail.exercises[0].sets[1].reps, 6)
        XCTAssertEqual(detail.exercises[0].sets[1].weight, 45)
        XCTAssertTrue(detail.exercises[0].sets[1].isPersonalRecord)
        XCTAssertEqual(workout.routineName, "UPPER A")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testFailureShowsServerMessageAndRetryLoadsDetail() async throws {
        let workout = try makeWorkout()
        let response = WorkoutDetailResponse(
            workoutId: workout.id,
            routine: .null,
            duration: 60,
            totalSets: 1,
            volume: 40,
            exercises: [WorkoutDetailExercise(sets: [
                WorkoutDetailSet(reps: 8, weight: 40, isPersonalRecord: false)
            ])]
        )
        let service = WorkoutDetailServiceStub(outcomes: [
            .failure(.server(
                statusCode: 503,
                detail: ServerErrorDetail(code: "TEMPORARY", message: "기록을 다시 불러와 주세요.")
            )),
            .success(response)
        ])
        let viewModel = HistoryServerWorkoutDetailViewModel(workout: workout, service: service)

        await viewModel.load()

        XCTAssertEqual(viewModel.errorMessage, "기록을 다시 불러와 주세요.")
        XCTAssertNil(viewModel.detail)
        XCTAssertFalse(viewModel.isLoading)

        await viewModel.retry()

        XCTAssertEqual(viewModel.detail?.totalSets, 1)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(service.requestedWorkoutIDs, ["server-workout-1", "server-workout-1"])
    }

    @MainActor
    func testMismatchedWorkoutIDDoesNotDisplayAnotherWorkoutDetail() async throws {
        let workout = try makeWorkout()
        let response = WorkoutDetailResponse(
            workoutId: "different-workout",
            routine: .null,
            duration: 60,
            totalSets: 1,
            volume: 40,
            exercises: []
        )
        let viewModel = HistoryServerWorkoutDetailViewModel(
            workout: workout,
            service: WorkoutDetailServiceStub(outcomes: [.success(response)])
        )

        await viewModel.load()

        XCTAssertNil(viewModel.detail)
        XCTAssertEqual(viewModel.errorMessage, "서버 기록을 불러오지 못했어요. 다시 시도해 주세요.")
        XCTAssertFalse(viewModel.isLoading)
    }

    private func makeWorkout() throws -> HistoryServerWorkout {
        try XCTUnwrap(HistoryServerWorkout(
            response: WorkoutListItem(
                workoutId: "server-workout-1",
                date: "2026-11-06T08:00:00Z",
                routineName: "UPPER A",
                duration: 1_800,
                totalSets: 3,
                volume: 3_200
            )
        ))
    }
}

@MainActor
private final class WorkoutDetailServiceStub: WorkoutDetailReading {
    enum Outcome {
        case success(WorkoutDetailResponse)
        case failure(APIClientError)
    }

    private var outcomes: [Outcome]
    private(set) var requestedWorkoutIDs: [String] = []

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func detail(workoutId: String) async throws -> WorkoutDetailResponse {
        requestedWorkoutIDs.append(workoutId)
        guard !outcomes.isEmpty else { throw APIClientError.invalidResponse }
        switch outcomes.removeFirst() {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}
