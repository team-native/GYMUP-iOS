import SwiftUI

struct WorkoutPhotoSavedScreen: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 22) {
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 82, height: 82)
                    .background(WorkoutCompletionColors.red, in: Circle())
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("사진 앨범에 저장했어요")
                        .font(GymupTypography.title)
                        .multilineTextAlignment(.center)

                    Text("오늘의 운동을 스탬프와 함께 남겼어요.")
                        .font(GymupTypography.callout)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 16) {
                WorkoutCompletionPrimaryButton(title: "완료", action: onClose)

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
}
