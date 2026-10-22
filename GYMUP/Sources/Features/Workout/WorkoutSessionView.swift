import SwiftUI

struct WorkoutSessionView: View {
    let routine: RoutinePlan
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutSessionViewModel

    init(routine: RoutinePlan) {
        self.routine = routine
        _viewModel = State(initialValue: WorkoutSessionViewModel(routine: routine))
    }

    var body: some View {
        Group {
            if viewModel.isComplete {
                WorkoutCompletionFlowView(onFinish: { dismiss() })
            } else {
                workoutContent
            }
        }
        .foregroundStyle(GymupColors.primaryText)
        .background(GymupColors.canvas)
        .onDisappear { viewModel.cancelTimer() }
    }

    private var workoutContent: some View {
        VStack(spacing: 0) {
            header
            ProgressView(value: viewModel.progress)
                .tint(GymupColors.accent)
                .padding(.horizontal, GymupSpacing.large)
            ScrollView {
                VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                    exerciseHeading
                    setList
                    if viewModel.isResting { restCard }
                    upcomingExercise
                }
                .padding(GymupSpacing.large)
            }
            footer
        }
        .background(GymupColors.canvas.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(GymupColors.surface, in: Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text(routine.name).font(GymupTypography.callout.weight(.bold))
                Text("운동 중")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "ellipsis")
                    .frame(width: 44, height: 44)
                    .background(GymupColors.surface, in: Circle())
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, GymupSpacing.large)
        .padding(.top, GymupSpacing.small)
    }

    private var exerciseHeading: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            Text("운동 \(viewModel.exerciseIndex + 1) / \(routine.exercises.count)")
                .font(GymupTypography.caption.weight(.bold))
                .foregroundStyle(GymupColors.accent)
            Text(viewModel.currentExercise.name)
                .font(GymupTypography.title)
            Text(viewModel.currentExercise.detail)
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.secondaryText)
        }
        .padding(.top, GymupSpacing.medium)
    }

    private var setList: some View {
        VStack(spacing: GymupSpacing.small) {
            ForEach(0..<viewModel.totalSets, id: \.self) { index in
                HStack(spacing: GymupSpacing.medium) {
                    Text("세트 \(index + 1)")
                        .font(GymupTypography.callout.weight(.semibold))
                    Spacer()
                    Text(viewModel.currentExercise.weight)
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                    Image(systemName: index < viewModel.completedSets ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 21))
                        .foregroundStyle(index < viewModel.completedSets ? GymupColors.accent : GymupColors.secondaryText)
                }
                .padding(GymupSpacing.medium)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            }
        }
    }

    private var restCard: some View {
        VStack(spacing: GymupSpacing.medium) {
            Text("REST")
                .font(GymupTypography.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(GymupColors.secondaryText)
            Text(String(format: "%02d:%02d", viewModel.restSecondsRemaining / 60, viewModel.restSecondsRemaining % 60))
                .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
            Button("휴식 건너뛰기") { viewModel.skipRest() }
                .font(GymupTypography.caption.weight(.semibold))
                .foregroundStyle(GymupColors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(GymupSpacing.large)
        .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
    }

    private var upcomingExercise: some View {
        Group {
            if viewModel.exerciseIndex + 1 < routine.exercises.count {
                let next = routine.exercises[viewModel.exerciseIndex + 1]
                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    Text("다음 운동").font(GymupTypography.caption).foregroundStyle(GymupColors.secondaryText)
                    HStack {
                        Text(next.name).font(GymupTypography.callout.weight(.semibold))
                        Spacer()
                        Text(next.detail).font(GymupTypography.caption).foregroundStyle(GymupColors.secondaryText)
                    }
                }
                .padding(GymupSpacing.medium)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            }
        }
    }

    private var footer: some View {
        GymupButton(title: viewModel.completionButtonTitle) {
            viewModel.completeSet()
        }
        .padding(GymupSpacing.large)
        .background(GymupColors.canvas)
    }
}

#Preview {
    WorkoutSessionView(routine: RoutinePlan.samples[0])
}
