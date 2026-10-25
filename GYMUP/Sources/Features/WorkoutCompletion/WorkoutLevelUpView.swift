import SwiftUI

struct WorkoutLevelUpView: View {
    let reward: WorkoutCompletionData.LevelReward
    let onViewItems: () -> Void
    let onContinue: () -> Void

    private var progress: Double {
        guard reward.nextLevelXP > 0 else { return 0 }
        return min(max(Double(reward.currentXP) / Double(reward.nextLevelXP), 0), 1)
    }

    private var nextLevel: Int {
        reward.level + 1
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    levelHeading

                    Spacer(minLength: 48)

                    VStack(alignment: .leading, spacing: 18) {
                        progressSection
                        rewardCard
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .frame(minHeight: geometry.size.height, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionArea
        }
        .background(WorkoutCompletionColors.canvas)
    }

    private var levelHeading: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LEVEL UP")
                .font(Font.custom("Archivo-SemiBold", size: 11, relativeTo: .caption))
                .tracking(1.5)
                .foregroundStyle(WorkoutCompletionColors.red)
                .padding(.bottom, 10)

            Text("\(reward.level)")
                .font(Font.custom("BarlowCondensed-Black", size: 112, relativeTo: .largeTitle))
                .foregroundStyle(WorkoutCompletionColors.red)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 2)

            Text("LV.\(reward.previousLevel) → LV.\(reward.level)")
                .font(Font.custom("Archivo-SemiBold", size: 19, relativeTo: .title2))
                .foregroundStyle(WorkoutCompletionColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityLabel("레벨 \(reward.previousLevel)에서 레벨 \(reward.level)로 올랐어요")
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("workout.completion.level-up.heading")
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                progressLabels

                VStack(alignment: .leading, spacing: 4) {
                    Text("LV.\(nextLevel)까지")
                    Text(experienceLabel)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WorkoutCompletionColors.elevatedSurface)

                    Capsule()
                        .fill(WorkoutCompletionColors.red)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 2)
            .accessibilityHidden(true)
        }
        .font(Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
        .foregroundStyle(WorkoutCompletionColors.secondaryText)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("다음 레벨까지 경험치")
        .accessibilityValue(experienceLabel)
        .accessibilityIdentifier("workout.completion.level-up.progress")
    }

    private var progressLabels: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("LV.\(nextLevel)까지")
            Spacer(minLength: 4)
            Text(experienceLabel)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var experienceLabel: String {
        "\(reward.currentXP.formatted()) / \(reward.nextLevelXP.formatted()) XP"
    }

    private var rewardCard: some View {
        WorkoutCompletionCard {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(WorkoutCompletionColors.red)
                    .frame(width: 44, height: 44)
                    .background(
                        WorkoutCompletionColors.red.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("레벨 보상")
                        .font(Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)

                    Text(reward.itemName)
                        .font(Font.custom("GothicA1-SemiBold", size: 16, relativeTo: .headline))
                        .foregroundStyle(WorkoutCompletionColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Text("NEW")
                    .font(Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption))
                    .tracking(0.8)
                    .foregroundStyle(WorkoutCompletionColors.red)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .overlay {
                        Capsule()
                            .strokeBorder(WorkoutCompletionColors.red.opacity(0.5), lineWidth: 1)
                    }
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("레벨 보상, \(reward.itemName), 새 아이템")
            .accessibilityIdentifier("workout.completion.level-up.reward")
        }
    }

    private var actionArea: some View {
        VStack(spacing: 2) {
            Button(action: onContinue) {
                Text("계속")
                    .font(Font.custom("GothicA1-SemiBold", size: 16, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        WorkoutCompletionColors.red,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.completion.level-up.continue")

            Button(action: onViewItems) {
                Text("아이템 보기")
                    .font(Font.custom("GothicA1-Medium", size: 12, relativeTo: .caption))
                    .foregroundStyle(WorkoutCompletionColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.completion.level-up.items")
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
