import Foundation

enum WorkoutPhotoShareFlow {
    static func stepAfterActivityCompletion(
        currentStep: WorkoutPhotoStep,
        result: WorkoutPhotoActivityResult,
        hasSelectedImage: Bool
    ) -> WorkoutPhotoStep {
        guard result == .savedToPhotos else { return currentStep }

        return stepAfterActivityCompletion(
            currentStep: currentStep,
            didSaveToPhotos: true,
            didFail: false,
            hasSelectedImage: hasSelectedImage
        )
    }

    static func stepAfterActivityCompletion(
        currentStep: WorkoutPhotoStep,
        didSaveToPhotos: Bool,
        didFail: Bool,
        hasSelectedImage: Bool
    ) -> WorkoutPhotoStep {
        WorkoutPhotoSaveFlow.stepAfterActivityCompletion(
            didSaveToPhotos: didSaveToPhotos,
            didFail: didFail,
            hasSelectedImage: hasSelectedImage
        ) ?? currentStep
    }

    static func shouldHandleCompletion(activePayloadID: UUID?, completedPayloadID: UUID) -> Bool {
        activePayloadID == completedPayloadID
    }
}
