import Combine
import SwiftUI
import UIKit

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutSessionViewModel
    @State private var didSaveHistoryRecord = false
    private let historyStore: HistoryStore
    @State private var isConfirmingFinish = false
    @State private var isShowingWorkoutPhoto = false
    @State private var photoCompletionData: WorkoutCompletionData?
    @State private var isShowingPlaylist = false
    @State private var isShowingRestFinishedAlert = false
    @State private var guideIndex = 0
    @State private var isShowingCurrentGuide = false
    @State private var isShowingFirstExercisePrompt = false
    @State private var promptedExerciseIDs: Set<String> = []
    @State private var isShowingWorkoutProcessing = false
    @State private var isShowingWeightInput = false
    @State private var weightInputSetIndex: Int?
    @State private var liveActivitySessionID = UUID().uuidString

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @MainActor
    init(routineID: String, historyStore: HistoryStore) {
        _viewModel = State(initialValue: WorkoutSessionViewModel(routineID: routineID))
        self.historyStore = historyStore
    }

    var body: some View {
        Group {
            if isShowingWorkoutProcessing {
                WorkoutSessionProcessingScreen()
            } else if let data = viewModel.completionData {
                WorkoutCompletionFlowView(
                    data: data,
                    onWorkoutPhoto: {
                        photoCompletionData = data
                        isShowingWorkoutPhoto = true
                    },
                    onFinish: finishWorkout,
                    showsPhotoAction: true,
                    showsPeakGoalActions: false
                )
            } else if !viewModel.hasStarted {
                preparationContent
            } else {
                sessionContent
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if isConfirmingFinish {
                WorkoutExitConfirmationDialog(
                    completedExerciseCount: viewModel.completedExerciseCount,
                    completedSetCount: viewModel.plan.exercises.reduce(0) { $0 + $1.completedSetCount },
                    onFinish: { viewModel.finish() },
                    onContinue: { isConfirmingFinish = false }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .sheet(
            isPresented: $isShowingWorkoutPhoto,
            onDismiss: { photoCompletionData = nil },
            content: {
                if let photoCompletionData {
                    WorkoutPhotoFlowView(
                        data: photoCompletionData,
                        onClose: { isShowingWorkoutPhoto = false }
                    )
                    .presentationDragIndicator(.visible)
                }
            }
        )
        .sheet(isPresented: $isShowingPlaylist) {
            ProfilePlaylistSheetView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(
            isPresented: $isShowingWeightInput,
            onDismiss: { weightInputSetIndex = nil },
            content: {
                if let setIndex = weightInputSetIndex,
                   let exercise = viewModel.currentExercise,
                   exercise.sets.indices.contains(setIndex) {
                    WorkoutSessionWeightInputSheet(
                        setNumber: setIndex + 1,
                        initialWeight: exercise.sets[setIndex].weightKilograms,
                        onConfirm: { weight in
                            viewModel.updateWeight(
                                weight,
                                exerciseIndex: viewModel.currentExerciseIndex,
                                setIndex: setIndex
                            )
                            isShowingWeightInput = false
                        }
                    )
                    .presentationDetents([.height(506)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(28)
                    .presentationBackground(GymupColors.surface)
                }
            }
        )
        .fullScreenCover(isPresented: $isShowingCurrentGuide) {
            if let exercise = viewModel.currentExercise {
                WorkoutExerciseGuideScreen(
                    exercise: exercise,
                    onClose: { isShowingCurrentGuide = false }
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingFirstExercisePrompt) {
            if let exercise = viewModel.currentExercise {
                WorkoutFirstExercisePromptScreen(
                    exercise: exercise,
                    onViewGuide: {
                        isShowingFirstExercisePrompt = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            isShowingCurrentGuide = true
                        }
                    },
                    onStartNow: { isShowingFirstExercisePrompt = false }
                )
            }
        }
        .onReceive(clock) { date in
            Task { @MainActor in
                if let activityState = WorkoutRestActivityController.shared.currentState(sessionID: liveActivitySessionID) {
                    if activityState.isSkipped {
                        viewModel.skipRest()
                        await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID)
                        return
                    }
                    viewModel.synchronizeRestTimer(
                        endsAt: activityState.restEndsAt,
                        durationSeconds: activityState.restDurationSeconds,
                        at: date
                    )
                }
                guard viewModel.refreshClock(at: date) else { return }
                isShowingRestFinishedAlert = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID)
            }
        }
        .alert("휴식 시간이 끝났어요", isPresented: $isShowingRestFinishedAlert) {
            Button("다음 세트 진행", role: .cancel) {}
        } message: {
            Text("준비가 되면 다음 세트를 시작해 주세요.")
        }
        .onChange(of: viewModel.currentExerciseIndex) { _, _ in
            isShowingCurrentGuide = false
            showFirstExercisePromptIfNeeded()
        }
        .task { showFirstExercisePromptIfNeeded() }
    }

    private var preparationContent: some View {
        WorkoutSessionPreparationView(
            plan: viewModel.plan,
            selectedExerciseIndex: $guideIndex,
            onBack: dismiss.callAsFunction,
            onStart: { viewModel.start(at: Date()) }
        )
    }

    private var sessionContent: some View {
        Group {
            if let exercise = viewModel.currentExercise,
               exercise.isComplete,
               viewModel.plan.exercises.indices.contains(viewModel.currentExerciseIndex + 1) {
                WorkoutExerciseCompleteScreen(
                    exercise: exercise,
                    nextExercise: viewModel.plan.exercises[viewModel.currentExerciseIndex + 1],
                    nextExerciseIndex: viewModel.currentExerciseIndex + 1,
                    totalExerciseCount: viewModel.plan.exercises.count,
                    onContinue: { _ = viewModel.moveToNextExercise() },
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
                    onExtend: {
                        viewModel.extendRest(by: 15)
                        syncRestActivity()
                    },
                    onSkip: {
                        viewModel.skipRest()
                        Task { await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID) }
                    }
                )
            } else if let exercise = viewModel.currentExercise {
                WorkoutTrainModeScreen(
                    routineTitle: viewModel.plan.title,
                    elapsedTime: formattedDuration(viewModel.elapsedSeconds),
                    exercise: exercise,
                    exerciseIndex: viewModel.currentExerciseIndex,
                    totalExerciseCount: viewModel.plan.exercises.count,
                    currentSetIndex: viewModel.currentSetIndex,
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
                        viewModel.toggleSetCompletion(
                            exerciseIndex: viewModel.currentExerciseIndex,
                            setIndex: setIndex,
                            at: Date()
                        )
                        syncRestActivity()
                    },
                    onAdjustWeight: viewModel.adjustCurrentWeight,
                    onInputWeight: {
                        weightInputSetIndex = viewModel.currentSetIndex
                        isShowingWeightInput = weightInputSetIndex != nil
                    },
                    onAdjustRepetitions: viewModel.adjustCurrentRepetitions,
                    onSetDone: { completeCurrentSet(at: Date()) },
                    onSkipRest: viewModel.skipRest,
                    onNextExercise: { _ = viewModel.moveToNextExercise() },
                    onFinish: { isConfirmingFinish = true }
                )
            } else {
                GymupEmptyState(symbol: "dumbbell", title: "운동을 찾을 수 없어요", message: "루틴으로 돌아가 운동을 확인해 주세요.")
            }
        }
    }

}

private extension WorkoutSessionView {
    func completeCurrentSet(at date: Date) {
        guard let currentSetIndex = viewModel.currentSetIndex else { return }
        viewModel.toggleSetCompletion(
            exerciseIndex: viewModel.currentExerciseIndex,
            setIndex: currentSetIndex,
            at: date
        )
        syncRestActivity()
        if viewModel.currentExerciseIndex == viewModel.plan.exercises.count - 1,
           viewModel.currentExercise?.isComplete == true {
            showWorkoutProcessing()
        }
    }

    func formattedDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    func finishWorkout() {
        guard !didSaveHistoryRecord else {
            dismiss()
            return
        }

        if let completedAt = viewModel.finishedAt {
            let record = WorkoutSessionCompletionDataFactory.makeHistoryRecord(
                plan: viewModel.plan,
                elapsedSeconds: viewModel.elapsedSeconds(at: completedAt),
                completedAt: completedAt
            )
            historyStore.add(record)
            didSaveHistoryRecord = true
        }
        dismiss()
    }

    func syncRestActivity() {
        guard viewModel.isResting,
              let exercise = viewModel.currentExercise,
              let setIndex = viewModel.currentSetIndex,
              let restEndsAt = viewModel.activeRestEndsAt else {
            Task { await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID) }
            return
        }

        let nextSet = exercise.sets[setIndex]
        let duration = viewModel.activeRestDurationSeconds
        let state = WorkoutRestActivityAttributes.ContentState(
            restStartedAt: restEndsAt.addingTimeInterval(TimeInterval(-duration)),
            restEndsAt: restEndsAt,
            restDurationSeconds: duration,
            routineName: viewModel.plan.title,
            exerciseName: exercise.name,
            exerciseIndex: viewModel.currentExerciseIndex + 1,
            totalExerciseCount: viewModel.plan.exercises.count,
            completedSetCount: exercise.completedSetCount,
            nextSetNumber: setIndex + 1,
            nextSetWeightKilograms: nextSet.weightKilograms,
            nextSetRepetitions: nextSet.repetitions,
            isSkipped: false
        )
        Task {
            await WorkoutRestActivityController.shared.startOrUpdate(sessionID: liveActivitySessionID, state: state)
        }
    }

    func showWorkoutProcessing() {
        isShowingWorkoutProcessing = true
        Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(1_800))
            } catch {
                return
            }
            isShowingWorkoutProcessing = false
            viewModel.finish()
        }
    }

    func showFirstExercisePromptIfNeeded() {
        guard let exercise = viewModel.currentExercise,
              !exercise.hasPreviousPerformance,
              !promptedExerciseIDs.contains(exercise.id) else { return }
        promptedExerciseIDs.insert(exercise.id)
        isShowingFirstExercisePrompt = true
    }
}

#Preview {
    NavigationStack {
        WorkoutSessionView(routineID: "upper-a", historyStore: HistoryStore())
    }
    .preferredColorScheme(.dark)
}
