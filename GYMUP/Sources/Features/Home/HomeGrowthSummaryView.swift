import SwiftUI

struct HomeGrowthSummaryView: View {
    let growth: Int
    let nextPlateProgress: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("GROWTH")
                    .font(GymupTypography.label)
                    .tracking(0.17)
                    .foregroundStyle(GymupColors.secondaryText)
                Text("\(growth)")
                    .font(GymupTypography.metric)
                    .tracking(0.13)
                    .foregroundStyle(GymupColors.primaryText)
                Text("/100")
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(GymupColors.tertiaryText)
                Spacer()
                Text("다음 원판까지 \(nextPlateProgress)")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(GymupColors.overlay)
                    Capsule()
                        .fill(GymupColors.accent)
                        .frame(width: geometry.size.width * 0.687)
                }
            }
            .frame(height: 6)
        }
    }

}
