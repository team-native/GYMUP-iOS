import SwiftUI

struct WorkoutSessionRecordSummary: View {
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

struct WorkoutSessionSetTable: View {
    let exercise: WorkoutSessionExercise
    let currentSetIndex: Int?
    let onToggleSet: (Int) -> Void
    let onAdjustWeight: (Double) -> Void
    let onInputWeight: () -> Void
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
                        value: exercise.sets[currentSetIndex].weightKilograms.formatted(
                            .number.precision(.fractionLength(0...1))
                        ),
                        onDecrease: { onAdjustWeight(-2.5) },
                        onIncrease: { onAdjustWeight(2.5) },
                        onValueTap: onInputWeight
                    )
                    WorkoutSessionValueAdjuster(
                        title: "SET \(currentSetIndex + 1) · \(exercise.measure == .seconds ? "SECS" : "REPS")",
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
            tableLabel(exercise.measure == .seconds ? "SECS" : "REPS")
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
