import SwiftUI
import UIKit

struct WorkoutPhotoFilterScreen: View {
    let image: UIImage
    @Binding var filter: WorkoutPhotoFilter
    let onClose: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            WorkoutPhotoEditorNavigationBar(title: "사진 보정", onBack: onClose)

            ScrollView {
                VStack(spacing: 20) {
                    WorkoutPhotoImagePreview(image: image, filter: filter)
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityLabel("(filter.rawValue) 필터 미리보기")

                    VStack(alignment: .leading, spacing: 12) {
                        Text("필터")
                            .font(GymupTypography.headline)
                        WorkoutPhotoFilterSelector(selection: $filter)
                            .padding(.horizontal, -20)
                    }

                    Text("운동 사진에 어울리는 분위기를 선택해 보세요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "사진 보정하기", action: onContinue),
                secondary: WorkoutCompletionSecondaryButton(title: "취소", action: onClose)
            )
        }
        .background(WorkoutCompletionColors.canvas)
    }
}

struct WorkoutPhotoAdjustmentScreen: View {
    let image: UIImage
    let filter: WorkoutPhotoFilter
    @Binding var adjustments: WorkoutPhotoAdjustments
    let onBack: () -> Void
    let onContinue: () -> Void

    private var previewAccessibilityLabel: String {
        let contrast = signedValue(adjustments.contrast)
        let shadow = signedValue(adjustments.shadow)
        let sharpness = signedValue(adjustments.sharpness)
        return "대비 (contrast), 그림자 (shadow), 선명도 (sharpness) 보정 미리보기"
    }

    var body: some View {
        VStack(spacing: 0) {
            WorkoutPhotoEditorNavigationBar(title: "사진 보정", onBack: onBack)

            ScrollView {
                VStack(spacing: 18) {
                    WorkoutPhotoImagePreview(image: image, filter: filter, adjustments: adjustments)
                        .frame(height: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityLabel(previewAccessibilityLabel)

                    VStack(spacing: 14) {
                        WorkoutPhotoAdjustmentSlider(title: "대비", value: $adjustments.contrast)
                        WorkoutPhotoAdjustmentSlider(title: "그림자", value: $adjustments.shadow)
                        WorkoutPhotoAdjustmentSlider(title: "선명도", value: $adjustments.sharpness)
                    }
                    .padding(16)
                    .background(WorkoutCompletionColors.surface, in: RoundedRectangle(cornerRadius: 16))

                    Text("대비, 그림자, 선명도를 조절해 사진을 다듬어요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "스탬프 추가하기", action: onContinue),
                secondary: WorkoutCompletionSecondaryButton(title: "이전", action: onBack)
            )
        }
        .background(WorkoutCompletionColors.canvas)
    }

    private func signedValue(_ value: Double) -> String {
        value.formatted(
            .number
                .sign(strategy: .always(includingZero: false))
                .precision(.fractionLength(0))
        )
    }
}

struct WorkoutPhotoStampScreen: View {
    let image: UIImage
    let data: WorkoutCompletionData
    let filter: WorkoutPhotoFilter
    let adjustments: WorkoutPhotoAdjustments
    @Binding var stampStyle: WorkoutPhotoStampStyle
    let onBack: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            WorkoutPhotoEditorNavigationBar(title: "운동 스탬프", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WorkoutPhotoPosterView(
                        image: image,
                        data: data,
                        filter: filter,
                        adjustments: adjustments,
                        stampStyle: stampStyle
                    )
                    .accessibilityLabel("(data.routineName) 운동 기록 스탬프 미리보기")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("스탬프 스타일")
                            .font(GymupTypography.headline)
                        WorkoutPhotoStampStyleSelector(selection: $stampStyle)
                    }

                    Text("저장 또는 공유를 누르면 사진을 내보낼 방법을 선택할 수 있어요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }

            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "저장") {
                    onSave()
                },
                secondary: WorkoutCompletionSecondaryButton(title: "공유하기") {
                    onShare()
                }
            )
        }
        .background(WorkoutCompletionColors.canvas)
    }
}

struct WorkoutPhotoPosterView: View {
    let image: UIImage
    let data: WorkoutCompletionData
    let filter: WorkoutPhotoFilter
    let adjustments: WorkoutPhotoAdjustments
    let stampStyle: WorkoutPhotoStampStyle

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                WorkoutPhotoImagePreview(image: image, filter: filter, adjustments: adjustments)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                WorkoutPhotoStampOverlay(data: data, style: stampStyle)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .aspectRatio(0.78, contentMode: .fit)
    }
}

private struct WorkoutPhotoEditorNavigationBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("이전 화면")

            Spacer()

            Text(title)
                .font(GymupTypography.headline)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .foregroundStyle(WorkoutCompletionColors.primaryText)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}
