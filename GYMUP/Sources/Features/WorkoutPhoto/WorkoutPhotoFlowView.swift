import PhotosUI
import SwiftUI
import UIKit

struct WorkoutPhotoFlowView: View {
    let data: WorkoutCompletionData
    let onClose: () -> Void

    @State private var step: WorkoutPhotoStep = .intro
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoadingImage = false
    @State private var selectionError: String?

    var body: some View {
        Group {
            switch step {
            case .intro:
                introScreen
            case .filters:
                selectedPhotoScreen
            case .adjustments, .stamp, .saved:
                EmptyView()
            }
        }
        .background(WorkoutCompletionColors.canvas)
        .foregroundStyle(WorkoutCompletionColors.primaryText)
        .preferredColorScheme(.dark)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            loadImage(from: item)
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

                        Text("사진을 선택해 오늘의 운동 스탬프를 만들어요.\n선택한 사진은 기기에서만 사용돼요.")
                            .font(GymupTypography.callout)
                            .foregroundStyle(WorkoutCompletionColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
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
                .accessibilityHint("기기에 있는 사진을 선택합니다. 사진은 외부로 업로드되지 않습니다.")

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

    private var selectedPhotoScreen: some View {
        VStack(spacing: 0) {
            navigationBar(title: "사진 선택")

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("오늘의 운동 사진")
                        .font(GymupTypography.headline)

                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 440)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .accessibilityLabel("선택한 운동 사진 미리보기")
                    } else {
                        selectedPhotoPlaceholder
                    }

                    Text("다음 단계에서 사진 보정과 운동 스탬프를 추가할 수 있어요.")
                        .font(GymupTypography.callout)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 20)
            }

            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "다음") {
                    step = .adjustments
                },
                secondary: PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("다른 사진 선택")
                        .font(GymupTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(WorkoutCompletionColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14))
                }
            )
        }
    }

    private var selectedPhotoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(WorkoutCompletionColors.surface)
            .frame(height: 320)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    Text("사진을 선택하면 여기에 표시돼요")
                        .font(GymupTypography.callout)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                }
            }
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
                step = .filters
            } catch {
                selectionError = "사진을 불러오지 못했어요. 다시 선택해 주세요."
            }
        }
    }
}

#Preview {
    WorkoutPhotoFlowView(data: .sample, onClose: {})
}
