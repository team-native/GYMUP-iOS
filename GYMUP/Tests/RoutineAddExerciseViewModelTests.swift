import XCTest
@testable import GYMUP

final class RoutineAddExerciseViewModelTests: XCTestCase {
    @MainActor
    func testEmptyRoutineStartsWithFigmaSelectionsAndAddsOnlyNewExercises() {
        let viewModel = RoutineAddExerciseViewModel(existingExercises: [])
        XCTAssertEqual(viewModel.selectedCount, 2)
        XCTAssertEqual(viewModel.exercisesToAdd().map(\.id), ["incline", "fly"])
        viewModel.toggle(RoutineExerciseOption.all[1])
        XCTAssertEqual(viewModel.selectedCount, 1)
    }

    @MainActor
    func testExistingExercisesCannotBeAddedTwiceAndFiltersSearchByName() {
        let viewModel = RoutineAddExerciseViewModel(existingExercises: RoutineExercise.upper)
        XCTAssertEqual(viewModel.selectedCount, 0)
        XCTAssertTrue(viewModel.isSelected(RoutineExerciseOption.all[0]))
        viewModel.toggle(RoutineExerciseOption.all[0])
        XCTAssertEqual(viewModel.selectedCount, 0)

        viewModel.searchText = "딥스"
        XCTAssertEqual(viewModel.visibleOptions.map(\.id), ["dips"])
        viewModel.toggle(viewModel.visibleOptions[0])
        XCTAssertEqual(viewModel.exercisesToAdd().map(\.id), ["dips"])
    }
}
