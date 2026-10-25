import SwiftUI

struct WorkoutSummaryView: View {
    let data: WorkoutCompletionData
    let onPhoto: () -> Void
    var showsPhotoAction = true
    let onContinue: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                WorkoutCompletionHero(routineName: data.routineName, completedAt: data.completedAt)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(data.metrics) { metric in
                        WorkoutCompletionMetricTile(metric: metric)
                    }
                }
                .padding(.horizontal, 20)

                growthCard
                    .padding(.horizontal, 20)

                experienceCard
                    .padding(.horizontal, 20)

                weeklyGoalBanner
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsPhotoAction {
                WorkoutCompletionActionBar(
                    primary: WorkoutCompletionPrimaryButton(title: "완료", action: onContinue),
                    secondary: WorkoutCompletionSecondaryButton(title: "오운완 사진", action: onPhoto)
                )
            } else {
                WorkoutCompletionPrimaryButton(title: "완료", action: onContinue)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(WorkoutCompletionColors.canvas.ignoresSafeArea(edges: .bottom))
            }
        }
        .background(WorkoutCompletionColors.canvas)
    }

    private var growthCard: some View {
        WorkoutCompletionCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("GROWTH")
                        .font(Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption))
                        .tracking(1.2)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)

                    Text("\(data.previousGrowth) → \(data.growth)")
                        .font(Font.custom("BarlowCondensed-ExtraBold", size: 18, relativeTo: .title3))
                        .foregroundStyle(WorkoutCompletionColors.primaryText)
                        .contentTransition(.numericText())

                    Spacer(minLength: 8)

                    Text("+\(data.growth - data.previousGrowth)")
                        .font(Font.custom("Archivo-SemiBold", size: 12, relativeTo: .caption))
                        .foregroundStyle(WorkoutCompletionColors.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(WorkoutCompletionColors.red.opacity(0.14), in: Capsule())
                }

                WorkoutCompletionProgressBar(value: Double(data.growth) / 100)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("성장도 \(data.previousGrowth)에서 \(data.growth), \(data.growth - data.previousGrowth) 상승")
        }
    }

    private var experienceCard: some View {
        WorkoutCompletionCard {
            VStack(spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                        .accessibilityHidden(true)

                    Text("+\(data.earnedXP) XP")
                        .font(Font.custom("GothicA1-Bold", size: 14, relativeTo: .headline))

                    Spacer(minLength: 8)

                    if let reward = data.levelReward {
                        Text("LV.\(reward.previousLevel) → \(reward.level)")
                            .font(Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption))
                            .foregroundStyle(WorkoutCompletionColors.secondaryText)
                            .accessibilityLabel("레벨 \(reward.previousLevel)에서 \(reward.level)로 상승")
                    }
                }
                .foregroundStyle(WorkoutCompletionColors.gold)

                Rectangle()
                    .fill(WorkoutCompletionColors.elevatedSurface)
                    .frame(height: 1)
                    .accessibilityHidden(true)

                ForEach(experienceItems) { item in
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
                            .foregroundStyle(WorkoutCompletionColors.secondaryText)

                        Spacer(minLength: 8)

                        Text("+\(item.amount)")
                            .font(Font.custom("Archivo-SemiBold", size: 11, relativeTo: .caption))
                            .foregroundStyle(WorkoutCompletionColors.primaryText)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var experienceItems: [WorkoutCompletionExperienceItem] {
        if data.experienceBreakdown.isEmpty, data.earnedXP > 0 {
            return [WorkoutCompletionExperienceItem(title: "운동 완료", amount: data.earnedXP)]
        }
        return data.experienceBreakdown
    }

    private var weeklyGoalBanner: some View {
        let isGoalComplete = data.weeklyWorkoutCount >= data.weeklyWorkoutGoal
        let goalText = isGoalComplete ? "주간 목표 \(data.weeklyWorkoutCount)/\(data.weeklyWorkoutGoal) 달성" :
            "주간 목표 \(data.weeklyWorkoutCount)/\(data.weeklyWorkoutGoal)"

        return HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WorkoutCompletionColors.red)
                .accessibilityHidden(true)

            Text("\(goalText) · \(data.streakWeeks)주 연속 Streak")
                .font(Font.custom("GothicA1-SemiBold", size: 11, relativeTo: .caption))
                .foregroundStyle(WorkoutCompletionColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(WorkoutCompletionColors.red.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
