import SwiftUI

struct LevelView: View {
    let onNavigationStateChanged: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LevelViewModel()

    var body: some View {
        VStack(spacing: 0) {
            GymupDetailNavigationBar(title: "레벨", onBack: dismiss.callAsFunction)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 19) {
                    Text("LEVEL")
                        .font(GymupTypography.label)
                        .foregroundStyle(GymupColors.brandText)
                        .frame(height: 13)
                    Text("\(viewModel.level)")
                        .font(GymupTypography.score)
                        .tracking(-0.57)
                        .foregroundStyle(GymupColors.primaryText)
                        .frame(height: 55)
                    experienceSummary
                    experienceProgress
                    nextReward
                    sectionLabel("XP 기준")
                    experienceFactors
                    sectionLabel("최근 획득")
                    recentExperience
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { onNavigationStateChanged(true) }
        .onDisappear { onNavigationStateChanged(false) }
    }

    private var experienceSummary: some View {
        HStack {
            Text("\(viewModel.experience.formatted()) / \(viewModel.targetExperience.formatted()) XP")
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
            Spacer(minLength: 4)
            Text("LV.\(viewModel.level + 1)까지 \(viewModel.remainingExperience)")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
        }
        .frame(minHeight: 21)
    }

    private var experienceProgress: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(GymupColors.overlay)
                Capsule()
                    .fill(GymupColors.accent)
                    .frame(width: geometry.size.width * viewModel.progress)
            }
        }
        .frame(height: 6)
        .accessibilityLabel("다음 레벨 진행률 \(Int(viewModel.progress * 100))퍼센트")
    }

    private var nextReward: some View {
        HStack(spacing: 12) {
            Image("H4IconTrophy")
                .resizable()
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 0) {
                Text("LV.\(viewModel.level + 1) 보상")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(minHeight: 15)
                Text(viewModel.nextReward)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(minHeight: 21)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var experienceFactors: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(viewModel.factors) { factor in
                HStack {
                    Text(factor.title)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Spacer(minLength: 4)
                    Text(factor.value)
                        .font(GymupTypography.number)
                        .foregroundStyle(GymupColors.brandText)
                }
                .padding(.horizontal, 12)
                .frame(height: 37)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var recentExperience: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.recentExperience) { entry in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                            .font(GymupTypography.uiStrong)
                            .foregroundStyle(GymupColors.primaryText)
                            .frame(minHeight: 21)
                        Text(entry.date)
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                            .frame(minHeight: 15)
                    }
                    Spacer()
                    Text("+\(entry.value) XP")
                        .font(GymupTypography.number)
                        .foregroundStyle(GymupColors.brandText)
                }
                .padding(.vertical, 12)
                if entry.id != viewModel.recentExperience.last?.id {
                    Rectangle().fill(GymupColors.border).frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(GymupTypography.label)
            .foregroundStyle(GymupColors.secondaryText)
            .frame(height: 13)
    }
}

#Preview {
    NavigationStack {
        LevelView(onNavigationStateChanged: { _ in })
    }
    .preferredColorScheme(.dark)
}
