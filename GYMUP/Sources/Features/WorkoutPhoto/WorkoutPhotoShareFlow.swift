import Foundation

enum WorkoutPhotoShareFlow {
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
}
