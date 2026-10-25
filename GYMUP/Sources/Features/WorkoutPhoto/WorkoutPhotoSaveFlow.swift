import Foundation

enum WorkoutPhotoSaveFlow {
    static func stepAfterActivityCompletion(
        didSaveToPhotos: Bool,
        didFail: Bool,
        hasSelectedImage: Bool
    ) -> WorkoutPhotoStep? {
        guard didSaveToPhotos, !didFail, hasSelectedImage else { return nil }
        return .saved
    }
}
