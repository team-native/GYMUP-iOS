import XCTest
@testable import GYMUP

final class RoutineExerciseSettingsViewModelTests: XCTestCase {
    @MainActor
    func testStepperValuesStayWithinValidLimits() {
        var exercise = RoutineExercise.upper[0]
        exercise.setCount = 1
        exercise.repetitions = 1
        exercise.weight = 0
        exercise.restSeconds = 0
        let viewModel = RoutineExerciseSettingsViewModel(exercise: exercise)

        viewModel.adjustSets(by: -1)
        viewModel.adjustRepetitions(by: -1)
        viewModel.adjustWeight(by: -2.5)
        viewModel.adjustRest(by: -30)
        XCTAssertEqual(viewModel.exercise.setCount, 1)
        XCTAssertEqual(viewModel.exercise.repetitions, 1)
        XCTAssertEqual(viewModel.exercise.weight, 0)
        XCTAssertEqual(viewModel.exercise.restSeconds, 0)
    }

    @MainActor
    func testWeightAndRestSteppersUseFigmaIncrements() {
        let viewModel = RoutineExerciseSettingsViewModel(exercise: RoutineExercise.upper[0])
        viewModel.adjustWeight(by: 2.5)
        viewModel.adjustRest(by: 30)
        XCTAssertEqual(viewModel.exercise.weight, 62.5)
        XCTAssertEqual(viewModel.exercise.restTitle, "2:00")

        viewModel.adjustSets(by: 1)
        viewModel.adjustRepetitions(by: 1)
        XCTAssertEqual(viewModel.exercise.setCount, 5)
        XCTAssertEqual(viewModel.exercise.repetitions, 9)
    }
}
