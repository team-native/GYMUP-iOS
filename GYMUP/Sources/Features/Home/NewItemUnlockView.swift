import SwiftUI

struct NewItemUnlockView: View {
    let onEquip: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("NEW ITEM UNLOCKED")
                .font(GymupTypography.label)
                .tracking(0.17)
                .foregroundStyle(GymupColors.brandText)
                .frame(height: 13)
            Image("H6Equipment")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
                .frame(height: 150)
            Text("블랙 원판")
                .font(GymupTypography.homeTitle)
                .tracking(-0.43)
                .foregroundStyle(GymupColors.primaryText)
                .frame(minHeight: 25)
            Text("주간 목표 3주 연속 달성으로 해금됐어요.")
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(minHeight: 19)
            VStack(spacing: 6) {
                GymupButton(
                    title: "장착하기",
                    font: GymupTypography.sectionTitle,
                    height: 50,
                    cornerRadius: 999,
                    action: onEquip
                )
                GymupButton(
                    title: "나중에",
                    variant: .ghost,
                    font: GymupTypography.uiBold,
                    height: 34,
                    cornerRadius: 999,
                    action: onLater
                )
            }
            .padding(.top, 12)
        }
        .padding(.top, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }
}
