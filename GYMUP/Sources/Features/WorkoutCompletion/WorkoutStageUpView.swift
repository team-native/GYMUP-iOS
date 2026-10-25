import SwiftUI

struct WorkoutStageUpView: View {
    let reward: WorkoutCompletionData.StageReward
    let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, topPadding)

                Color.clear
                    .frame(height: headerToPreviousBarbellSpacing)
                    .accessibilityHidden(true)

                previousBarbell
                    .padding(.bottom, previousToUpdatedSpacing)

                updatedBarbell
                    .padding(.bottom, updatedToWeightSpacing)

                weightTransition
                    .padding(.bottom, 8)

                stageDescription
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WorkoutCompletionActionBar(
                primary: WorkoutCompletionPrimaryButton(title: "계속", action: onContinue)
                    .accessibilityIdentifier("workout.completion.stage-up.continue"),
                secondary: EmptyView()
            )
        }
        .background(WorkoutCompletionColors.canvas)
        .accessibilityIdentifier("workout.completion.stage-up")
    }

    private var topPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 28 : 70
    }

    private var headerToPreviousBarbellSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 48 : 104
    }

    private var previousToUpdatedSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 56 : 102
    }

    private var updatedToWeightSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 40 : 82
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("STAGE UP")
                .font(Font.custom("Archivo-SemiBold", size: 11, relativeTo: .caption))
                .tracking(1.5)
                .foregroundStyle(WorkoutCompletionColors.red)

            Text("원판이 추가됐어요")
                .font(Font.custom("NotoSansKR-Bold", size: 24, relativeTo: .title))
                .foregroundStyle(WorkoutCompletionColors.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("스테이지 업. 원판이 추가됐어요.")
        .accessibilityIdentifier("workout.completion.stage-up.heading")
    }

    private var previousBarbell: some View {
        StageBarbellIllustration(highlightsNewPlate: false)
            .frame(maxWidth: 328)
            .frame(height: 56)
            .opacity(0.42)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("이전 바벨, 총 \(reward.previousWeight)킬로그램")
            .accessibilityIdentifier("workout.completion.stage-up.barbell.before")
    }

    private var updatedBarbell: some View {
        StageBarbellIllustration(highlightsNewPlate: true)
            .frame(maxWidth: 328)
            .frame(height: 108)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "새 바벨, 총 \(reward.weight)킬로그램, 빨간 \(reward.plateWeight)킬로그램 원판 추가"
            )
            .accessibilityIdentifier("workout.completion.stage-up.barbell.updated")
    }

    private var weightTransition: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                previousWeight
                arrow
                currentWeight
            }

            VStack(spacing: 0) {
                previousWeight
                arrow
                currentWeight
            }
        }
        .font(Font.custom("BarlowCondensed-ExtraBold", size: 34, relativeTo: .largeTitle))
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "총 중량 \(reward.previousWeight)킬로그램에서 \(reward.weight)킬로그램으로 증가"
        )
        .accessibilityIdentifier("workout.completion.stage-up.weight-transition")
    }

    private var previousWeight: some View {
        Text(reward.previousWeight.formatted())
            .monospacedDigit()
            .foregroundStyle(WorkoutCompletionColors.secondaryText)
    }

    private var arrow: some View {
        Text("→")
            .font(Font.custom("BarlowCondensed-Bold", size: 26, relativeTo: .title2))
            .foregroundStyle(WorkoutCompletionColors.secondaryText)
            .accessibilityHidden(true)
    }

    private var currentWeight: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(reward.weight.formatted())
                .monospacedDigit()
                .foregroundStyle(WorkoutCompletionColors.primaryText)

            Text("KG")
                .font(Font.custom("Archivo-SemiBold", size: 13, relativeTo: .subheadline))
                .tracking(0.5)
                .foregroundStyle(WorkoutCompletionColors.primaryText)
        }
    }

    private var stageDescription: some View {
        Text("STAGE \(reward.stage) · HEAVY · \(reward.plateWeight)kg 레드 원판 해금")
            .font(Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
            .foregroundStyle(WorkoutCompletionColors.secondaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "스테이지 \(reward.stage), 헤비, \(reward.plateWeight)킬로그램 빨간 원판 해금"
            )
            .accessibilityIdentifier("workout.completion.stage-up.description")
    }
}

private struct StageBarbellIllustration: View {
    let highlightsNewPlate: Bool

    var body: some View {
        HStack(spacing: 0) {
            plateStack(isLeading: true)

            Capsule()
                .fill(Color(red: 0.72, green: 0.73, blue: 0.76))
                .frame(maxWidth: .infinity)
                .frame(height: highlightsNewPlate ? 7 : 5)

            plateStack(isLeading: false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: highlightsNewPlate ? 96 : 52)
    }

    private func plateStack(isLeading: Bool) -> some View {
        HStack(spacing: 2) {
            ForEach(plates(isLeading: isLeading)) { plate in
                RoundedRectangle(cornerRadius: 3)
                    .fill(plate.color)
                    .frame(width: plate.width, height: plate.height)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func plates(isLeading: Bool) -> [StageBarbellPlate] {
        let existingPlates = [
            StageBarbellPlate(id: "outer", width: 7, height: 42, color: existingPlateColor),
            StageBarbellPlate(id: "middle", width: 9, height: 57, color: existingPlateColor),
            StageBarbellPlate(id: "inner", width: 11, height: 72, color: existingPlateColor)
        ]

        guard highlightsNewPlate else {
            return isLeading ? existingPlates : Array(existingPlates.reversed())
        }

        let newPlate = StageBarbellPlate(
            id: "new-red-plate",
            width: 14,
            height: 88,
            color: WorkoutCompletionColors.red
        )

        if isLeading {
            return existingPlates + [newPlate]
        }
        return [newPlate] + Array(existingPlates.reversed())
    }

    private var existingPlateColor: Color {
        Color(red: 0.4, green: 0.4, blue: 0.43)
    }
}

private struct StageBarbellPlate: Identifiable {
    let id: String
    let width: CGFloat
    let height: CGFloat
    let color: Color
}
