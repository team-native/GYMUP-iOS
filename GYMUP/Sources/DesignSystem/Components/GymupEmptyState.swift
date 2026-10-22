import SwiftUI

struct GymupEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: GymupSpacing.medium) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(GymupColors.accent)
                .frame(width: 64, height: 64)
                .background(GymupColors.accent.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            Text(title)
                .font(GymupTypography.headline)
                .foregroundStyle(GymupColors.primaryText)

            Text(message)
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GymupSpacing.xxLarge)
    }
}

#Preview {
    GymupEmptyState(
        symbol: "figure.run",
        title: "아직 기록이 없어요",
        message: "운동을 기록하면 이곳에서 확인할 수 있어요."
    )
    .padding()
}
