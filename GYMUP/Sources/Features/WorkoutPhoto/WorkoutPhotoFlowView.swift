import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct WorkoutPhotoFlowView: View {
    let data: WorkoutCompletionData
    let onClose: () -> Void
    var onCameraAuthorized: () -> Void = {}
    var onCameraPermissionDenied: () -> Void = {}

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var step: WorkoutPhotoStep = .intro
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var editor = WorkoutPhotoEditorState()
    @State private var stamp = WorkoutPhotoStampState()
    @State private var sharePayload: WorkoutPhotoSharePayload?
    @State private var isLoadingImage = false
    @State private var isRequestingCameraPermission = false
    @State private var isShowingPhotoSaveFailure = false
    @State private var shouldRetryPhotoSave = false
    @State private var selectionError: String?
    @StateObject private var cameraController = WorkoutPhotoCameraController()

    private let cameraPermissionRequester = WorkoutCameraPermissionRequester.live

    var body: some View {
        stepContent
        .background(WorkoutCompletionColors.canvas)
        .foregroundStyle(WorkoutCompletionColors.primaryText)
        .preferredColorScheme(.dark)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            selectedItem = nil
            loadImage(from: item)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshCameraPermissionAfterForegrounding()
        }
        .onChange(of: isShowingPhotoSaveFailure) { wasPresented, isPresented in
            guard wasPresented, !isPresented, shouldRetryPhotoSave else { return }
            shouldRetryPhotoSave = false
            prepareSharePayload()
        }
        .sheet(item: $sharePayload) { payload in
            WorkoutPhotoShareSheet(image: payload.image) { result in
                guard WorkoutPhotoShareFlow.shouldHandleCompletion(
                    activePayloadID: sharePayload?.id,
                    completedPayloadID: payload.id
                ) else { return }

                sharePayload = nil
                step = WorkoutPhotoShareFlow.stepAfterActivityCompletion(
                    currentStep: step,
                    result: result,
                    hasSelectedImage: selectedImage != nil
                )

                if result == .photoSaveFailed, selectedImage != nil {
                    isShowingPhotoSaveFailure = true
                } else if result == .shareFailed {
                    selectionError = "사진을 공유하지 못했어요. 다시 시도해 주세요."
                } else if result == .photoSaveFailed || result == .savedToPhotos, selectedImage == nil {
                    selectionError = "저장한 사진 미리보기를 찾지 못했어요. 다시 시도해 주세요."
                }
            }
        }
        .alert("사진 공유", isPresented: isShowingSelectionError) {
            Button("확인", role: .cancel) {
                selectionError = nil
            }
        } message: {
            Text(selectionError ?? "")
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .intro:
            permissionGuideScreen
        case .camera:
            WorkoutPhotoCameraScreen(
                camera: cameraController,
                filter: $editor.filter,
                selectedItem: $selectedItem,
                onClose: onClose,
                onCapture: handleCameraCapture
            )
        case .permissionDenied:
            WorkoutPhotoPermissionDeniedScreen(
                onOpenSettings: openCameraSettings,
                onClose: onClose
            )
        case .filters:
            if let selectedImage {
                WorkoutPhotoFilterScreen(
                    image: selectedImage,
                    editor: $editor,
                    onClose: onClose,
                    onContinue: continueToStamp
                )
            } else {
                permissionGuideScreen
            }
        case .stamp:
            if let selectedImage {
                WorkoutPhotoStampScreen(
                    image: selectedImage,
                    data: data,
                    filter: editor.filter,
                    adjustments: editor.adjustments,
                    stamp: $stamp,
                    onBack: { step = WorkoutPhotoEditorFlow.stepAfterStampBack },
                    onSave: prepareSharePayload,
                    onShare: prepareSharePayload
                )
                .alert("사진을 저장하지 못했어요", isPresented: $isShowingPhotoSaveFailure) {
                    Button("다시 시도") {
                        shouldRetryPhotoSave = true
                        isShowingPhotoSaveFailure = false
                    }
                    .accessibilityIdentifier("workout.photo.save-failure.retry")

                    Button("설정 열기", role: .cancel, action: openAppSettings)
                        .accessibilityIdentifier("workout.photo.save-failure.open-settings")
                } message: {
                    Text("사진 보관함 접근 권한이 꺼져 있거나 저장 공간이 부족해요.")
                }
                .tint(WorkoutCompletionColors.red)
            } else {
                permissionGuideScreen
            }
        case .saved:
            if let selectedImage {
                WorkoutPhotoSavedScreen(
                    image: selectedImage,
                    data: data,
                    posterModel: stamp.posterModel(editor: editor),
                    onClose: onClose
                )
            } else {
                permissionGuideScreen
            }
        }
    }

    private var permissionGuideScreen: some View {
        WorkoutPhotoPermissionGuideScreen(
            isRequestingPermission: isRequestingCameraPermission,
            onClose: onClose,
            onAllowCamera: requestCameraPermission,
            onLater: onClose
        )
    }

    private var isShowingSelectionError: Binding<Bool> {
        Binding(
            get: { selectionError != nil },
            set: { isPresented in
                if !isPresented { selectionError = nil }
            }
        )
    }

    private func continueToStamp() {
        guard selectedImage != nil else {
            selectionError = "사진을 먼저 선택해 주세요."
            step = .intro
            return
        }

        guard let nextStep = WorkoutPhotoEditorFlow.continueStep(
            hasSelectedImage: true,
            isLoadingImage: isLoadingImage
        ) else { return }

        step = nextStep
    }

    private func prepareSharePayload() {
        guard sharePayload == nil else { return }

        guard let selectedImage else {
            selectionError = "사진을 먼저 선택해 주세요."
            step = .intro
            return
        }

        let posterModel = stamp.posterModel(editor: editor)
        let poster = WorkoutPhotoPosterView(
            image: selectedImage,
            data: data,
            model: posterModel
        )
        .frame(width: 393, height: 504)

        let renderer = ImageRenderer(content: poster)
        renderer.scale = 3

        guard let renderedImage = renderer.uiImage else {
            selectionError = "운동 사진을 준비하지 못했어요. 다시 시도해 주세요."
            return
        }

        sharePayload = WorkoutPhotoSharePayload(image: renderedImage)
    }

    private func loadImage(from item: PhotosPickerItem) {
        isLoadingImage = true
        selectionError = nil

        Task { @MainActor in
            defer { isLoadingImage = false }

            do {
                guard let imageData = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: imageData) else {
                    selectionError = "이 사진을 불러오지 못했어요. 다른 사진을 선택해 주세요."
                    return
                }

                selectedImage = image
                editor = WorkoutPhotoEditorState()
                stamp = WorkoutPhotoStampState()
                step = .filters
            } catch {
                selectionError = "사진을 불러오지 못했어요. 다시 선택해 주세요."
            }
        }
    }

    private func requestCameraPermission() {
        guard !isRequestingCameraPermission else { return }
        isRequestingCameraPermission = true

        Task { @MainActor in
            defer { isRequestingCameraPermission = false }

            let isAuthorized = await cameraPermissionRequester.requestCameraAccess()
            if isAuthorized {
                onCameraAuthorized()
            } else {
                onCameraPermissionDenied()
            }
            step = WorkoutPhotoCameraFlow.permissionStep(isAuthorized: isAuthorized)
        }
    }

    private func refreshCameraPermissionAfterForegrounding() {
        guard step == .camera || step == .permissionDenied else { return }
        let isAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        step = WorkoutPhotoCameraFlow.stepAfterSettingsReturn(isAuthorized: isAuthorized)
    }

    private func handleCameraCapture(_ image: UIImage?) {
        guard let editorStep = WorkoutPhotoCameraFlow.editorStep(afterCaptureSucceeded: image != nil),
              let image else { return }

        selectedImage = image
        editor = WorkoutPhotoEditorState()
        stamp = WorkoutPhotoStampState()
        step = editorStep
    }

    private func openCameraSettings() {
        openAppSettings()
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
    }
}

struct WorkoutPhotoFlowHostView: View {
    @State private var isShowingWorkoutPhoto = false

    var body: some View {
        WorkoutCompletionFlowView(onWorkoutPhoto: {
            isShowingWorkoutPhoto = true
        })
        .sheet(isPresented: $isShowingWorkoutPhoto) {
            WorkoutPhotoFlowView(data: .sample) {
                isShowingWorkoutPhoto = false
            }
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    WorkoutPhotoFlowView(data: .sample, onClose: {})
}
