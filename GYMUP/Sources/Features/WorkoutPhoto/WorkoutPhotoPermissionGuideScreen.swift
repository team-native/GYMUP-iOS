import SwiftUI

struct WorkoutPhotoPermissionGuideScreen: View {
    let isRequestingPermission: Bool
    let onClose: () -> Void
    let onAllowCamera: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 76)

                    Image(systemName: "camera")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(WorkoutCompletionColors.red)
                        .frame(width: 56, height: 56)
                        .background(WorkoutCompletionColors.red.opacity(0.12), in: Circle())
                        .accessibilityHidden(true)
                        .padding(.bottom, 18)

                    Text("오늘의 운동을\n사진으로 남겨볼까요?")
                        .font(GymupTypography.headline)
                        .foregroundStyle(WorkoutCompletionColors.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 12)

                    Text("촬영한 사진은 기기에만 저장되고\n운동 기록 스탬프로 만들 수 있어요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 72)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            actionArea
        }
        .background(WorkoutCompletionColors.canvas)
        .accessibilityIdentifier("workout.photo.permission-guide")
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
            .accessibilityHint("오운완 사진 안내를 닫습니다.")
            .accessibilityIdentifier("workout.photo.permission-guide.close")

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
    }

    private var actionArea: some View {
        VStack(spacing: 2) {
            WorkoutCompletionPrimaryButton(
                title: isRequestingPermission ? "권한 확인 중" : "카메라 허용",
                action: onAllowCamera
            )
            .disabled(isRequestingPermission)
            .accessibilityHint("카메라 권한을 요청하고, 허용하면 촬영 화면으로 이동합니다.")
            .accessibilityIdentifier("workout.photo.permission-guide.allow-camera")

            Button(action: onLater) {
                Text("나중에")
                    .font(GymupTypography.callout)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("권한 안내를 닫습니다.")
            .accessibilityIdentifier("workout.photo.permission-guide.later")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(WorkoutCompletionColors.canvas)
    }
}

#Preview {
    WorkoutPhotoPermissionGuideScreen(
        isRequestingPermission: false,
        onClose: {},
        onAllowCamera: {},
        onLater: {}
    )
}
