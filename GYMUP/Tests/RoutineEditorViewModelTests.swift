import XCTest
@testable import GYMUP

final class RoutineEditorViewModelTests: XCTestCase {
    @MainActor
    func testTitleIsLimitedToTwentyCharactersAndWhitespaceCannotSave() {
        let viewModel = RoutineEditorViewModel(store: RoutineStore(), routineID: nil)
        viewModel.limitTitle(String(repeating: "가", count: 21))
        XCTAssertEqual(viewModel.title.count, 20)
        XCTAssertTrue(viewModel.canSave)
        viewModel.title = "   "
        XCTAssertFalse(viewModel.canSave)
        XCTAssertNil(viewModel.save())
    }

    @MainActor
    func testReorderingMovesExerciseBeforeTarget() {
        let viewModel = RoutineEditorViewModel(store: RoutineStore(), routineID: "upper-a")
        viewModel.moveExercise(id: "pushdown", before: "bench")
        XCTAssertEqual(viewModel.exercises.first?.id, "pushdown")
        viewModel.moveExercise(id: "bench", before: "shoulder")
        XCTAssertEqual(viewModel.exercises.map(\.id), ["pushdown", "incline", "bench", "shoulder", "fly"])
    }

    @MainActor
    func testSavingUpdatesSharedRoutineAndCreatesNewRoutine() {
        let store = RoutineStore()
        let editor = RoutineEditorViewModel(store: store, routineID: "upper-a")
        editor.title = "가슴 루틴"
        editor.exercises.removeLast()
        XCTAssertEqual(editor.save(), "upper-a")
        XCTAssertEqual(store.routine(id: "upper-a")?.title, "가슴 루틴")
        XCTAssertEqual(store.routine(id: "upper-a")?.exerciseCount, 4)

        let newEditor = RoutineEditorViewModel(store: store, routineID: nil)
        newEditor.title = "하체 A"
        let newID = newEditor.save()
        XCTAssertEqual(store.routine(id: newID ?? "")?.title, "하체 A")
    }
}
