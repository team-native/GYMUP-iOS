import XCTest
@testable import GYMUP

final class RoutineDetailViewModelTests: XCTestCase {
    @MainActor
    func testDetailReadsCurrentSharedStore() {
        let store = RoutineStore()
        let viewModel = RoutineDetailViewModel(store: store, routineID: "upper-a")
        XCTAssertNotNil(viewModel.routine)
        store.routines.removeAll { $0.id == "upper-a" }
        XCTAssertNil(viewModel.routine)
        XCTAssertTrue(viewModel.summary.isEmpty)
    }

    func testExerciseSummaryReflectsEditedRestAndWeight() {
        var exercise = RoutineExercise.upper[0]
        exercise.restSeconds = 75
        exercise.weight = 22.5
        XCTAssertEqual(exercise.restTitle, "1:15")
        XCTAssertEqual(exercise.weightTitle, "22.5")
        exercise.restSeconds = 0
        XCTAssertEqual(exercise.restTitle, "0:00")
    }
}
