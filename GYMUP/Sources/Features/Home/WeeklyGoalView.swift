import SwiftUI

struct WeeklyGoalView: View {
    let onNavigationStateChanged: (Bool) -> Void
    var onChangeGoal: (() -> Void)?
    var goal: Int = 3
    var records: [WorkoutRecord]?
    @Environment(\.dismiss) private var dismiss
    private var viewModel: WeeklyGoalViewModel { WeeklyGoalViewModel(records: records ?? [], goal: goal) }

    private var completedWorkouts: Int { viewModel.completedWorkouts }
    private var completedWeekdays: Set<Int> { viewModel.completedWeekdays }
    private var currentWeekday: Int { viewModel.currentWeekday }

    var body: some View {
        VStack(spacing: 0) {
            GymupDetailNavigationBar(
                title: "이번 주",
                onBack: dismiss.callAsFunction,
                actionTitle: "변경",
                onAction: onChangeGoal
            )
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    weeklyScore
                    Text("이번 주 목표까지 \(max(goal - completedWorkouts, 0))회 남았어요")
                        .font(GymupTypography.uiMedium)
                        .foregroundStyle(GymupColors.secondaryText)
                        .frame(minHeight: 19)
                    weekdayProgress
                    streakSummary
                    historyChart
                    Text("최근 12주 기록이에요. 이번 주 목표를 채우면 연속 달성에 포함돼요.")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .lineSpacing(4)
                    workouts
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { onNavigationStateChanged(true) }
        .onDisappear { onNavigationStateChanged(false) }
    }

    private var weeklyScore: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(completedWorkouts)")
                .font(GymupTypography.score)
                .tracking(-0.57)
                .foregroundStyle(GymupColors.primaryText)
            Text("/ \(goal) 회")
                .font(GymupTypography.metric)
                .foregroundStyle(GymupColors.tertiaryText)
        }
        .frame(height: 55, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var weekdayAccessibilityLabel: String {
        let completed = completedWeekdays.sorted().map { viewModel.weekdays[$0] + "요일" }.joined(separator: ", ")
        let summary = completed.isEmpty ? "이번 주 운동 기록 없음" : "\(completed) 운동 완료"
        return "\(summary), 오늘 \(viewModel.weekdays[currentWeekday])요일"
    }

    private var weekdayProgress: some View {
        HStack(spacing: 6) {
            ForEach(Array(viewModel.weekdays.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(weekdayColor(at: index))
                        if index == currentWeekday {
                            Circle().strokeBorder(GymupColors.accent, lineWidth: 1.23)
                        }
                        if completedWeekdays.contains(index) {
                            Image("H3IconCheck")
                                .resizable()
                                .frame(width: 13.12, height: 13.12)
                        }
                    }
                    .frame(width: 29.52, height: 29.52)
                    Text(day)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(index == currentWeekday ? GymupColors.brandText : GymupColors.secondaryText)
                        .frame(height: 15)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(weekdayAccessibilityLabel)
    }

    private var streakSummary: some View {
        HStack(spacing: 8) {
            Image("H3IconFlame")
                .resizable()
                .frame(width: 22, height: 22)
            Text("\(viewModel.streakWeeks)주 연속 달성")
                .font(GymupTypography.sectionTitle)
                .foregroundStyle(GymupColors.primaryText)
                .frame(minHeight: 22)
            Spacer()
            Text("최장 \(viewModel.longestStreakWeeks)주")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
        }
        .padding(.top, 12)
    }

    private var historyChart: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(viewModel.progressBars) { bar in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(historyBarColor(for: bar))
                        .frame(width: 20, height: bar.isMissedGoal ? 12 : CGFloat(max(4, min(bar.workoutCount * 12, 72))))
                    Text("\(bar.week)")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.tertiaryText)
                        .frame(height: 15)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(bar.week)주차, \(bar.isMissedGoal ? "목표 미달" : "운동 기록")")
            }
        }
    }

    private var workouts: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("이번 주 운동")
                .font(GymupTypography.label)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(height: 13)
            ForEach(viewModel.workouts) { workout in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.title)
                            .font(GymupTypography.uiStrong)
                            .foregroundStyle(GymupColors.primaryText)
                            .frame(minHeight: 21)
                        Text("\(workout.date) · \(workout.duration)")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                            .frame(minHeight: 15)
                    }
                    Spacer()
                    Text(workout.volume)
                        .font(GymupTypography.uiMedium)
                        .foregroundStyle(GymupColors.secondaryText)
                    Image("H3IconChevronRight")
                        .resizable()
                        .frame(width: 18, height: 18)
                }
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(GymupColors.border).frame(height: 1)
                }
            }
        }
    }

    private func weekdayColor(at index: Int) -> Color {
        if completedWeekdays.contains(index) { return GymupColors.accent }
        return index == currentWeekday ? .clear : GymupColors.elevatedSurface
    }

    private func historyBarColor(for bar: WeeklyProgressBar) -> Color {
        if bar.isMissedGoal { return GymupColors.critical }
        return bar.week < 4 ? GymupColors.overlay : GymupColors.accent
    }
}

#Preview {
    NavigationStack {
        WeeklyGoalView(onNavigationStateChanged: { _ in })
    }
    .preferredColorScheme(.dark)
}
