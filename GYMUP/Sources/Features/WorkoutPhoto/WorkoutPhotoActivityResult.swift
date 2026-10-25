import Foundation

enum WorkoutPhotoActivityResult: Equatable {
    case savedToPhotos
    case shared
    case cancelled
    case photoSaveFailed
    case shareFailed

    static func resolve(isPhotoSaveActivity: Bool, completed: Bool, hasError: Bool) -> Self {
        if hasError {
            return isPhotoSaveActivity ? .photoSaveFailed : .shareFailed
        }

        guard completed else { return .cancelled }
        return isPhotoSaveActivity ? .savedToPhotos : .shared
    }
}
