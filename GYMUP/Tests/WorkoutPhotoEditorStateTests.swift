import XCTest
@testable import GYMUP

final class WorkoutPhotoEditorStateTests: XCTestCase {
    func testSelectingFilterChangesStateUsedByPreviewAndStamp() {
        var editor = WorkoutPhotoEditorState()

        editor.filter = .definition

        XCTAssertEqual(editor.filter, .definition)
    }

    func testOriginalResetsFilterAndAllAdjustmentsToNeutral() {
        var editor = WorkoutPhotoEditorState(filter: .pump, adjustments: .init(contrast: 31, shadow: -24, sharpness: 43))

        editor.resetToOriginal()

        XCTAssertEqual(editor.filter, .natural)
        XCTAssertEqual(editor.adjustments, .original)
        XCTAssertEqual(editor.adjustments.contrast, 0)
        XCTAssertEqual(editor.adjustments.shadow, 0)
        XCTAssertEqual(editor.adjustments.sharpness, 0)
    }

    func testEditorValuesSurviveNavigationToStampAndBack() {
        let editor = WorkoutPhotoEditorState(filter: .mirror, adjustments: .init(contrast: -12, shadow: 26, sharpness: 8))
        var step = WorkoutPhotoStep.filters

        step = WorkoutPhotoEditorFlow.continueStep(hasSelectedImage: true, isLoadingImage: false) ?? step
        XCTAssertEqual(step, .stamp)

        step = WorkoutPhotoEditorFlow.stepAfterStampBack

        XCTAssertEqual(step, .filters)
        XCTAssertEqual(editor.filter, .mirror)
        XCTAssertEqual(editor.adjustments, .init(contrast: -12, shadow: 26, sharpness: 8))
    }

    func testContinueAppliesEditorOnlyWhenImageIsReady() {
        XCTAssertEqual(
            WorkoutPhotoEditorFlow.continueStep(hasSelectedImage: true, isLoadingImage: false),
            .stamp
        )
        XCTAssertNil(WorkoutPhotoEditorFlow.continueStep(hasSelectedImage: false, isLoadingImage: false))
        XCTAssertNil(WorkoutPhotoEditorFlow.continueStep(hasSelectedImage: true, isLoadingImage: true))
    }

    func testCancelClosesTheEditorWithoutResettingItsCurrentValues() {
        var didClose = false
        let editor = WorkoutPhotoEditorState(filter: .pump, adjustments: .init(contrast: 9, shadow: -3, sharpness: 17))

        WorkoutPhotoEditorFlow.cancel {
            didClose = true
        }

        XCTAssertTrue(didClose)
        XCTAssertEqual(editor.filter, .pump)
        XCTAssertEqual(editor.adjustments, .init(contrast: 9, shadow: -3, sharpness: 17))
    }
}
