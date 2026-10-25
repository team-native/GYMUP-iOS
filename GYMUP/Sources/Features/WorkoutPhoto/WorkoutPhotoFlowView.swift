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
    @State private var selectedFilter: WorkoutPhotoFilter = .natural
    @State private var adjustments = WorkoutPhotoAdjustments()
    @State private var stampStyle: WorkoutPhotoStampStyle = .card
    @State private var sharePayload: WorkoutPhotoSharePayload?
    @State private var isLoadingImage = false
    @State private var isRequestingCameraPermission = false
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
        .sheet(item: $sharePayload) { payload in
            WorkoutPhotoShareSheet(image: payload.image) { didSaveToPhotos, didFail in
                sharePayload = nil
                if didSaveToPhotos {
                    step = .saved
                } else if didFail {
                    selectionError = "사진을 공유하지 못했어요. 다시 시도해 주세요."
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
                filter: $selectedFilter,
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
                    filter: $selectedFilter,

                    onClose: onClose,
                    onContinue: advanceToAdjustments
                )
            } else {
                permissionGuideScreen
            }
        case .adjustments:
            if let selectedImage {
                WorkoutPhotoAdjustmentScreen(
                    image: selectedImage,
                    filter: selectedFilter,
                    adjustments: $adjustments,
                    onBack: { step = .filters },
                    onContinue: { step = .stamp }
                )
            } else {
                permissionGuideScreen
            }
        case .stamp:
            if let selectedImage {
                WorkoutPhotoStampScreen(
                    image: selectedImage,
                    data: data,
                    filter: selectedFilter,
                    adjustments: adjustments,
                    stampStyle: $stampStyle,
                    onBack: { step = .adjustments },
                    onSave: prepareSharePayload,
                    onShare: prepareSharePayload
                )
            } else {
                permissionGuideScreen
            }
        case .saved:
            WorkoutPhotoSavedScreen(onClose: onClose)
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

    private func advanceToAdjustments() {
        guard selectedImage != nil else {
            selectionError = "사진을 먼저 선택해 주세요."
            step = .intro
            return
        }

        guard !isLoadingImage else { return }
        step = .adjustments
    }

    private func prepareSharePayload() {
        guard let selectedImage else {
            selectionError = "사진을 먼저 선택해 주세요."
            step = .intro
            return
        }

        let poster = WorkoutPhotoPosterView(
            image: selectedImage,
            data: data,
            filter: selectedFilter,
            adjustments: adjustments,
            stampStyle: stampStyle
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
                selectedFilter = .natural
                adjustments = WorkoutPhotoAdjustments()
                stampStyle = .card
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
        adjustments = WorkoutPhotoAdjustments()
        step = editorStep
    }

    private func openCameraSettings() {
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
