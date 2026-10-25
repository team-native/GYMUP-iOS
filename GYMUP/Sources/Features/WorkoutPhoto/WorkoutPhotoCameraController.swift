import AVFoundation
import Combine
import UIKit

final class WorkoutPhotoCameraController: NSObject, ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var isCapturing = false
    @Published private(set) var canUseFlash = false
    @Published private(set) var isFlashOn = false
    @Published private(set) var cameraPosition: AVCaptureDevice.Position = .front
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.teamnative.gymup.photo-camera")
    private let photoOutput = AVCapturePhotoOutput()
    private var activeInput: AVCaptureDeviceInput?
    private var activePhotoDelegate: WorkoutPhotoCaptureDelegate?
    private var isConfigured = false

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, self.configureSessionIfNeeded() else { return }
            guard !self.session.isRunning else { return }

            self.session.startRunning()
            let isRunning = self.session.isRunning
            DispatchQueue.main.async {
                self.isRunning = isRunning
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }

    func toggleFlash() {
        guard canUseFlash else { return }
        isFlashOn.toggle()
    }

    func switchCamera() {
        guard !isCapturing else { return }

        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured else { return }
            let currentPosition = self.activeInput?.device.position ?? .front
            let nextPosition: AVCaptureDevice.Position = currentPosition == .front ? .back : .front
            guard let device = Self.cameraDevice(at: nextPosition) else {
                self.publishError("전환할 카메라를 찾지 못했어요.")
                return
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: device)
                self.session.beginConfiguration()
                let previousInput = self.activeInput
                if let previousInput {
                    self.session.removeInput(previousInput)
                }

                guard self.session.canAddInput(newInput) else {
                    if let previousInput, self.session.canAddInput(previousInput) {
                        self.session.addInput(previousInput)
                    }
                    self.session.commitConfiguration()
                    self.publishError("카메라를 전환하지 못했어요. 다시 시도해 주세요.")
                    return
                }

                self.session.addInput(newInput)
                self.activeInput = newInput
                self.session.commitConfiguration()
                self.publishCameraState(for: device)
            } catch {
                self.publishError("카메라를 전환하지 못했어요. 다시 시도해 주세요.")
            }
        }
    }

    func capturePhoto(onCaptured: @escaping (UIImage?) -> Void) {
        guard !isCapturing else { return }
        isCapturing = true
        let flashEnabled = isFlashOn

        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning, let device = self.activeInput?.device else {
                self?.finishCapture(with: nil, onCaptured: onCaptured)
                return
            }

            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality
            if device.hasFlash {
                settings.flashMode = flashEnabled ? .on : .off
            }

            let delegate = WorkoutPhotoCaptureDelegate(
                onPhotoProcessed: { [weak self] image in
                    if image == nil {
                        self?.publishError("사진을 촬영하지 못했어요. 다시 시도해 주세요.")
                    }
                    onCaptured(image)
                },
                onCaptureFinished: { [weak self] error in
                    guard let self else { return }
                    self.sessionQueue.async {
                        self.activePhotoDelegate = nil
                    }
                    DispatchQueue.main.async {
                        self.isCapturing = false
                        if error != nil {
                            self.errorMessage = "사진을 촬영하지 못했어요. 다시 시도해 주세요."
                        }
                    }
                }
            )
            self.activePhotoDelegate = delegate
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    private func configureSessionIfNeeded() -> Bool {
        guard !isConfigured else { return true }
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            publishError("설정에서 카메라 접근을 허용해 주세요.")
            return false
        }
        guard let device = Self.cameraDevice(at: cameraPosition) else {
            publishError("사용할 수 있는 카메라를 찾지 못했어요.")
            return false
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            session.sessionPreset = .photo

            guard session.canAddInput(input) else {
                session.commitConfiguration()
                publishError("카메라를 시작할 수 없어요. 다시 시도해 주세요.")
                return false
            }
            session.addInput(input)

            guard session.canAddOutput(photoOutput) else {
                session.removeInput(input)
                session.commitConfiguration()
                publishError("카메라를 시작할 수 없어요. 다시 시도해 주세요.")
                return false
            }
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
            session.commitConfiguration()

            activeInput = input
            isConfigured = true
            publishCameraState(for: device)
            return true
        } catch {
            publishError("카메라를 시작할 수 없어요. 다시 시도해 주세요.")
            return false
        }
    }

    private func finishCapture(with image: UIImage?, onCaptured: @escaping (UIImage?) -> Void) {
        DispatchQueue.main.async {
            self.isCapturing = false
            if image == nil {
                self.errorMessage = "카메라를 준비하지 못했어요. 다시 시도해 주세요."
            }
            onCaptured(image)
        }
    }

    private func publishCameraState(for device: AVCaptureDevice) {
        DispatchQueue.main.async {
            self.cameraPosition = device.position
            self.canUseFlash = device.hasFlash
            if !device.hasFlash {
                self.isFlashOn = false
            }
        }
    }

    private func publishError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }

    private static func cameraDevice(at position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}

private final class WorkoutPhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let onPhotoProcessed: (UIImage?) -> Void
    private let onCaptureFinished: (Error?) -> Void

    init(
        onPhotoProcessed: @escaping (UIImage?) -> Void,
        onCaptureFinished: @escaping (Error?) -> Void
    ) {
        self.onPhotoProcessed = onPhotoProcessed
        self.onCaptureFinished = onCaptureFinished
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let photoData = photo.fileDataRepresentation(),
              let image = UIImage(data: photoData) else {
            DispatchQueue.main.async {
                self.onPhotoProcessed(nil)
            }
            return
        }

        DispatchQueue.main.async {
            self.onPhotoProcessed(image)
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.onCaptureFinished(error)
        }
    }
}
