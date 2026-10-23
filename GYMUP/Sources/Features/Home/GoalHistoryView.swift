import SwiftUI

struct GoalHistoryView: View {
    var onCreateGoal: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GoalHistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            GymupDetailNavigationBar(
                title: "목표 히스토리",
                onBack: dismiss.callAsFunction,
                actionTitle: "새 목표",
                onAction: onCreateGoal
            )
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    currentGoal
                    Text("완료한 목표")
                        .font(GymupTypography.label)
                        .foregroundStyle(GymupColors.secondaryText)
                        .frame(height: 13)
                    completedGoals
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var currentGoal: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("진행 중")
                    .font(GymupTypography.label)
                    .foregroundStyle(GymupColors.brandText)
                Spacer()
                Text("\(viewModel.currentWeek) / \(viewModel.totalWeeks)주")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .frame(height: 15)
            Text(viewModel.currentGoalTitle)
                .font(GymupTypography.sectionTitle)
                .foregroundStyle(GymupColors.primaryText)
                .frame(minHeight: 22)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(GymupColors.overlay)
                    Capsule()
                        .fill(GymupColors.accent)
                        .frame(width: geometry.size.width * viewModel.progress)
                }
            }
            .frame(height: 4)
            Text("Growth \(viewModel.growth) / 100")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(minHeight: 15)
        }
        .padding(16)
        .frame(height: 120)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(GymupColors.accent, lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }

    private var completedGoals: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.completedGoals) { goal in
                HStack(spacing: 12) {
                    Image(goal.stage.equipmentAssetName)
                        .resizable()
                        .frame(width: 80, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(GymupTypography.uiStrong)
                            .foregroundStyle(GymupColors.primaryText)
                            .frame(minHeight: 21)
                        Text(goal.period)
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                            .frame(minHeight: 15)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Text(goal.stage.rawValue)
                        .font(GymupTypography.label)
                        .foregroundStyle(goal.stage == .peak ? GymupColors.brandText : GymupColors.secondaryText)
                }
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(GymupColors.border).frame(height: 1)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview {
    NavigationStack { GoalHistoryView() }
        .preferredColorScheme(.dark)
}
