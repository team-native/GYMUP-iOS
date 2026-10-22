import SwiftUI

struct WorkoutStageUpView: View {
    let reward: WorkoutCompletionData.StageReward
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                header
                barbell
                weightTransition
                stageCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "계속", action: onContinue),
                secondary: EmptyView()
            )
        }
        .background(WorkoutCompletionColors.canvas)
    }

    private var header: some View {
        VStack(spacing: 7) {
            Text("STAGE UP")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(WorkoutCompletionColors.red)
            Text("원판이 추가됐어요")
                .font(GymupTypography.title)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var barbell: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                plateStack
                Capsule()
                    .fill(Color(red: 0.72, green: 0.73, blue: 0.76))
                    .frame(maxWidth: .infinity, minHeight: 7, maxHeight: 7)
                plateStack
            }
            .padding(.horizontal, 34)
            .shadow(color: WorkoutCompletionColors.red.opacity(0.2), radius: 22)

            Text("+\(reward.plateWeight) KG")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(WorkoutCompletionColors.red)
                .padding(.top, 15)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 170)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [WorkoutCompletionColors.red.opacity(0.12), WorkoutCompletionColors.surface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("양쪽 바벨에 빨간색 \(reward.plateWeight)킬로 원판이 추가됐어요")
    }

    private var plateStack: some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 5)
                .fill(WorkoutCompletionColors.red)
                .frame(width: 22, height: 82)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.69, green: 0.08, blue: 0.11))
                .frame(width: 13, height: 68)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.43, green: 0.43, blue: 0.46))
                .frame(width: 8, height: 51)
        }
    }

    private var weightTransition: some View {
        HStack(alignment: .center, spacing: 15) {
            weightValue(reward.previousWeight, label: "BEFORE", muted: true)
            Image(systemName: "arrow.right")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(WorkoutCompletionColors.red)
                .accessibilityHidden(true)
            weightValue(reward.weight, label: "NOW", muted: false)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func weightValue(_ value: Int, label: String, muted: Bool) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(WorkoutCompletionColors.secondaryText)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("KG")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(muted ? WorkoutCompletionColors.secondaryText : WorkoutCompletionColors.primaryText)
        }
    }

    private var stageCard: some View {
        WorkoutCompletionCard {
            HStack(spacing: 11) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(WorkoutCompletionColors.red)
                    .frame(width: 42, height: 42)
                    .background(WorkoutCompletionColors.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("STAGE \(reward.stage)")
                        .font(GymupTypography.headline)
                        .foregroundStyle(.white)
                    Text("HEAVY · \(reward.plateWeight) KG 레드 원판 적용")
                        .font(GymupTypography.caption)
                        .foregroundStyle(WorkoutCompletionColors.secondaryText)
                }

                Spacer(minLength: 0)

                Circle()
                    .fill(WorkoutCompletionColors.red)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
    }
}
