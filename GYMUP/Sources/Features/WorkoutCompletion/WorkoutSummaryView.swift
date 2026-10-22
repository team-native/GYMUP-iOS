import SwiftUI

struct WorkoutSummaryView: View {
    let data: WorkoutCompletionData
    let onPhoto: () -> Void
    let onContinue: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                WorkoutCompletionBarbellArtwork()
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(data.metrics) { metric in
                        WorkoutCompletionMetricTile(metric: metric)
                    }
                }
                growthCard
                xpAndWeeklyGoal
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "완료", action: onContinue),
                secondary: WorkoutCompletionSecondaryButton(title: "오운완 사진", action: onPhoto)
            )
        }
        .background(WorkoutCompletionColors.canvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("WORKOUT COMPLETE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(WorkoutCompletionColors.red)

            Text(data.routineName)
                .font(GymupTypography.title)
                .foregroundStyle(WorkoutCompletionColors.primaryText)

            Text(data.completedAt)
                .font(GymupTypography.caption)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }

    private var growthCard: some View {
        WorkoutCompletionCard {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("GROWTH")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    Text("\(data.previousGrowth) → \(data.growth)")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 8)

                Text("+\(data.growth - data.previousGrowth)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(WorkoutCompletionColors.red)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(WorkoutCompletionColors.red.opacity(0.14), in: Capsule())
                    .accessibilityLabel("성장도 \(data.growth - data.previousGrowth) 상승")
            }
        }
    }

    private var xpAndWeeklyGoal: some View {
        VStack(spacing: 10) {
            HStack {
                Label("\(data.earnedXP) XP", systemImage: "bolt.fill")
                    .font(GymupTypography.headline)
                    .foregroundStyle(WorkoutCompletionColors.gold)
                Spacer()
                Text("이번 주 목표")
                    .font(GymupTypography.caption)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                Text("\(data.weeklyWorkoutCount)/\(data.weeklyWorkoutGoal)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(WorkoutCompletionColors.primaryText)
            }

            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(WorkoutCompletionColors.red)
                Text("\(data.streakWeeks)주 연속 운동 중")
                    .font(GymupTypography.callout)
                    .foregroundStyle(WorkoutCompletionColors.primaryText)
                Spacer(minLength: 0)
                Text("목표 달성")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(WorkoutCompletionColors.red)
            }
            .padding(.top, 10)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(WorkoutCompletionColors.elevatedSurface)
                    .frame(height: 1)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 2)
    }
}
