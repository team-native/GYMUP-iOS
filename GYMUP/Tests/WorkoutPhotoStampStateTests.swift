import XCTest
@testable import GYMUP

final class WorkoutPhotoStampStateTests: XCTestCase {
    func testSelectingStyleUpdatesTheStateUsedByThePoster() {
        var stamp = WorkoutPhotoStampState()

        stamp.selectStyle(.minimal)

        XCTAssertEqual(stamp.style, .minimal)
        XCTAssertEqual(stamp.posterModel(editor: WorkoutPhotoEditorState()).style, .minimal)
    }

    func testPosterModelCarriesEditorAndAccessibleContent() {
        var stamp = WorkoutPhotoStampState()
        stamp.selectStyle(.bold)
        let editor = WorkoutPhotoEditorState(
            filter: .definition,
            adjustments: .init(contrast: 24, shadow: -12, sharpness: 18)
        )

        let poster = stamp.posterModel(editor: editor)
        let description = poster.accessibilityDescription(for: .sample)

        XCTAssertEqual(poster.filter, .definition)
        XCTAssertEqual(poster.adjustments, editor.adjustments)
        XCTAssertEqual(poster.style, .bold)
        XCTAssertTrue(description.contains("UPPER A"))
        XCTAssertTrue(description.contains("58 MIN"))
        XCTAssertTrue(description.contains("강조된 운동 기록 스타일"))
    }

    func testStampBackDestinationIsPhotoFilters() {
        let nextStep = WorkoutPhotoEditorFlow.stepAfterStampBack

        XCTAssertEqual(nextStep, .filters)
    }

    func testCancelInvokesFlowCloseAction() {
        var didClose = false

        WorkoutPhotoEditorFlow.cancel {
            didClose = true
        }

        XCTAssertTrue(didClose)
    }
}
