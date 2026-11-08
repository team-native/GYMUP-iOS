import SwiftUI

struct LevelView: View {
    let onNavigationStateChanged: (Bool) -> Void
    @Bindable private var viewModel: LevelViewModel
    @Environment(\.dismiss) private var dismiss

    init(onNavigationStateChanged: @escaping (Bool) -> Void, viewModel: LevelViewModel) {
        self.onNavigationStateChanged = onNavigationStateChanged
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            GymupDetailNavigationBar(title: "레벨", onBack: dismiss.callAsFunction)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 19) {
                    serverRequestStatus
                    Text("LEVEL")
                        .font(GymupTypography.label)
                        .foregroundStyle(GymupColors.brandText)
                        .frame(height: 13)
                    Text(viewModel.level.map { String($0) } ?? "—")
                        .font(GymupTypography.score)
                        .tracking(-0.57)
                        .foregroundStyle(GymupColors.primaryText)
                        .frame(height: 55)
                    experienceSummary
                    experienceProgress
                    if let lastLevelUpDateText = viewModel.lastLevelUpDateText {
                        HStack {
                            Text("마지막 레벨업")
                                .foregroundStyle(GymupColors.secondaryText)
                            Spacer(minLength: 8)
                            Text(lastLevelUpDateText)
                                .foregroundStyle(GymupColors.primaryText)
                        }
                        .font(GymupTypography.uiCaption)
                    }
                    if viewModel.showsLocalSampleDetails {
                        nextReward
                        sectionLabel("XP 기준")
                        experienceFactors
                        sectionLabel("최근 획득")
                        recentExperience
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.loadIfNeeded() }
        .onAppear { onNavigationStateChanged(true) }
        .onDisappear { onNavigationStateChanged(false) }
    }

    @ViewBuilder
    private var serverRequestStatus: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(GymupColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("레벨 정보를 불러오는 중")
        } else if let errorMessage = viewModel.errorMessage {
            VStack(alignment: .leading, spacing: 8) {
                Text(errorMessage)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
                Button("다시 시도") {
                    Task { await viewModel.retry() }
                }
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
                .accessibilityIdentifier("home.level.retry")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var experienceSummary: some View {
        HStack {
            Text(xpSummary)
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)
            Spacer(minLength: 4)
            Text(remainingExperienceSummary)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
        }
        .frame(minHeight: 21)
    }

    private var experienceProgress: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(GymupColors.overlay)
                if let progress = viewModel.progress {
                    Capsule()
                        .fill(GymupColors.accent)
                        .frame(width: geometry.size.width * progress)
                }
            }
        }
        .frame(height: 6)
        .accessibilityLabel(progressAccessibilityLabel)
    }

    private var nextReward: some View {
        HStack(spacing: 12) {
            Image("H4IconTrophy")
                .resizable()
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.level.map { "LV.\($0 + 1) 보상" } ?? "다음 레벨 보상")
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

    private var xpSummary: String {
        guard let experience = viewModel.experience,
              let targetExperience = viewModel.targetExperience else { return "— / — XP" }
        return "\(experience.formatted()) / \(targetExperience.formatted()) XP"
    }

    private var remainingExperienceSummary: String {
        guard let level = viewModel.level,
              let remainingExperience = viewModel.remainingExperience else { return "—" }
        return "LV.\(level + 1)까지 \(remainingExperience)"
    }

    private var progressAccessibilityLabel: String {
        guard let progress = viewModel.progress else { return "레벨 진행률 정보 없음" }
        return "다음 레벨 진행률 \(Int(progress * 100))퍼센트"
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
        LevelView(onNavigationStateChanged: { _ in }, viewModel: LevelViewModel())
    }
    .preferredColorScheme(.dark)
}
