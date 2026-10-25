import SwiftUI

struct WorkoutPeakUnlockView: View {
    let reward: WorkoutCompletionData.PeakReward
    let onFinish: () -> Void
    let onCreateGoal: () -> Void
    let onGoalHistory: () -> Void
    var showsGoalActions = true

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                completionHeading
                    .padding(.bottom, 20)

                barbell
                    .padding(.bottom, 18)

                summaryStats
                    .padding(.bottom, 12)

                rewardBanner
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionArea
        }
        .background(WorkoutCompletionColors.canvas)
        .accessibilityIdentifier("workout.completion.peak-unlock")
    }

    private var completionHeading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PHYSIQUE COMPLETE · GROWTH \(reward.goalGrowth)")
                .font(Font.custom("Archivo-SemiBold", size: 11, relativeTo: .caption))
                .tracking(0.8)
                .foregroundStyle(WorkoutCompletionColors.red)
                .fixedSize(horizontal: false, vertical: true)

            Text("PEAK\nUNLOCKED")
                .font(Font.custom("BarlowCondensed-Black", size: 38, relativeTo: .largeTitle))
                .foregroundStyle(WorkoutCompletionColors.primaryText)
                .lineSpacing(-5)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("workout.completion.peak-unlock.heading")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("피지크 완료, 성장 \(reward.goalGrowth), Peak 단계 해금")
    }

    private var barbell: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                plateStack(isLeading: true)

                Capsule()
                    .fill(Color(red: 0.72, green: 0.73, blue: 0.76))
                    .frame(maxWidth: .infinity)
                    .frame(height: 6)

                plateStack(isLeading: false)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)

            Text("\(reward.fullyLoadedWeight.formatted()) KG · FULLY LOADED")
                .font(Font.custom("Archivo-SemiBold", size: 11, relativeTo: .caption))
                .tracking(0.7)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("완전히 장착된 바벨, \(reward.fullyLoadedWeight)킬로그램")
        .accessibilityIdentifier("workout.completion.peak-unlock.barbell")
    }

    private func plateStack(isLeading: Bool) -> some View {
        HStack(spacing: 2) {
            if isLeading {
                plate(color: Color(red: 0.38, green: 0.38, blue: 0.41), width: 7, height: 42)
                plate(color: Color(red: 0.55, green: 0.55, blue: 0.58), width: 8, height: 58)
                plate(color: WorkoutCompletionColors.red.opacity(0.82), width: 10, height: 70)
                plate(color: WorkoutCompletionColors.red, width: 11, height: 82)
            } else {
                plate(color: WorkoutCompletionColors.red, width: 11, height: 82)
                plate(color: WorkoutCompletionColors.red.opacity(0.82), width: 10, height: 70)
                plate(color: Color(red: 0.55, green: 0.55, blue: 0.58), width: 8, height: 58)
                plate(color: Color(red: 0.38, green: 0.38, blue: 0.41), width: 7, height: 42)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityHidden(true)
    }

    private func plate(color: Color, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: width, height: height)
    }

    @ViewBuilder
    private var summaryStats: some View {
        let stats = [
            PeakStat(value: "\(reward.durationWeeks)주", title: "기간"),
            PeakStat(value: "\(reward.workoutCount)회", title: "총 운동"),
            PeakStat(value: "\(reward.longestStreakWeeks)주", title: "최장 Streak")
        ]

        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 8) {
                ForEach(stats) { stat in
                    statCard(stat)
                }
            }
        } else {
            HStack(spacing: 8) {
                ForEach(stats) { stat in
                    statCard(stat)
                }
            }
        }
    }

    private func statCard(_ stat: PeakStat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(stat.value)
                .font(Font.custom("BarlowCondensed-ExtraBold", size: 20, relativeTo: .title3))
                .monospacedDigit()
                .foregroundStyle(WorkoutCompletionColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(stat.title)
                .font(Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(WorkoutCompletionColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stat.title), \(stat.value)")
        .accessibilityIdentifier("workout.completion.peak-unlock.stat.\(stat.id)")
    }

    private var rewardBanner: some View {
        HStack(spacing: 9) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WorkoutCompletionColors.red)
                .accessibilityHidden(true)

            Text("보상 · 챔피언 바 + \(reward.rewardXP.formatted()) XP")
                .font(Font.custom("GothicA1-SemiBold", size: 11, relativeTo: .subheadline))
                .foregroundStyle(WorkoutCompletionColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(WorkoutCompletionColors.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 13))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Peak 보상, 챔피언 바와 경험치 \(reward.rewardXP)")
        .accessibilityIdentifier("workout.completion.peak-unlock.reward")
    }

    @ViewBuilder
    private var actionArea: some View {
        VStack(spacing: 2) {
            if showsGoalActions {
                WorkoutCompletionPrimaryButton(title: "새 목표 설정하기", action: onCreateGoal)
                    .accessibilityIdentifier("workout.completion.peak-unlock.create-goal")

                Button(action: onGoalHistory) {
                    Text("목표 히스토리")
                        .font(Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("완료한 목표 기록을 확인합니다.")
                .accessibilityIdentifier("workout.completion.peak-unlock.goal-history")
            } else {
                WorkoutCompletionPrimaryButton(title: "운동 완료", action: onFinish)
                    .accessibilityIdentifier("workout.completion.finish")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background {
            WorkoutCompletionColors.canvas
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

private struct PeakStat: Identifiable {
    let value: String
    let title: String

    var id: String { title }
}
