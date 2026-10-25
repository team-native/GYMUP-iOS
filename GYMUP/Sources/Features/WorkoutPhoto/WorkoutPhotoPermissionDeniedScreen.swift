import SwiftUI

struct WorkoutPhotoPermissionDeniedScreen: View {
    let onOpenSettings: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 72)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .frame(width: 64, height: 64)
                        .background(WorkoutCompletionColors.surface, in: Circle())
                        .accessibilityHidden(true)
                        .padding(.bottom, 20)

                    Text("카메라 접근이 꺼져 있어요")
                        .font(GymupTypography.headline)
                        .foregroundStyle(WorkoutCompletionColors.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 12)
                        .accessibilityIdentifier("workout.photo.permission-denied.title")

                    Text("설정 > GYMUP > 카메라를 켜면\n오운완 사진을 찍을 수 있어요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("workout.photo.permission-denied.message")

                    Spacer(minLength: 72)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            actionArea
        }
        .background(WorkoutCompletionColors.canvas)
        .accessibilityIdentifier("workout.photo.permission-denied")
    }

    private var navigationBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(WorkoutCompletionColors.primaryText)
            .accessibilityLabel("닫기")
            .accessibilityHint("권한 안내를 닫습니다.")
            .accessibilityIdentifier("workout.photo.permission-denied.close")

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
    }

    private var actionArea: some View {
        VStack(spacing: 2) {
            WorkoutCompletionPrimaryButton(title: "설정 열기", action: onOpenSettings)
                .accessibilityHint("설정 앱에서 GYMUP의 카메라 접근을 허용합니다.")
                .accessibilityIdentifier("workout.photo.permission-denied.open-settings")

            Button(action: onClose) {
                Text("닫기")
                    .font(GymupTypography.callout)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("권한 안내를 닫고 이전 화면으로 돌아갑니다.")
            .accessibilityIdentifier("workout.photo.permission-denied.dismiss")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(WorkoutCompletionColors.canvas)
    }
}

#Preview {
    WorkoutPhotoPermissionDeniedScreen(onOpenSettings: {}, onClose: {})
}
