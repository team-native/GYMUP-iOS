import SwiftUI

struct WeeklyGoalView: View {
    let onNavigationStateChanged: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = WeeklyGoalViewModel()

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    weeklyScore
                    weekdayProgress
                    streakSummary
                    historyChart
                    workouts
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
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
            Text("이번 주")
                .font(GymupTypography.growthNavigationTitle)
                .foregroundStyle(GymupColors.primaryText)
            Spacer()
            Button {} label: {
                Text("변경")
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .disabled(true)
            .accessibilityLabel("주간 목표 변경, 준비 중")
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
    }

    private var weeklyScore: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(viewModel.completedWorkouts)")
                    .font(GymupTypography.growthScore)
                    .foregroundStyle(GymupColors.primaryText)
                Text("/ \(viewModel.weeklyGoal) 회")
                    .font(GymupTypography.growthScoreUnit)
                    .foregroundStyle(Color.white.opacity(0.45))
            }
            Text("이번 주 목표까지 \(viewModel.remainingWorkouts)회 남았어요")
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }

    private var weekdayProgress: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.weekdays.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 10) {
                    Text(day)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                    ZStack {
                        Circle()
                            .strokeBorder(index == viewModel.currentWeekday ? GymupColors.accent : Color.white.opacity(0.14), lineWidth: 1)
                            .background(Circle().fill(viewModel.completedWeekdays.contains(index) ? GymupColors.accent : Color.clear))
                        if viewModel.completedWeekdays.contains(index) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 30, height: 30)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("월요일과 수요일 운동 완료, 토요일")
    }

    private var streakSummary: some View {
        HStack(spacing: 10) {
            Image("H1IconFlame")
                .resizable()
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(viewModel.streakWeeks)주 연속 달성")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(GymupColors.primaryText)
                Text("최장 \(viewModel.longestStreakWeeks)주")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            Spacer()
        }
        .padding(14)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom, spacing: 7) {
                ForEach(viewModel.progressBars) { bar in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(historyBarColor(for: bar))
                            .frame(maxWidth: .infinity)
                            .frame(height: bar.isMissedGoal ? 12 : (bar.week < 4 ? 40 : 56))
                        Text("\(bar.week)")
                            .font(.custom("Archivo-SemiBold", size: 9))
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Text("4주차는 목표 미달로 Streak가 초기화됐어요. 쉬는 날은 실패로 계산되지 않아요.")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .lineSpacing(4)
        }
        .padding(14)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func historyBarColor(for bar: WeeklyProgressBar) -> Color {
        if bar.isMissedGoal {
            return GymupColors.accent.opacity(0.45)
        }
        return bar.week < 4 ? Color.white.opacity(0.16) : GymupColors.accent
    }

    private var workouts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이번 주 운동")
                .font(GymupTypography.uiBold)
                .foregroundStyle(GymupColors.primaryText)
            ForEach(viewModel.workouts) { workout in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(workout.title)
                            .font(GymupTypography.uiMedium)
                            .foregroundStyle(GymupColors.primaryText)
                        Text("\(workout.date) · \(workout.duration)")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    Spacer()
                    Text(workout.volume)
                        .font(GymupTypography.uiCaption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Image("H1IconChevronRight")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .padding(.horizontal, 14)
                .frame(height: 64)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
