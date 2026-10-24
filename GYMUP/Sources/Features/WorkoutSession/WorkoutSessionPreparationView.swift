import SwiftUI

struct WorkoutSessionPreparationView: View {
    let plan: WorkoutSessionPlan
    @Binding var selectedExerciseIndex: Int
    let onBack: () -> Void
    let onStart: () -> Void

    private var selectedExercise: WorkoutSessionExercise? {
        guard plan.exercises.indices.contains(selectedExerciseIndex) else { return nil }
        return plan.exercises[selectedExerciseIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            GymupDetailNavigationBar(title: "운동 준비", onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GymupSpacing.large) {
                    planOverview
                    exercisePicker
                    if let selectedExercise {
                        WorkoutSessionFormGuideView(exercise: selectedExercise)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, GymupSpacing.large)
                .padding(.bottom, GymupSpacing.large)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GymupButton(title: "운동 시작", height: 52, action: onStart)
                .accessibilityIdentifier("workout.start")
                .padding(.horizontal, 20)
                .padding(.top, GymupSpacing.medium)
                .padding(.bottom, GymupSpacing.small)
                .background(GymupColors.canvas)
        }
    }

    private var planOverview: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            Text(plan.title)
                .font(GymupTypography.title)
                .foregroundStyle(GymupColors.primaryText)
            Text("운동 순서와 자세를 확인한 뒤 시작해요.")
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.secondaryText)
            Label(
                "약 \(plan.estimatedDurationMinutes)분 · \(plan.exercises.count)종목",
                systemImage: "clock"
            )
            .font(GymupTypography.uiSemibold)
            .foregroundStyle(GymupColors.accent)
            .padding(.top, GymupSpacing.xSmall)
        }
        .padding(GymupSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
    }

    private var exercisePicker: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.medium) {
            Text("오늘 할 운동")
                .font(GymupTypography.sectionTitle)
                .foregroundStyle(GymupColors.primaryText)

            ForEach(Array(plan.exercises.enumerated()), id: \.element.id) { index, exercise in
                Button {
                    selectedExerciseIndex = index
                } label: {
                    HStack(spacing: GymupSpacing.medium) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(.callout, design: .rounded).weight(.bold))
                            .foregroundStyle(selectedExerciseIndex == index ? GymupColors.accent : GymupColors.secondaryText)
                            .frame(width: 32, height: 32)
                            .background(GymupColors.elevatedSurface, in: Circle())

                        VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                            Text(exercise.name)
                                .font(GymupTypography.uiSemibold)
                                .foregroundStyle(GymupColors.primaryText)
                            Text("\(exercise.target) · \(exercise.sets.count)세트")
                                .font(GymupTypography.caption)
                                .foregroundStyle(GymupColors.secondaryText)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GymupColors.secondaryText)
                    }
                    .padding(.horizontal, GymupSpacing.medium)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .background(
                        selectedExerciseIndex == index ? GymupColors.accent.opacity(0.1) : GymupColors.surface,
                        in: RoundedRectangle(cornerRadius: GymupRadius.medium)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: GymupRadius.medium)
                            .strokeBorder(
                                selectedExerciseIndex == index ? GymupColors.accent.opacity(0.55) : .clear,
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("운동 자세 안내, \(exercise.name), \(exercise.target)")
                .accessibilityIdentifier("workout.guide.\(index + 1)")
            }
        }
    }
}

struct WorkoutSessionFormGuideView: View {
    let exercise: WorkoutSessionExercise

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.medium) {
            Label("자세 가이드 · \(exercise.name)", systemImage: "figure.strengthtraining.traditional")
                .font(GymupTypography.uiStrong)
                .foregroundStyle(GymupColors.primaryText)

            ForEach(Array(exercise.formSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: GymupSpacing.medium) {
                    Text("\(index + 1)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(GymupColors.accent)
                        .frame(width: 24, height: 24)
                        .background(GymupColors.accent.opacity(0.12), in: Circle())
                    Text(step)
                        .font(GymupTypography.callout)
                        .foregroundStyle(GymupColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            beginnerTip
        }
        .padding(GymupSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymupColors.canvas, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
        .accessibilityIdentifier("workout.form-guide.\(exercise.id)")
    }

    private var beginnerTip: some View {
        Label {
            Text(exercise.beginnerTip)
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: "sparkles")
                .foregroundStyle(WorkoutCompletionColors.gold)
        }
        .padding(GymupSpacing.medium)
        .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("처음 하는 운동 팁. \(exercise.beginnerTip)")
    }
}
