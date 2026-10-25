import XCTest
@testable import GYMUP

final class WorkoutPhotoSavedFlowTests: XCTestCase {
    func testSuccessfulSaveShowsTheSavedScreen() {
        let nextStep = WorkoutPhotoSaveFlow.stepAfterActivityCompletion(
            didSaveToPhotos: true,
            didFail: false,
            hasSelectedImage: true
        )

        XCTAssertEqual(nextStep, .saved)
    }

    func testCancelledActivityDoesNotShowTheSavedScreen() {
        let nextStep = WorkoutPhotoSaveFlow.stepAfterActivityCompletion(
            didSaveToPhotos: false,
            didFail: false,
            hasSelectedImage: true
        )

        XCTAssertNil(nextStep)
    }

    func testFailedActivityDoesNotShowTheSavedScreen() {
        let nextStep = WorkoutPhotoSaveFlow.stepAfterActivityCompletion(
            didSaveToPhotos: false,
            didFail: true,
            hasSelectedImage: true
        )

        XCTAssertNil(nextStep)
    }

    func testSaveWithoutPreviewImageDoesNotShowTheSavedScreen() {
        let nextStep = WorkoutPhotoSaveFlow.stepAfterActivityCompletion(
            didSaveToPhotos: true,
            didFail: false,
            hasSelectedImage: false
        )

        XCTAssertNil(nextStep)
    }
}
