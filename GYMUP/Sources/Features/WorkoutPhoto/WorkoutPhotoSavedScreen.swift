import SwiftUI
import UIKit

struct WorkoutPhotoSavedScreen: View {
    let image: UIImage
    let data: WorkoutCompletionData
    let posterModel: WorkoutPhotoPosterModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            closeNavigationBar

            ScrollView {
                VStack(spacing: 20) {
                    WorkoutPhotoPosterView(image: image, data: data, model: posterModel)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(posterModel.accessibilityDescription(for: data))
                        .accessibilityIdentifier("workoutPhoto.saved.posterPreview")

                    savedConfirmation
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                WorkoutCompletionPrimaryButton(title: "완료", action: onClose)
                    .accessibilityIdentifier("workoutPhoto.saved.done")

                Text("Progress Album 보기 · V2")
                    .font(GymupTypography.caption)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .accessibilityLabel("Progress Album은 기록 화면 업데이트 후 제공됩니다")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WorkoutCompletionColors.canvas)
        .accessibilityElement(children: .contain)
    }

    private var closeNavigationBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("닫기")
            .accessibilityHint("저장 완료 화면을 닫습니다")
            .accessibilityIdentifier("workoutPhoto.saved.close")

            Spacer()
        }
        .foregroundStyle(WorkoutCompletionColors.primaryText)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var savedConfirmation: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(red: 0.30, green: 0.84, blue: 0.51))
                .accessibilityHidden(true)

            Text("사진 앨범에 저장했어요")
                .font(GymupTypography.caption)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 43)
        .background(
            Color(red: 31.0 / 255, green: 31.0 / 255, blue: 36.0 / 255),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("workoutPhoto.saved.confirmation")
    }
}
