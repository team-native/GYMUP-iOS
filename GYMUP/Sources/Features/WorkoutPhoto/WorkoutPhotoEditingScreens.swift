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
    @Binding var stamp: WorkoutPhotoStampState
    let onBack: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void

    @State private var isShowingStyleHelp = false

    private var posterModel: WorkoutPhotoPosterModel {
        stamp.posterModel(editor: WorkoutPhotoEditorState(filter: filter, adjustments: adjustments))
    }

    private var styleSelection: Binding<WorkoutPhotoStampStyle> {
        Binding(
            get: { stamp.style },
            set: { stamp.selectStyle($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            WorkoutPhotoEditorNavigationBar(title: "스탬프", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WorkoutPhotoPosterView(
                        image: image,
                        data: data,
                        model: posterModel
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(posterModel.accessibilityDescription(for: data))
                    .accessibilityIdentifier("workoutPhoto.stamp.posterPreview")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("스탬프 스타일")
                            .font(GymupTypography.headline)
                            .accessibilityAddTraits(.isHeader)
                        WorkoutPhotoStampStyleSelector(selection: styleSelection)
                    }

                    Button("조절 방법 자세히 보기") {
                        isShowingStyleHelp = true
                    }
                    .font(GymupTypography.caption.weight(.semibold))
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .frame(minHeight: 44, alignment: .leading)
                    .accessibilityHint("운동 기록 스타일과 사진 내보내기 방법을 확인합니다")
                    .accessibilityIdentifier("workoutPhoto.stamp.styleHelp")
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
        .sheet(isPresented: $isShowingStyleHelp) {
            WorkoutPhotoStampStyleHelpSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

struct WorkoutPhotoPosterView: View {
    let image: UIImage
    let data: WorkoutCompletionData
    let model: WorkoutPhotoPosterModel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                WorkoutPhotoImagePreview(image: image, filter: model.filter, adjustments: model.adjustments)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                WorkoutPhotoStampOverlay(data: data, style: model.style)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .aspectRatio(0.78, contentMode: .fit)
    }
}

private struct WorkoutPhotoStampStyleHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("스타일을 선택하면 사진 미리보기와 저장 결과에 바로 반영돼요.")
                    .font(GymupTypography.callout)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                styleDescription("카드", detail: "운동 기록을 어두운 카드에 담아요.")
                styleDescription("미니멀", detail: "사진을 더 많이 보이게 간결하게 표시해요.")
                styleDescription("볼드", detail: "붉은 그라데이션으로 기록을 강조해요.")
                styleDescription("스탬프", detail: "운동 결과를 선명한 붉은 배경에 담아요.")

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(WorkoutCompletionColors.canvas)
            .navigationTitle("조절 방법")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                        .font(GymupTypography.callout.weight(.semibold))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func styleDescription(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(GymupTypography.callout.weight(.semibold))
                .foregroundStyle(WorkoutCompletionColors.primaryText)
            Text(detail)
                .font(GymupTypography.caption)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
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
