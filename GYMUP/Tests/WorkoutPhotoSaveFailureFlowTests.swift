import XCTest
@testable import GYMUP

final class WorkoutPhotoSaveFailureFlowTests: XCTestCase {
    func testCameraRollErrorUsesPhotoSaveFailureResult() {
        let result = WorkoutPhotoActivityResult.resolve(
            isPhotoSaveActivity: true,
            completed: false,
            hasError: true
        )

        XCTAssertEqual(result, .photoSaveFailed)
        XCTAssertEqual(
            WorkoutPhotoShareFlow.stepAfterActivityCompletion(
                currentStep: .stamp,
                result: result,
                hasSelectedImage: true
            ),
            .stamp
        )
    }

    func testSuccessfulRetryAfterFailureAdvancesToSavedScreen() {
        let failedResult = WorkoutPhotoActivityResult.resolve(
            isPhotoSaveActivity: true,
            completed: false,
            hasError: true
        )
        XCTAssertEqual(
            WorkoutPhotoShareFlow.stepAfterActivityCompletion(
                currentStep: .stamp,
                result: failedResult,
                hasSelectedImage: true
            ),
            .stamp
        )

        let result = WorkoutPhotoActivityResult.resolve(
            isPhotoSaveActivity: true,
            completed: true,
            hasError: false
        )

        XCTAssertEqual(result, .savedToPhotos)
        XCTAssertEqual(
            WorkoutPhotoShareFlow.stepAfterActivityCompletion(
                currentStep: .stamp,
                result: result,
                hasSelectedImage: true
            ),
            .saved
        )
    }

    func testCancelledSaveReturnsToStampWithoutShowingFailure() {
        let result = WorkoutPhotoActivityResult.resolve(
            isPhotoSaveActivity: true,
            completed: false,
            hasError: false
        )

        XCTAssertEqual(result, .cancelled)
        XCTAssertEqual(
            WorkoutPhotoShareFlow.stepAfterActivityCompletion(
                currentStep: .stamp,
                result: result,
                hasSelectedImage: true
            ),
            .stamp
        )
    }

    func testErrorFromAnotherShareActivityDoesNotUsePhotoSaveFailure() {
        let result = WorkoutPhotoActivityResult.resolve(
            isPhotoSaveActivity: false,
            completed: false,
            hasError: true
        )

        XCTAssertEqual(result, .shareFailed)
        XCTAssertNotEqual(result, .photoSaveFailed)
    }

    func testMissingSelectedImageCannotAdvanceAfterSuccessfulSave() {
        let result = WorkoutPhotoActivityResult.resolve(
            isPhotoSaveActivity: true,
            completed: true,
            hasError: false
        )

        XCTAssertEqual(
            WorkoutPhotoShareFlow.stepAfterActivityCompletion(
                currentStep: .stamp,
                result: result,
                hasSelectedImage: false
            ),
            .stamp
        )
    }

    func testDuplicateCompletionForDismissedPayloadIsIgnored() {
        let payloadID = UUID()

        XCTAssertFalse(
            WorkoutPhotoShareFlow.shouldHandleCompletion(
                activePayloadID: nil,
                completedPayloadID: payloadID
            )
        )
        XCTAssertTrue(
            WorkoutPhotoShareFlow.shouldHandleCompletion(
                activePayloadID: payloadID,
                completedPayloadID: payloadID
            )
        )
        XCTAssertFalse(
            WorkoutPhotoShareFlow.shouldHandleCompletion(
                activePayloadID: UUID(),
                completedPayloadID: payloadID
            )
        )
    }
}
