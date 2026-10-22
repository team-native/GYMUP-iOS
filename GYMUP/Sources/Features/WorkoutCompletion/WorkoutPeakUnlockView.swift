import SwiftUI

struct WorkoutPeakUnlockView: View {
    let reward: WorkoutCompletionData.PeakReward
    let onCreateGoal: () -> Void
    let onGoalHistory: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                peakEmblem
                Text("PEAK UNLOCKED")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(WorkoutCompletionColors.gold)
                    .frame(maxWidth: .infinity)
                Text("\(reward.fullyLoadedWeight) KG · FULLY LOADED")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .frame(maxWidth: .infinity)

                LazyVGrid(columns: columns, spacing: 9) {
                    statTile(value: "\(reward.durationWeeks)주", title: "목표 기간")
                    statTile(value: "\(reward.workoutCount)회", title: "총 운동")
                    statTile(value: "\(reward.longestStreakWeeks)주", title: "최장 Streak")
                    statTile(value: "\(reward.goalGrowth)", title: "GROWTH")
                }

                rewardCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "새 목표 설정하기", action: onCreateGoal),
                secondary: WorkoutCompletionSecondaryButton(title: "목표 히스토리", action: onGoalHistory)
            )
        }
        .background(WorkoutCompletionColors.canvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("PHYSIQUE COMPLETE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("GROWTH")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                Text("\(reward.goalGrowth)")
                    .font(.system(size: 33, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("/ 100")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var peakEmblem: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [WorkoutCompletionColors.gold.opacity(0.2), WorkoutCompletionColors.gold.opacity(0.01)],
                        center: .center,
                        startRadius: 6,
                        endRadius: 105
                    )
                )
            Circle()
                .strokeBorder(WorkoutCompletionColors.gold.opacity(0.7), lineWidth: 1.5)
                .padding(24)
            Circle()
                .strokeBorder(WorkoutCompletionColors.gold.opacity(0.2), lineWidth: 1)
                .padding(37)
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 28, weight: .semibold))
                Text("PEAK")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(2.4)
            }
            .foregroundStyle(WorkoutCompletionColors.gold)
        }
        .frame(height: 190)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Peak 단계 해금")
    }

    private func statTile(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(GymupTypography.caption)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(WorkoutCompletionColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private var rewardCard: some View {
        WorkoutCompletionCard {
            HStack(spacing: 12) {
                Image(systemName: "medal.fill")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(WorkoutCompletionColors.gold)
                    .frame(width: 48, height: 48)
                    .background(WorkoutCompletionColors.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PEAK REWARD")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    Text("챔피언 바")
                        .font(GymupTypography.headline)
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 4)

                Text("+\(reward.rewardXP.formatted()) XP")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(WorkoutCompletionColors.gold)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}
