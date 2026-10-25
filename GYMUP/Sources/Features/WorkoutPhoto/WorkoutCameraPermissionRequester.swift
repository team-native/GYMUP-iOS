import AVFoundation

struct WorkoutCameraPermissionRequester {
    private let authorizationStatus: () -> AVAuthorizationStatus
    private let requestAccess: () async -> Bool

    init(
        authorizationStatus: @escaping () -> AVAuthorizationStatus,
        requestAccess: @escaping () async -> Bool
    ) {
        self.authorizationStatus = authorizationStatus
        self.requestAccess = requestAccess
    }

    static let live = WorkoutCameraPermissionRequester(
        authorizationStatus: { AVCaptureDevice.authorizationStatus(for: .video) },
        requestAccess: { await AVCaptureDevice.requestAccess(for: .video) }
    )

    func requestCameraAccess() async -> Bool {
        switch authorizationStatus() {
        case .authorized:
            true
        case .notDetermined:
            await requestAccess()
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }
}
