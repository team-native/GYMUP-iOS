import SwiftUI

extension WorkoutSessionView {
    var preparationContent: some View {
        WorkoutSessionPreparationView(
            plan: viewModel.plan,
            selectedExerciseIndex: $guideIndex,
            onBack: dismiss.callAsFunction,
            onStart: { viewModel.start(at: Date()) }
        )
    }

    var sessionContent: some View {
        Group {
            if let exercise = viewModel.currentExercise,
               exercise.isComplete,
               viewModel.plan.exercises.indices.contains(viewModel.currentExerciseIndex + 1) {
                WorkoutExerciseCompleteScreen(
                    exercise: exercise,
                    nextExercise: viewModel.plan.exercises[viewModel.currentExerciseIndex + 1],
                    nextExerciseIndex: viewModel.currentExerciseIndex + 1,
                    totalExerciseCount: viewModel.plan.exercises.count,
                    onContinue: advanceToNextExercise,
                    onFinish: { isConfirmingFinish = true }
                )
            } else if viewModel.isResting,
               let exercise = viewModel.currentExercise,
               let nextSetIndex = viewModel.currentSetIndex {
                WorkoutSessionRestTimerScreen(
                    exercise: exercise,
                    completedSetCount: exercise.completedSetCount,
                    nextSetIndex: nextSetIndex,
                    remainingSeconds: viewModel.restSecondsRemaining,
                    totalSeconds: viewModel.activeRestDurationSeconds,
                    onExtend: { extendCurrentRest(by: 15) },
                    onSkip: skipCurrentRest,
                    previousRecordError: viewModel.previousRecordError(for: exercise.id),
                    isLoadingPreviousRecord: viewModel.isLoadingPreviousRecord(for: exercise.id),
                    onRetryPreviousRecord: { Task { await loadPreviousRecord(for: exercise.id) } },
                    nextSetPreview: viewModel.nextSetPreview,
                    nextSetPreviewError: viewModel.nextSetPreviewError,
                    isLoadingNextSetPreview: viewModel.isLoadingNextSetPreview,
                    onRetryNextSetPreview: { Task { await viewModel.loadNextSetPreview() } }
                )
            } else if let exercise = viewModel.currentExercise {
                WorkoutTrainModeScreen(
                    routineTitle: viewModel.plan.title,
                    elapsedTime: formattedDuration(viewModel.elapsedSeconds),
                    exercise: exercise,
                    exerciseIndex: viewModel.currentExerciseIndex,
                    totalExerciseCount: viewModel.plan.exercises.count,
                    currentSetIndex: viewModel.currentSetIndex,
                    canPerformPrimaryAction: viewModel.pendingRestStart == nil &&
                        !viewModel.isSubmittingWorkoutAction,
                    isResting: viewModel.isResting || viewModel.isPaused,
                    isPaused: viewModel.isPaused,
                    restSecondsRemaining: viewModel.restSecondsRemaining,
                    onQuit: { isConfirmingFinish = true },
                    onMusic: { isShowingPlaylist = true },
                    onToggleGuide: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingCurrentGuide.toggle()
                        }
                    },
                    onToggleSet: { setIndex in
                        if viewModel.serverWorkoutID == nil {
                            viewModel.toggleSetCompletion(
                                exerciseIndex: viewModel.currentExerciseIndex,
                                setIndex: setIndex,
                                at: Date()
                            )
                            syncRestActivity()
                        } else {
                            Task {
                                await completeSet(
                                    exerciseIndex: viewModel.currentExerciseIndex,
                                    setIndex: setIndex,
                                    at: Date()
                                )
                            }
                        }
                    },
                    canToggleSet: { setIndex in
                        viewModel.serverWorkoutID == nil ||
                            (viewModel.pendingRestStart == nil &&
                             setIndex == viewModel.currentSetIndex &&
                             !viewModel.isSubmittingWorkoutAction)
                    },
                    onAdjustWeight: viewModel.adjustCurrentWeight,
                    onInputWeight: {
                        weightInputSetIndex = viewModel.currentSetIndex
                        isShowingWeightInput = weightInputSetIndex != nil
                    },
                    onAdjustRepetitions: viewModel.adjustCurrentRepetitions,
                    onSetDone: { completeCurrentSet(at: Date()) },
                    onSkipRest: skipCurrentRest,
                    onNextExercise: advanceToNextExercise,
                    onFinish: { isConfirmingFinish = true },
                    previousRecordError: viewModel.previousRecordError(for: exercise.id),
                    isLoadingPreviousRecord: viewModel.isLoadingPreviousRecord(for: exercise.id),
                    onRetryPreviousRecord: { Task { await loadPreviousRecord(for: exercise.id) } }
                )
            } else {
                GymupEmptyState(
                    symbol: "dumbbell",
                    title: "운동을 찾을 수 없어요",
                    message: "루틴으로 돌아가 운동을 확인해 주세요."
                )
            }
        }
    }
}
