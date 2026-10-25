import Foundation

enum WorkoutPhotoStep: Equatable {
    case intro
    case camera
    case filters
    case adjustments
    case stamp
    case saved
}

enum WorkoutPhotoCameraFlow {
    static func cameraStep(afterPermissionGranted granted: Bool) -> WorkoutPhotoStep? {
        granted ? .camera : nil
    }

    static func editorStep(afterCaptureSucceeded succeeded: Bool) -> WorkoutPhotoStep? {
        succeeded ? .filters : nil
    }
}

enum WorkoutPhotoFilter: String, CaseIterable, Identifiable {
    case natural = "Natural"
    case pump = "Pump"
    case definition = "Definition"
    case mirror = "Mirror"

    var id: Self { self }
}

struct WorkoutPhotoAdjustments {
    var contrast = 12.0
    var shadow = -8.0
    var sharpness = 20.0
}

enum WorkoutPhotoStampStyle: String, CaseIterable, Identifiable {
    case card = "카드"
    case minimal = "미니멀"
    case bold = "볼드"
    case stamp = "스탬프"

    var id: Self { self }
}
