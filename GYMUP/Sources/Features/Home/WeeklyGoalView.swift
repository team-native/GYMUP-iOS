import SwiftUI

struct WeeklyGoalView: View {
    let onNavigationStateChanged: (Bool) -> Void
    var onChangeGoal: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = WeeklyGoalViewModel()

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
                    Text("이번 주 목표까지 \(viewModel.remainingWorkouts)회 남았어요")
                        .font(GymupTypography.uiMedium)
                        .foregroundStyle(GymupColors.secondaryText)
                    weekdayProgress
                    streakSummary
                    historyChart
                    Text("4주차는 목표 미달로 Streak가 초기화됐어요. 쉬는 날은 실패로 계산되지 않아요.")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
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
            Text("\(viewModel.completedWorkouts)")
                .font(GymupTypography.score)
                .tracking(-0.57)
                .foregroundStyle(GymupColors.primaryText)
            Text("/ \(viewModel.weeklyGoal) 회")
                .font(GymupTypography.metric)
                .foregroundStyle(GymupColors.tertiaryText)
        }
        .frame(height: 55, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var weekdayProgress: some View {
        HStack(spacing: 6) {
            ForEach(Array(viewModel.weekdays.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(weekdayColor(at: index))
                        if index == viewModel.currentWeekday {
                            Circle().strokeBorder(GymupColors.accent, lineWidth: 1.23)
                        }
                        if viewModel.completedWeekdays.contains(index) {
                            Image("H3IconCheck")
                                .resizable()
                                .frame(width: 13.12, height: 13.12)
                        }
                    }
                    .frame(width: 29.52, height: 29.52)
                    Text(day)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(index == viewModel.currentWeekday ? GymupColors.brandText : GymupColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("월요일과 수요일 운동 완료, 토요일")
    }

    private var streakSummary: some View {
        HStack(spacing: 8) {
            Image("H3IconFlame")
                .resizable()
                .frame(width: 22, height: 22)
            Text("\(viewModel.streakWeeks)주 연속 달성")
                .font(GymupTypography.sectionTitle)
                .foregroundStyle(GymupColors.primaryText)
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
                        .frame(width: 20, height: bar.isMissedGoal ? 12 : (bar.week < 4 ? 40 : 56))
                    Text("\(bar.week)")
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.tertiaryText)
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
            ForEach(viewModel.workouts) { workout in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.title)
                            .font(GymupTypography.uiStrong)
                            .foregroundStyle(GymupColors.primaryText)
                        Text("\(workout.date) · \(workout.duration)")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
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
        if viewModel.completedWeekdays.contains(index) { return GymupColors.accent }
        return index == viewModel.currentWeekday ? .clear : GymupColors.elevatedSurface
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
