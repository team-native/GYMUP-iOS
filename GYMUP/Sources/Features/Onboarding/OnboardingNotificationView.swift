import SwiftUI
import UserNotifications

struct OnboardingNotificationView: View {
    let onFinish: () -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 130)
            Image("O8Bell").resizable().frame(width: 28, height: 28).frame(width: 78, height: 78)
                .background(GymupColors.accent.opacity(0.2), in: Circle()).accessibilityHidden(true)
            Text("휴식이 끝나면\n바로 알려드릴게요").font(GymupTypography.homeTitle)
                .multilineTextAlignment(.center).padding(.top, 20)
            Text("잠금화면에서도 남은 휴식 시간과\n다음 세트를 확인할 수 있어요.")
                .font(GymupTypography.uiStrong).foregroundStyle(GymupColors.secondaryText)
                .multilineTextAlignment(.center).padding(.top, 22)
            Spacer()
            OnboardingActionButton(title: "알림 허용", disabled: isRequesting) {
                isRequesting = true
                Task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                    onFinish()
                }
            }
            Button("나중에", action: onFinish).font(GymupTypography.uiBold)
                .foregroundStyle(GymupColors.secondaryText).frame(height: 44)
        }.foregroundStyle(GymupColors.primaryText).padding(.horizontal, 36).padding(.bottom, 4)
            .frame(maxWidth: .infinity).background(GymupColors.canvas.ignoresSafeArea())
    }
}
