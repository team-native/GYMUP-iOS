import SwiftUI

struct HistoryEmptyContent: View {
    let onOpenRoutines: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image("H2EquipmentEmpty")
                .resizable()
                .scaledToFit()
                .frame(width: 148, height: 88)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("아직 운동 기록이 없어요")
                    .font(GymupTypography.headline)
                    .foregroundStyle(GymupColors.primaryText)
                Text("첫 운동을 마치면 날짜별 운동 기록과\n세트 · 볼륨 · PR이 여기에 쌓여요.")
                    .font(GymupTypography.callout)
                    .foregroundStyle(GymupColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: onOpenRoutines) {
                Text("루틴 시작하기")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(GymupColors.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("history.startRoutine")
            .accessibilityLabel("루틴 시작하기")
            .frame(minWidth: 44, minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityIdentifier("history.emptyState")
    }
}
