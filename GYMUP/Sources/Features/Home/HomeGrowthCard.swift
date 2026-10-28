import SwiftUI

struct HomeGrowthCard: View {
    let inventory: BarbellCustomizationViewModel
    let growthViewModel: GrowthViewModel
    let rewardNotice: String
    let onOpenGrowth: () -> Void
    let onNewItem: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(growthViewModel.stageTitle)
                    .font(GymupTypography.label)
                    .tracking(0.17)
                    .foregroundStyle(GymupColors.brandText)
                Spacer(minLength: 6)
                if inventory.hasNewItem {
                    Button(action: onNewItem) { newItemBanner }
                        .buttonStyle(.plain)
                }
            }
            Button(action: onOpenGrowth) {
                VStack(spacing: 12) {
                    equipment
                    HomeGrowthSummaryView(
                        growth: growthViewModel.growth,
                        nextPlateProgress: growthViewModel.nextPlateProgress,
                        progress: growthViewModel.progress
                    )
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.growth")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(height: 318)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var newItemBanner: some View {
        HStack(spacing: 10) {
            Image("H1IconSparkle")
                .resizable()
                .frame(width: 16, height: 16)
            Text(rewardNotice)
                .font(GymupTypography.uiMedium)
                .tracking(-0.09)
                .lineLimit(1)
            Image("H1IconChevronRight")
                .resizable()
                .frame(width: 16, height: 16)
        }
        .foregroundStyle(GymupColors.primaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(GymupColors.brandSubtle, in: RoundedRectangle(cornerRadius: 14))
    }

    private var equipment: some View {
        VStack(spacing: 0) {
            Image(inventory.equippedPlateID == .blackPlate ? "H6Equipment" : "H1Equipment")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 150)
            Text("\(growthViewModel.barbellWeight) KG")
                .font(GymupTypography.display)
                .lineSpacing(-1)
                .foregroundStyle(GymupColors.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
