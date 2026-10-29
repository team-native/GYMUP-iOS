import SwiftUI

struct GrowthView: View {
    let onNavigationStateChanged: (Bool) -> Void
    let onOpenHistory: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var goalStore = GoalStore.shared
    private let historyStore: HistoryStore
    private let initialGoalSettings: OnboardingStoredSettings?
    private var viewModel: GrowthViewModel {
        GrowthViewModel(historyStore: historyStore,
                        goalSettings: goalStore.revision > 0 ? goalStore.settings : initialGoalSettings)
    }

    @MainActor
    init(
        onNavigationStateChanged: @escaping (Bool) -> Void,
        onOpenHistory: @escaping () -> Void,
        historyStore: HistoryStore? = nil,
        goalSettings: OnboardingStoredSettings? = .load()
    ) {
        self.onNavigationStateChanged = onNavigationStateChanged
        self.onOpenHistory = onOpenHistory
        self.historyStore = historyStore ?? HistoryStore()
        self.initialGoalSettings = goalSettings
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 19) {
                    score
                    goalDescription
                    progressBar
                    stages
                    growthFactors
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

    private var navigationBar: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
                Image("H2IconChevronLeft")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Growth")
                .font(GymupTypography.growthNavigationTitle)
                .foregroundStyle(GymupColors.primaryText)
            Spacer()
            Button(action: onOpenHistory) {
                Image("H2IconHistory")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("성장 기록")
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
    }

    private var score: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("\(viewModel.growth)")
                .font(GymupTypography.growthScore)
                .foregroundStyle(GymupColors.primaryText)
            Text("/100")
                .font(GymupTypography.growthScoreUnit)
                .foregroundStyle(Color.white.opacity(0.35))
        }
        .frame(height: 65, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Growth \(viewModel.growth) / 100")
        .accessibilityIdentifier("home.growth.score")
    }

    private var goalDescription: some View {
        Text("\(viewModel.goalTitle) · \(viewModel.goalDurationWeeks)주 중 \(viewModel.currentWeek)주차")
            .font(GymupTypography.uiMedium)
            .foregroundStyle(GymupColors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("home.growth.goal")
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(GymupColors.accent)
                    .frame(width: geometry.size.width * viewModel.progress)
            }
        }
        .frame(height: 6)
        .accessibilityLabel("성장 진행률 \(Int(viewModel.progress * 100))퍼센트")
    }

    private var stages: some View {
        VStack(spacing: 7) {
            ForEach(viewModel.stages) { stage in
                GrowthStageRow(stage: stage)
            }
        }
    }

    private var growthFactors: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(viewModel.growthFactors) { factor in
                HStack {
                    Text(factor.title)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Spacer(minLength: 4)
                    Text(factor.value)
                        .font(GymupTypography.growthFactorValue)
                        .foregroundStyle(Color(red: 1, green: 0.42, blue: 0.43))
                }
                .padding(.horizontal, 12)
                .frame(height: 37)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

private struct GrowthStageRow: View {
    let stage: GrowthStage

    private var textColor: Color {
        stage.isLocked ? Color.white.opacity(0.35) : GymupColors.primaryText
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(stage.equipmentAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(stage.title) · \(stage.weight)kg")
                        .font(GymupTypography.growthStageTitle)
                        .foregroundStyle(textColor)
                }
                Text(stage.growthRangeTitle)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(stage.isLocked ? Color.white.opacity(0.25) : GymupColors.secondaryText)
            }
            Spacer(minLength: 0)
            if stage.isCurrent {
                Text("현재")
                    .font(GymupTypography.growthStageBadge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(GymupColors.accent, in: Capsule())
            } else if stage.isLocked {
                Image("H2IconLock")
                    .resizable()
                    .frame(width: 16, height: 16)
            } else if !stage.isCurrent {
                Image("H2IconCheck")
                    .resizable()
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            stage.isCurrent ? Color(red: 0.23, green: 0.07, blue: 0.08) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}
