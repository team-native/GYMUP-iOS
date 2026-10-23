import PhotosUI
import SwiftUI
import UIKit

struct WorkoutPhotoFlowView: View {
    let data: WorkoutCompletionData
    let onClose: () -> Void

    @State private var step: WorkoutPhotoStep = .intro
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedFilter: WorkoutPhotoFilter = .natural
    @State private var adjustments = WorkoutPhotoAdjustments()
    @State private var stampStyle: WorkoutPhotoStampStyle = .card
    @State private var sharePayload: WorkoutPhotoSharePayload?
    @State private var isLoadingImage = false
    @State private var selectionError: String?

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
            introScreen
        case .filters:
            if let selectedImage {
                WorkoutPhotoFilterScreen(
                    image: selectedImage,
                    filter: $selectedFilter,
                    
                    onClose: onClose,
                    onContinue: advanceToAdjustments
                )
            } else {
                introScreen
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
                introScreen
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
                introScreen
            }
        case .saved:
            WorkoutPhotoSavedScreen(onClose: onClose)
        }
    }

    private var introScreen: some View {
        VStack(spacing: 0) {
            navigationBar(title: "오운완 사진")

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(WorkoutCompletionColors.red)
                        .frame(width: 88, height: 88)
                        .background(WorkoutCompletionColors.red.opacity(0.12), in: Circle())
                        .padding(.top, 64)
                        .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        Text("오늘의 운동을\n사진으로 남겨볼까요?")
                            .font(GymupTypography.title)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 4) {
                            Text("사진을 선택해 오늘의 운동 스탬프를 만들어요.")
                            Text("사진은 앱 서버로 전송되지 않아요.")
                        }
                        .font(GymupTypography.callout)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .multilineTextAlignment(.center)
                    }

                    if let selectionError {
                        Label(selectionError, systemImage: "exclamationmark.circle.fill")
                            .font(GymupTypography.caption)
                            .foregroundStyle(WorkoutCompletionColors.red)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            VStack(spacing: 10) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 8) {
                        if isLoadingImage {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isLoadingImage ? "사진을 불러오는 중" : "사진 선택하기")
                    }
                    .font(GymupTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(WorkoutCompletionColors.red, in: RoundedRectangle(cornerRadius: 14))
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isLoadingImage)
                .accessibilityHint("기기에 있는 사진을 선택합니다. 앱 서버로 전송되지 않습니다.")

                Button("나중에", action: onClose)
                    .font(GymupTypography.callout)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
    }

    private var isShowingSelectionError: Binding<Bool> {
        Binding(
            get: { selectionError != nil },
            set: { isPresented in
                if !isPresented { selectionError = nil }
            }
        )
    }

    private func navigationBar(title: String) -> some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("닫기")

            Spacer()

            Text(title)
                .font(GymupTypography.headline)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
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
