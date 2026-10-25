import XCTest
@testable import GYMUP

final class RoutineMoreActionsTests: XCTestCase {
    @MainActor
    func testMoreActionsPresentationCanBeOpened() {
        let viewModel = RoutineDetailViewModel(store: RoutineStore(), routineID: "upper-a")

        XCTAssertFalse(viewModel.isMoreActionsPresented)
        viewModel.presentMoreActions()
        XCTAssertTrue(viewModel.isMoreActionsPresented)
    }

    @MainActor
    func testDuplicateCreatesAnEditableCopyAndPreservesRoutineContent() throws {
        let store = RoutineStore()
        let original = try XCTUnwrap(store.routine(id: "upper-a"))

        let duplicateID = try XCTUnwrap(store.duplicateRoutine(id: original.id))
        let duplicate = try XCTUnwrap(store.routine(id: duplicateID))

        XCTAssertNotEqual(duplicate.id, original.id)
        XCTAssertEqual(duplicate.title, "상체 A 복사본")
        XCTAssertEqual(duplicate.name, "상체 A 복사본".uppercased())
        XCTAssertEqual(duplicate.exercises, original.exercises)
        XCTAssertEqual(duplicate.muscleGroups, original.muscleGroups)
        XCTAssertEqual(duplicate.durationMinutes, original.durationMinutes)
        XCTAssertEqual(duplicate.displayedSetCount, original.displayedSetCount)
        XCTAssertEqual(duplicate.lastPerformed, "기록 없음")
        XCTAssertFalse(duplicate.isRecommended)
        let originalIndex = try XCTUnwrap(store.routines.firstIndex(of: original))
        XCTAssertEqual(store.routines[originalIndex + 1].id, duplicateID)
    }

    @MainActor
    func testDuplicateTitlesStayUniqueAndDeleteRemovesRoutine() throws {
        let store = RoutineStore()
        let firstID = try XCTUnwrap(store.duplicateRoutine(id: "upper-a"))
        let secondID = try XCTUnwrap(store.duplicateRoutine(id: "upper-a"))

        XCTAssertEqual(store.routine(id: firstID)?.title, "상체 A 복사본")
        XCTAssertEqual(store.routine(id: secondID)?.title, "상체 A 복사본 2")
        XCTAssertTrue(store.deleteRoutine(id: firstID))
        XCTAssertNil(store.routine(id: firstID))
        XCTAssertFalse(store.deleteRoutine(id: firstID))
    }

    @MainActor
    func testDeleteRemainsPendingUntilConfirmedAndCanBeCancelled() throws {
        let store = RoutineStore()
        let viewModel = RoutineDetailViewModel(store: store, routineID: "upper-a")

        viewModel.presentDeleteConfirmation()
        XCTAssertTrue(viewModel.isDeleteConfirmationPresented)
        XCTAssertNotNil(store.routine(id: "upper-a"))

        viewModel.cancelDeleteConfirmation()
        XCTAssertFalse(viewModel.isDeleteConfirmationPresented)
        XCTAssertNotNil(store.routine(id: "upper-a"))

        viewModel.presentDeleteConfirmation()
        XCTAssertTrue(viewModel.confirmDeleteRoutine())
        XCTAssertFalse(viewModel.isDeleteConfirmationPresented)
        XCTAssertNil(store.routine(id: "upper-a"))
    }
}
