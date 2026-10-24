import SwiftUI

struct WorkoutSessionProgressCard: View {
    let title: String
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text(title)
                        .font(GymupTypography.title)
                        .foregroundStyle(GymupColors.primaryText)
                    Text("오늘의 운동 루틴")
                        .font(GymupTypography.callout)
                        .foregroundStyle(GymupColors.secondaryText)
                }

                Spacer()

                Text("\(completedCount) / \(totalCount)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityLabel("완료한 운동 \(completedCount)개, 전체 \(totalCount)개")
            }

            ProgressView(value: Double(completedCount), total: Double(max(totalCount, 1)))
                .tint(GymupColors.accent)
                .accessibilityLabel("운동 진행")
        }
        .padding(GymupSpacing.large)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
    }
}

struct WorkoutSessionExerciseCard: View {
    let exercise: WorkoutSessionExercise
    let exerciseIndex: Int
    let totalExercises: Int
    @Binding var isShowingGuide: Bool
    let onToggleGuide: () -> Void
    let onAddSet: () -> Void
    let onToggleSet: (Int) -> Void
    let weightBinding: (Int) -> Binding<Double>
    let repetitionsBinding: (Int) -> Binding<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.large) {
            exerciseHeader

            if isShowingGuide {
                WorkoutSessionFormGuideView(exercise: exercise)
            }

            setColumnHeaders

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                setRow(set, setIndex: setIndex)
            }

            Button(action: onAddSet) {
                Label("세트 추가", systemImage: "plus")
                    .font(GymupTypography.uiSemibold)
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.add-set")
        }
        .padding(GymupSpacing.large)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
    }

    private var exerciseHeader: some View {
        HStack(alignment: .top, spacing: GymupSpacing.medium) {
            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text(exercise.name)
                    .font(GymupTypography.headline)
                    .foregroundStyle(GymupColors.primaryText)
                Text(exercise.target)
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
            }

            Spacer(minLength: 0)

            Button(action: onToggleGuide) {
                Label("자세 안내", systemImage: "info.circle")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.accent)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("workout.exercise-guide")

            Text("\(exerciseIndex + 1) / \(totalExercises)")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(GymupColors.elevatedSurface, in: Capsule())
                .accessibilityLabel("\(exerciseIndex + 1)번째 운동, 전체 \(totalExercises)개")
        }
    }

    private var setColumnHeaders: some View {
        HStack(spacing: GymupSpacing.small) {
            Text("세트")
                .frame(width: 40, alignment: .leading)
            Spacer(minLength: 0)
            Text("중량 (KG)")
                .frame(width: 82)
            Text("횟수")
                .frame(width: 60)
            Text("완료")
                .frame(width: 44)
        }
        .font(GymupTypography.uiCaption)
        .foregroundStyle(GymupColors.secondaryText)
        .padding(.horizontal, GymupSpacing.small)
        .accessibilityElement(children: .combine)
    }

    private func setRow(_ set: WorkoutSessionSet, setIndex: Int) -> some View {
        HStack(spacing: GymupSpacing.small) {
            Text(String(format: "%02d", setIndex + 1))
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(set.isCompleted ? GymupColors.accent : GymupColors.primaryText)
                .frame(width: 40, alignment: .leading)
                .accessibilityLabel("세트 \(setIndex + 1)")

            Spacer(minLength: 0)

            weightField(setIndex)

            Text("×")
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.secondaryText)

            repetitionsField(setIndex)

            setCompletionButton(set, setIndex: setIndex)
        }
        .padding(.horizontal, GymupSpacing.small)
        .padding(.vertical, GymupSpacing.xSmall)
        .background(
            set.isCompleted ? GymupColors.accent.opacity(0.08) : GymupColors.elevatedSurface.opacity(0.42),
            in: RoundedRectangle(cornerRadius: GymupRadius.medium)
        )
    }

    private func weightField(_ setIndex: Int) -> some View {
        TextField("0", value: weightBinding(setIndex), format: .number.precision(.fractionLength(0...1)))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .font(.system(.body, design: .rounded).weight(.medium))
            .foregroundStyle(GymupColors.primaryText)
            .frame(width: 82, height: 44)
            .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
            .accessibilityLabel("세트 \(setIndex + 1) 중량 킬로그램")
    }

    private func repetitionsField(_ setIndex: Int) -> some View {
        TextField("0", value: repetitionsBinding(setIndex), format: .number.grouping(.never))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(.body, design: .rounded).weight(.medium))
            .foregroundStyle(GymupColors.primaryText)
            .frame(width: 60, height: 44)
            .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
            .accessibilityLabel("세트 \(setIndex + 1) 반복 횟수")
    }

    private func setCompletionButton(_ set: WorkoutSessionSet, setIndex: Int) -> some View {
        Button {
            onToggleSet(setIndex)
        } label: {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(set.isCompleted ? GymupColors.accent : GymupColors.secondaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(set.isCompleted ? "세트 \(setIndex + 1) 완료 취소" : "세트 \(setIndex + 1) 완료")
        .accessibilityIdentifier("workout.set.\(setIndex + 1).complete")
    }
}

struct WorkoutSessionRestCard: View {
    let isPaused: Bool
    let remainingSeconds: Int
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: GymupSpacing.medium) {
            Image(systemName: isPaused ? "pause.fill" : "timer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(GymupColors.accent)
                .frame(width: 40, height: 40)
                .background(GymupColors.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text(isPaused ? "일시 정지 중" : "세트 휴식")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                Text(isPaused ? "이어 하기를 누르면 시간이 다시 흘러요." : "다음 세트까지")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
            }

            Spacer(minLength: GymupSpacing.xSmall)

            if !isPaused {
                Text(formattedDuration(remainingSeconds))
                    .font(.system(.title3, design: .rounded).monospacedDigit().weight(.bold))
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityLabel("휴식 남은 시간 \(spokenDuration(remainingSeconds))")
                Button("건너뛰기", action: onSkip)
                    .font(GymupTypography.uiSemibold)
                    .foregroundStyle(GymupColors.accent)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("휴식 건너뛰기")
            }
        }
        .padding(GymupSpacing.medium)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
    }

    private func formattedDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func spokenDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 { return "\(remainder)초" }
        return remainder == 0 ? "\(minutes)분" : "\(minutes)분 \(remainder)초"
    }
}
