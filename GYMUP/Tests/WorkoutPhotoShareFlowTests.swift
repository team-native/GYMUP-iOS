import XCTest
import UIKit
@testable import GYMUP

final class WorkoutPhotoShareFlowTests: XCTestCase {
    @MainActor
    func testShareConfigurationContainsOnlyThePosterImageAndGenericName() {
        let poster = UIImage(systemName: "figure.strengthtraining.traditional")!
        let configuration = WorkoutPhotoShareConfiguration.make(for: poster)
        let providers = configuration.itemProvidersForActivityItemsConfiguration

        XCTAssertEqual(providers.count, 1)
        XCTAssertTrue(providers[0].canLoadObject(ofClass: UIImage.self))
        XCTAssertEqual(providers[0].suggestedName, WorkoutPhotoShareConfiguration.fileName)
        XCTAssertEqual(
            configuration.activityItemsConfigurationMetadata(key: .title) as? String,
            WorkoutPhotoShareConfiguration.fileName
        )
    }

    func testCancellingShareKeepsTheStampScreenVisible() {
        let nextStep = WorkoutPhotoShareFlow.stepAfterActivityCompletion(
            currentStep: .stamp,
            didSaveToPhotos: false,
            didFail: false,
            hasSelectedImage: true
        )

        XCTAssertEqual(nextStep, .stamp)
    }

    func testFailedShareKeepsTheStampScreenVisible() {
        let nextStep = WorkoutPhotoShareFlow.stepAfterActivityCompletion(
            currentStep: .stamp,
            didSaveToPhotos: false,
            didFail: true,
            hasSelectedImage: true
        )

        XCTAssertEqual(nextStep, .stamp)
    }

    func testSuccessfulPhotoSaveContinuesToTheSavedScreen() {
        let nextStep = WorkoutPhotoShareFlow.stepAfterActivityCompletion(
            currentStep: .stamp,
            didSaveToPhotos: true,
            didFail: false,
            hasSelectedImage: true
        )

        XCTAssertEqual(nextStep, .saved)
    }
}
