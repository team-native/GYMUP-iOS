import SwiftUI

struct ProfileGoalHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    var historyStore: HistoryStore = HistoryStore()
    @State private var goalStore = GoalStore.shared
    private var goals: [ProfileGoalRecord] { goalStore.goals(historyStore: historyStore) }
    @State private var isCreationPresented = false

    private var currentGoal: ProfileGoalRecord? {
        goals.first(where: \.isCurrent)
    }

    private var completedGoals: [ProfileGoalRecord] {
        goals.filter { !$0.isCurrent }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                if let currentGoal {
                    currentGoalCard(currentGoal)
                }

                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    sectionTitle("완료한 목표")
                    VStack(spacing: 0) {
                        ForEach(completedGoals) { goal in
                            completedGoalRow(goal)
                            if goal.id != completedGoals.last?.id {
                                Rectangle()
                                    .fill(GymupColors.border)
                                    .frame(height: 1)
                                    .padding(.leading, GymupSpacing.large)
                            }
                        }
                    }
                    .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
                }
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.medium)
            .padding(.bottom, GymupSpacing.xxLarge)
        }
        .background(GymupColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            GymupDetailNavigationBar(
                title: "목표 히스토리",
                onBack: { dismiss() },
                actionTitle: "새 목표",
                onAction: { isCreationPresented = true }
            )
            .background(GymupColors.canvas)
        }
        .navigationDestination(isPresented: $isCreationPresented) {
            ProfileGoalCreationView(workoutsPerWeek: goalStore.settings?.frequency ?? 3) { newGoal in
                goalStore.start(newGoal, historyStore: historyStore)
                isCreationPresented = false
            }
        }
    }

    private func currentGoalCard(_ goal: ProfileGoalRecord) -> some View {
        VStack(alignment: .leading, spacing: GymupSpacing.large) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text("진행 중")
                        .font(GymupTypography.label)
                        .foregroundStyle(GymupColors.brandText)
                    Text("\(goal.type.rawValue) · 주 \(goal.workoutsPerWeek)회")
                        .font(GymupTypography.sectionTitle)
                        .foregroundStyle(GymupColors.primaryText)
                }
                Spacer(minLength: GymupSpacing.small)
                Text("\(goal.completedWeeks)/\(goal.durationWeeks)주")
                    .font(GymupTypography.metric)
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityLabel("\(goal.durationWeeks)주 중 \(goal.completedWeeks)주 완료")
            }

            VStack(alignment: .leading, spacing: GymupSpacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Growth")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.secondaryText)
                    Spacer()
                    Text("\(goal.growth)/100")
                        .font(GymupTypography.metric)
                        .foregroundStyle(GymupColors.brandText)
                }
                ProgressView(value: Double(goal.growth), total: 100)
                    .tint(GymupColors.accent)
                    .accessibilityLabel("Growth 진행률 \(goal.growth)퍼센트")
            }
        }
        .padding(GymupSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
        .accessibilityElement(children: .contain)
    }

    private func completedGoalRow(_ goal: ProfileGoalRecord) -> some View {
        HStack(spacing: GymupSpacing.medium) {
            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text("\(goal.type.rawValue) · 주 \(goal.workoutsPerWeek)회")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                Text("\(goal.period) · \(goal.durationWeeks)주")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let badge = goal.badge {
                Text(badge)
                    .font(GymupTypography.label)
                    .foregroundStyle(badge == "PEAK" ? Color(red: 1, green: 0.78, blue: 0.3) : GymupColors.brandText)
                    .padding(.horizontal, GymupSpacing.small)
                    .padding(.vertical, GymupSpacing.xSmall)
                    .background(GymupColors.elevatedSurface, in: Capsule())
                    .accessibilityLabel("\(badge) 단계")
            }
        }
        .padding(.horizontal, GymupSpacing.large)
        .padding(.vertical, GymupSpacing.medium)
        .frame(minHeight: 68)
        .accessibilityElement(children: .combine)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(GymupTypography.label)
            .foregroundStyle(GymupColors.secondaryText)
            .frame(minHeight: 20, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    NavigationStack {
        ProfileGoalHistoryView()
            .preferredColorScheme(.dark)
    }
}
