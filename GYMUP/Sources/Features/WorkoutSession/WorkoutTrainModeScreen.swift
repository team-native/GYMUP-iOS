import SwiftUI

struct WorkoutTrainModeScreen: View {
    let routineTitle: String
    let elapsedTime: String
    let exercise: WorkoutSessionExercise
    let exerciseIndex: Int
    let totalExerciseCount: Int
    let currentSetIndex: Int?
    let isResting: Bool
    let isPaused: Bool
    let restSecondsRemaining: Int
    let onQuit: () -> Void
    let onMusic: () -> Void
    let onToggleGuide: () -> Void
    let onToggleSet: (Int) -> Void
    let onAdjustWeight: (Double) -> Void
    let onInputWeight: () -> Void
    let onAdjustRepetitions: (Int) -> Void
    let onSetDone: () -> Void
    let onSkipRest: () -> Void
    let onNextExercise: () -> Void
    let onFinish: () -> Void
    let previousRecordError: String?
    let isLoadingPreviousRecord: Bool
    let onRetryPreviousRecord: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    exerciseHero(topInset: max(geometry.safeAreaInsets.top, 54))
                    exerciseProgress
                        .padding(.top, 6)
                    WorkoutSessionRecordSummary(exercise: exercise, currentSetIndex: currentSetIndex)
                        .padding(.top, 9)
                    if let previousRecordError {
                        WorkoutSessionRecordRetryBanner(
                            message: previousRecordError,
                            isLoading: isLoadingPreviousRecord,
                            onRetry: onRetryPreviousRecord
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    WorkoutSessionSetTable(
                        exercise: exercise,
                        currentSetIndex: currentSetIndex,
                        onToggleSet: onToggleSet,
                        onAdjustWeight: onAdjustWeight,
                        onInputWeight: onInputWeight,
                        onAdjustRepetitions: onAdjustRepetitions
                    )
                    if isResting {
                        WorkoutSessionRestCard(
                            isPaused: isPaused,
                            remainingSeconds: restSecondsRemaining,
                            onSkip: onSkipRest
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
            .ignoresSafeArea(edges: .top)
        }
        .background(GymupColors.canvas.ignoresSafeArea())
    }

    private func exerciseHero(topInset: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Image(exercise.imageAssetName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: GymupColors.canvas.opacity(0.12), location: 0.18),
                            .init(color: GymupColors.canvas.opacity(0.68), location: 0.72),
                            .init(color: GymupColors.canvas, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(spacing: 0) {
                navigationHeader
                guideButton
                    .padding(.top, 30)
                exerciseTitle
                    .padding(.top, 6)
            }
            .padding(.top, topInset)

            if isFinalSet {
                Text("LAST SET")
                    .font(GymupTypography.label)
                    .tracking(0.16)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(GymupColors.accent, in: Capsule())
                    .padding(.leading, 20)
                    .padding(.top, 140)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .accessibilityIdentifier("workout.train.last-set")
            }
        }
        .frame(height: 280)
    }

    private var isFinalSet: Bool {
        exerciseIndex == totalExerciseCount - 1 && currentSetIndex == exercise.sets.indices.last
    }

    private var exerciseProgress: some View {
        let activeProgressIndex = min(exerciseIndex + 1, max(totalExerciseCount - 1, 0))
        return HStack(spacing: 4) {
            ForEach(0..<max(totalExerciseCount, 1), id: \.self) { index in
                Capsule()
                    .fill(progressColor(for: index, activeIndex: activeProgressIndex))
                    .frame(maxWidth: .infinity)
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 20)
        .accessibilityLabel("운동 진행 \(exerciseIndex + 1)/\(totalExerciseCount)")
    }

    private func progressColor(for index: Int, activeIndex: Int) -> Color {
        if index < activeIndex { return GymupColors.secondaryText }
        if index == activeIndex { return GymupColors.accent }
        return GymupColors.overlay
    }

    private var navigationHeader: some View {
        HStack {
            Button(action: onQuit) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("운동 종료 확인")
            .accessibilityIdentifier("workout.quit")

            Spacer()

            VStack(spacing: 0) {
                Text(routineTitle)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.primaryText)
                Text(elapsedTime)
                    .font(GymupTypography.number)
                    .monospacedDigit()
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityLabel("운동 시간 \(elapsedTime)")
            }

            Spacer()

            Button(action: onMusic) {
                Image("R2IconMusic")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("플레이리스트")
            .accessibilityIdentifier("workout.playlist")
        }
        .padding(.horizontal, 8)
        .frame(height: 48)
    }

    private var guideButton: some View {
        HStack {
            Spacer()
            Button(action: onToggleGuide) {
                Text("자세 보기")
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(GymupColors.primaryText)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(.black.opacity(0.25), in: Capsule())
                    .overlay(Capsule().strokeBorder(GymupColors.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.exercise-guide")
        }
        .padding(.horizontal, 30)
    }

    private var exerciseTitle: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EXERCISE \(min(exerciseIndex + 1, totalExerciseCount)) / \(totalExerciseCount)")
                .font(GymupTypography.label)
                .tracking(0.16)
                .foregroundStyle(GymupColors.accent)
            Text(exercise.displayTitle)
                .font(GymupTypography.routineTitle)
                .tracking(-0.28)
                .foregroundStyle(GymupColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("\(exercise.name) · \(exercise.target)")
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.secondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionBar: some View {
        HStack {
            if currentSetIndex != nil {
                trainActionButton(title: "SET DONE", action: onSetDone)
            } else if exerciseIndex < totalExerciseCount - 1 {
                trainActionButton(title: "NEXT EXERCISE", action: onNextExercise)
            } else {
                trainActionButton(title: "FINISH WORKOUT", action: onFinish)
            }
        }
        .padding(.horizontal, 36)
        .frame(height: 50)
        .padding(.bottom, 0)
        .background(GymupColors.canvas)
    }

    private func trainActionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("BarlowCondensed-ExtraBold", size: 17))
                .tracking(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(GymupColors.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("workout.train.primary-action")
    }
}
