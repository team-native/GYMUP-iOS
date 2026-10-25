import SwiftUI
import UIKit

struct WorkoutPhotoFilterScreen: View {
    let image: UIImage
    @Binding var editor: WorkoutPhotoEditorState
    let onClose: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: cancelEditing) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("사진 편집 취소")

                Spacer()

                Text("보정")
                    .font(GymupTypography.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button("다음", action: onContinue)
                    .font(GymupTypography.callout.weight(.semibold))
                    .foregroundStyle(WorkoutCompletionColors.red)
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    .accessibilityHint("보정한 사진에 운동 스탬프를 추가합니다")
            }
            .foregroundStyle(WorkoutCompletionColors.primaryText)
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    WorkoutPhotoImagePreview(
                        image: image,
                        filter: editor.filter,
                        adjustments: editor.adjustments
                    )
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityLabel("\(editor.filter.rawValue) 필터와 보정 미리보기")
                        .accessibilityIdentifier("workoutPhoto.editor.preview")

                    VStack(alignment: .leading, spacing: 12) {
                        Text("필터")
                            .font(GymupTypography.headline)
                        WorkoutPhotoFilterSelector(selection: $editor.filter)
                            .padding(.horizontal, -20)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("보정")
                                .font(GymupTypography.headline)

                            Spacer()

                            Button("원본") {
                                editor.resetToOriginal()
                            }
                            .font(GymupTypography.caption.weight(.semibold))
                            .foregroundStyle(WorkoutCompletionColors.secondaryText)
                            .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                            .accessibilityHint("필터와 모든 보정값을 원래 상태로 되돌립니다")
                            .accessibilityIdentifier("workoutPhoto.editor.reset")
                        }

                        VStack(spacing: 12) {
                            WorkoutPhotoAdjustmentSlider(title: "대비", value: $editor.adjustments.contrast)
                            WorkoutPhotoAdjustmentSlider(title: "그림자", value: $editor.adjustments.shadow)
                            WorkoutPhotoAdjustmentSlider(title: "선명도", value: $editor.adjustments.sharpness)
                        }
                        .padding(16)
                        .background(WorkoutCompletionColors.surface, in: RoundedRectangle(cornerRadius: 16))
                    }

                    Text("필터와 밝기·보정은 미리보기에 바로 반영돼요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .background(WorkoutCompletionColors.canvas)
    }

    private func cancelEditing() {
        WorkoutPhotoEditorFlow.cancel(onClose: onClose)
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
