import Foundation

enum WorkoutPhotoStep: Equatable {
    case intro
    case camera
    case permissionDenied
    case filters
    case stamp
    case saved
}

enum WorkoutPhotoCameraFlow {
    static func cameraStep(afterPermissionGranted granted: Bool) -> WorkoutPhotoStep? {
        granted ? .camera : nil
    }

    static func permissionStep(isAuthorized: Bool) -> WorkoutPhotoStep {
        isAuthorized ? .camera : .permissionDenied
    }

    static func stepAfterSettingsReturn(isAuthorized: Bool) -> WorkoutPhotoStep {
        permissionStep(isAuthorized: isAuthorized)
    }

    static func editorStep(afterCaptureSucceeded succeeded: Bool) -> WorkoutPhotoStep? {
        succeeded ? .filters : nil
    }
}

enum WorkoutPhotoEditorFlow {
    static func continueStep(hasSelectedImage: Bool, isLoadingImage: Bool) -> WorkoutPhotoStep? {
        guard hasSelectedImage, !isLoadingImage else { return nil }
        return .stamp
    }

    static var stepAfterStampBack: WorkoutPhotoStep { .filters }

    static func cancel(onClose: () -> Void) {
        onClose()
    }
}

enum WorkoutPhotoFilter: String, CaseIterable, Identifiable {
    case natural = "Natural"
    case pump = "Pump"
    case definition = "Definition"
    case mirror = "Mirror"

    var id: Self { self }
}

struct WorkoutPhotoAdjustments: Equatable {
    var contrast = 12.0
    var shadow = -8.0
    var sharpness = 20.0

    static let original = WorkoutPhotoAdjustments(contrast: 0, shadow: 0, sharpness: 0)
}

struct WorkoutPhotoEditorState: Equatable {
    var filter: WorkoutPhotoFilter = .natural
    var adjustments = WorkoutPhotoAdjustments()

    mutating func resetToOriginal() {
        filter = .natural
        adjustments = .original
    }
}

enum WorkoutPhotoStampStyle: String, CaseIterable, Identifiable {
    case card = "카드"
    case minimal = "미니멀"
    case bold = "볼드"
    case stamp = "스탬프"

    var id: Self { self }

    var accessibilityDescription: String {
        switch self {
        case .card:
            "카드형 운동 기록"
        case .minimal:
            "간결한 운동 기록"
        case .bold:
            "강조된 운동 기록"
        case .stamp:
            "스탬프형 운동 기록"
        }
    }
}

struct WorkoutPhotoStampState: Equatable {
    private(set) var style: WorkoutPhotoStampStyle = .card

    mutating func selectStyle(_ style: WorkoutPhotoStampStyle) {
        self.style = style
    }

    func posterModel(editor: WorkoutPhotoEditorState) -> WorkoutPhotoPosterModel {
        WorkoutPhotoPosterModel(editor: editor, style: style)
    }
}

struct WorkoutPhotoPosterModel: Equatable {
    let filter: WorkoutPhotoFilter
    let adjustments: WorkoutPhotoAdjustments
    let style: WorkoutPhotoStampStyle

    init(editor: WorkoutPhotoEditorState, style: WorkoutPhotoStampStyle) {
        filter = editor.filter
        adjustments = editor.adjustments
        self.style = style
    }

    func accessibilityDescription(for data: WorkoutCompletionData) -> String {
        let metrics = data.metrics.prefix(3).map { "\($0.value) \($0.unit)" }.joined(separator: ", ")
        return "\(data.routineName) 운동 사진, \(data.completedAt), \(metrics), " +
            "성장도 \(data.previousGrowth)에서 \(data.growth), \(data.earnedXP) 경험치, " +
            "\(style.accessibilityDescription) 스타일"
    }
}
