import SwiftUI

struct WorkoutLevelUpView: View {
    let reward: WorkoutCompletionData.LevelReward
    let onViewItems: () -> Void
    let onContinue: () -> Void

    private var progress: Double {
        Double(reward.currentXP) / Double(max(reward.nextLevelXP, 1))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                levelEmblem
                progressCard
                rewardCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "계속", action: onContinue),
                secondary: WorkoutCompletionSecondaryButton(title: "아이템 보기", action: onViewItems)
            )
        }
        .background(WorkoutCompletionColors.canvas)
    }

    private var header: some View {
        VStack(spacing: 7) {
            Text("LEVEL UP")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(WorkoutCompletionColors.red)
            Text("새로운 레벨에 도달했어요")
                .font(GymupTypography.body)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private var levelEmblem: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [WorkoutCompletionColors.red.opacity(0.24), WorkoutCompletionColors.red.opacity(0.02)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 220, height: 220)

            Circle()
                .strokeBorder(WorkoutCompletionColors.red.opacity(0.7), lineWidth: 1.5)
                .frame(width: 148, height: 148)
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.08), lineWidth: 8)
                        .padding(10)
                }

            VStack(spacing: 1) {
                Text("LV.")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                Text("\(reward.level)")
                    .font(.system(size: 62, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("레벨 업, 레벨 \(reward.level)")
    }

    private var progressCard: some View {
        WorkoutCompletionCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .firstTextBaseline) {
                    Text("LV.\(reward.previousLevel) → LV.\(reward.level)")
                        .font(GymupTypography.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("NEXT LEVEL")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                }

                WorkoutCompletionProgressBar(value: progress)

                HStack {
                    Text("\(reward.currentXP.formatted()) XP")
                    Spacer()
                    Text("\(reward.nextLevelXP.formatted()) XP")
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var rewardCard: some View {
        WorkoutCompletionCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(WorkoutCompletionColors.gold.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(WorkoutCompletionColors.gold)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("LEVEL REWARD")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    Text(reward.itemName)
                        .font(GymupTypography.headline)
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 8)

                Text("NEW")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(WorkoutCompletionColors.gold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .overlay(Capsule().strokeBorder(WorkoutCompletionColors.gold.opacity(0.5), lineWidth: 1))
            }
        }
    }
}
