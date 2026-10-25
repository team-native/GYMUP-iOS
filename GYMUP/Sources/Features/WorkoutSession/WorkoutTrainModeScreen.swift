import SwiftUI

struct WorkoutTrainModeScreen: View {
    let routineTitle: String
    let elapsedTime: String
    let exercise: WorkoutSessionExercise
    let exerciseIndex: Int
    let totalExerciseCount: Int
    let currentSetIndex: Int?
    let isShowingGuide: Bool
    let isResting: Bool
    let isPaused: Bool
    let restSecondsRemaining: Int
    let onQuit: () -> Void
    let onMusic: () -> Void
    let onToggleGuide: () -> Void
    let onToggleSet: (Int) -> Void
    let onAdjustWeight: (Double) -> Void
    let onAdjustRepetitions: (Int) -> Void
    let onSetDone: () -> Void
    let onSkipRest: () -> Void
    let onNextExercise: () -> Void
    let onFinish: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    exerciseHero(topInset: max(geometry.safeAreaInsets.top, 54))
                    exerciseProgress
                        .padding(.top, 6)
                    if isShowingGuide {
                        WorkoutSessionFormGuideView(exercise: exercise)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }
                    WorkoutSessionRecordSummary(exercise: exercise, currentSetIndex: currentSetIndex)
                        .padding(.top, 9)
                    WorkoutSessionSetTable(
                        exercise: exercise,
                        currentSetIndex: currentSetIndex,
                        onToggleSet: onToggleSet,
                        onAdjustWeight: onAdjustWeight,
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
        }
        .frame(height: 280)
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
                Text(isShowingGuide ? "자세 닫기" : "자세 보기")
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
            Text("EXERCISE \(min(exerciseIndex + 2, totalExerciseCount)) / \(totalExerciseCount)")
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

private struct WorkoutSessionRecordSummary: View {
    let exercise: WorkoutSessionExercise
    let currentSetIndex: Int?

    private var displayedSetIndex: Int? {
        currentSetIndex ?? (exercise.isComplete ? exercise.sets.indices.last : nil)
    }

    private var showsPersonalRecord: Bool {
        guard !exercise.isComplete else { return false }
        return currentSetIndex != exercise.sets.count - 1
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(exercise.previousPerformanceTitle(for: displayedSetIndex))
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            if showsPersonalRecord, let personalRecord = exercise.personalRecordKilograms {
                Text("PR 도전 \(personalRecord.formatted(.number.precision(.fractionLength(0...1))))kg")
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(GymupColors.brandText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 40, alignment: .center)
        .overlay(alignment: .bottom) {
            Rectangle().fill(GymupColors.border).frame(height: 1)
                .padding(.horizontal, 20)
        }
    }
}

private struct WorkoutSessionSetTable: View {
    let exercise: WorkoutSessionExercise
    let currentSetIndex: Int?
    let onToggleSet: (Int) -> Void
    let onAdjustWeight: (Double) -> Void
    let onAdjustRepetitions: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            columnHeaders
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                setRow(set, index: index)
            }
            if let currentSetIndex, exercise.sets.indices.contains(currentSetIndex) {
                HStack(spacing: 10) {
                    WorkoutSessionValueAdjuster(
                        title: "SET \(currentSetIndex + 1) · KG",
                        value: exercise.sets[currentSetIndex].weightKilograms.formatted(.number.precision(.fractionLength(0...1))),
                        onDecrease: { onAdjustWeight(-2.5) },
                        onIncrease: { onAdjustWeight(2.5) }
                    )
                    WorkoutSessionValueAdjuster(
                        title: "SET \(currentSetIndex + 1) · REPS",
                        value: String(exercise.sets[currentSetIndex].repetitions),
                        onDecrease: { onAdjustRepetitions(-1) },
                        onIncrease: { onAdjustRepetitions(1) }
                    )
                }
                .padding(.top, 14)
            }
        }
        .padding(.horizontal, 20)
    }

    private var columnHeaders: some View {
        HStack(spacing: 8) {
            tableLabel("SET")
                .frame(width: 36, alignment: .leading)
            tableLabel("이전")
                .frame(maxWidth: .infinity, alignment: .leading)
            tableLabel("KG")
                .frame(width: 72, alignment: .trailing)
            Text("×")
                .font(GymupTypography.label)
                .foregroundStyle(GymupColors.tertiaryText)
            tableLabel("REPS")
                .frame(width: 36, alignment: .leading)
            Color.clear.frame(width: 28)
        }
        .frame(height: 38)
        .padding(.horizontal, 4)
    }

    private func tableLabel(_ value: String) -> some View {
        Text(value)
            .font(GymupTypography.label)
            .tracking(0.16)
            .foregroundStyle(GymupColors.tertiaryText)
    }

    private func setRow(_ set: WorkoutSessionSet, index: Int) -> some View {
        let isCurrent = currentSetIndex == index
        let valueColor = set.isCompleted || isCurrent ? GymupColors.primaryText : GymupColors.tertiaryText
        return HStack(spacing: 8) {
            Text(String(index + 1))
                .font(GymupTypography.number)
                .foregroundStyle(isCurrent ? GymupColors.accent : valueColor)
                .frame(width: 36, alignment: .leading)
            Text(exercise.previousPerformance(for: index) ?? "—")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.tertiaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(set.weightKilograms.formatted(.number.precision(.fractionLength(0...1))))
                .font(GymupTypography.number)
                .foregroundStyle(valueColor)
                .frame(width: 72, alignment: .trailing)
            Text("×")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.tertiaryText)
            Text(String(set.repetitions))
                .font(GymupTypography.number)
                .foregroundStyle(valueColor)
                .frame(width: 36, alignment: .leading)
            Button { onToggleSet(index) } label: {
                statusIcon(set: set, isCurrent: isCurrent)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.isCompleted ? "세트 \(index + 1) 완료 취소" : "세트 \(index + 1) 완료")
            .accessibilityIdentifier("workout.set.\(index + 1).complete")
        }
        .padding(.horizontal, 4)
        .frame(height: 44)
        .background(isCurrent ? GymupColors.elevatedSurface.opacity(0.55) : .clear)
        .overlay(alignment: .bottom) {
            Rectangle().fill(GymupColors.border.opacity(0.8)).frame(height: 1)
        }
    }

    @ViewBuilder
    private func statusIcon(set: WorkoutSessionSet, isCurrent: Bool) -> some View {
        if set.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(GymupColors.accent)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
        } else {
            Circle()
                .strokeBorder(isCurrent ? GymupColors.accent : GymupColors.border, lineWidth: isCurrent ? 1.5 : 1)
                .frame(width: 28, height: 28)
        }
    }
}
