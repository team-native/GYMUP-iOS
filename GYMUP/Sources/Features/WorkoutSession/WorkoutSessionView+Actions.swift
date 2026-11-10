import SwiftUI
import UIKit

extension WorkoutSessionView {
    func loadPreviousRecord(for exerciseID: String) async {
        async let previousRecord: Void = viewModel.loadPreviousRecord(for: exerciseID)
        async let firstTimeStatus: Void = viewModel.exerciseGuidance.loadFirstTimeStatus(
            for: exerciseID,
            in: viewModel.plan
        )
        _ = await (previousRecord, firstTimeStatus)
        guard viewModel.currentExercise?.id == exerciseID else { return }
        showFirstExercisePromptIfNeeded()
    }

    func handleRestTick(at date: Date) async {
        if let activityState = WorkoutRestActivityController.shared.currentState(sessionID: liveActivitySessionID) {
            if activityState.isSkipped {
                let didSkip = await viewModel.requestServerRestSkip()
                if didSkip {
                    settings.cancelRestNotification(sessionID: liveActivitySessionID)
                    await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID)
                } else {
                    isShowingServerActionError = viewModel.serverActionErrorMessage != nil
                    syncRestActivity()
                }
                return
            }
            viewModel.synchronizeRestTimer(
                endsAt: activityState.restEndsAt,
                durationSeconds: activityState.restDurationSeconds,
                at: date
            )
        }
        guard viewModel.refreshClock(at: date) else { return }
        isShowingRestFinishedAlert = settings.preferences.restTimerEnabled
        if settings.preferences.hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID)
    }

    func completeCurrentSet(at date: Date) {
        guard let currentSetIndex = viewModel.currentSetIndex else { return }
        Task {
            await completeSet(
                exerciseIndex: viewModel.currentExerciseIndex,
                setIndex: currentSetIndex,
                at: date
            )
        }
    }

    func completeSet(exerciseIndex: Int, setIndex: Int, at date: Date) async {
        let didComplete = await viewModel.completeSet(exerciseIndex: exerciseIndex, setIndex: setIndex, at: date)
        guard didComplete else {
            isShowingServerActionError = viewModel.serverActionErrorMessage != nil
            return
        }
        completeSetSideEffects()
    }

    private func completeSetSideEffects() {
        if settings.preferences.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        syncRestActivity()
        refreshNextSetPreviewIfServerResting()
        if viewModel.currentExerciseIndex == viewModel.plan.exercises.count - 1,
           viewModel.currentExercise?.isComplete == true {
            showWorkoutProcessing()
        }
    }

    func retryFailedServerAction() {
        let failedAction = viewModel.failedServerAction
        Task {
            let didRetry = await viewModel.retryFailedServerAction()
            guard didRetry else {
                isShowingServerActionError = viewModel.serverActionErrorMessage != nil
                return
            }
            if let failedAction, case .recordSet = failedAction {
                completeSetSideEffects()
            } else if let failedAction, case .startRest = failedAction {
                syncRestActivity()
                refreshNextSetPreviewIfServerResting()
            } else if let failedAction, case .skipRest = failedAction {
                settings.cancelRestNotification(sessionID: liveActivitySessionID)
                await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID)
            } else if let failedAction, case .extendRest = failedAction {
                syncRestActivity()
            } else if let failedAction, case .refreshRest = failedAction {
                syncRestActivity()
                refreshNextSetPreviewIfServerResting()
            }
        }
    }

    func skipCurrentRest() {
        Task {
            let didSkip = await viewModel.requestServerRestSkip()
            guard didSkip else {
                isShowingServerActionError = viewModel.serverActionErrorMessage != nil
                syncRestActivity()
                return
            }
            settings.cancelRestNotification(sessionID: liveActivitySessionID)
            await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID)
        }
    }

    func extendCurrentRest(by seconds: Int) {
        Task {
            let didExtend = await viewModel.requestServerRestExtension(by: seconds)
            guard didExtend else {
                isShowingServerActionError = viewModel.serverActionErrorMessage != nil
                syncRestActivity()
                return
            }
            syncRestActivity()
        }
    }

    private func refreshNextSetPreviewIfServerResting() {
        guard viewModel.isServerManagedRest else { return }
        Task { await viewModel.loadNextSetPreview() }
    }

    func refreshRestOnForeground() {
        guard viewModel.isServerManagedRest else { return }
        if viewModel.refreshClock(at: Date()) {
            syncRestActivity()
            return
        }
        guard viewModel.isResting else { return }
        Task {
            let didRefresh = await viewModel.refreshActiveServerRest(at: Date())
            guard didRefresh else {
                isShowingServerActionError = viewModel.serverActionErrorMessage != nil
                return
            }
            syncRestActivity()
            await viewModel.loadNextSetPreview()
        }
    }

    func skipPendingRestStart() {
        guard viewModel.skipPendingRestStart() else { return }
        syncRestActivity()
    }

    func advanceToNextExercise() {
        Task {
            let didAdvance = await viewModel.advanceToNextExercise()
            isShowingServerActionError = !didAdvance && viewModel.serverActionErrorMessage != nil
        }
    }

    func formattedDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    func finishWorkout() {
        settings.cancelRestNotification(sessionID: liveActivitySessionID)
        Task { await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID) }
        guard !didSaveHistoryRecord else {
            dismiss()
            return
        }

        if let completedAt = viewModel.finishedAt {
            var record = WorkoutSessionCompletionDataFactory.makeHistoryRecord(
                plan: viewModel.plan,
                elapsedSeconds: viewModel.elapsedSeconds(at: completedAt),
                completedAt: completedAt
            )
            record.earnedExperience = viewModel.completionData?.earnedXP
            if record.setCount > 0 {
                historyStore.add(record)
            }
            didSaveHistoryRecord = true
        }
        dismiss()
    }

    func finishWorkoutSession(at date: Date = .now) {
        isConfirmingFinish = false
        Task { @MainActor in
            if viewModel.serverWorkoutID != nil {
                isShowingWorkoutProcessing = true
            }
            let didFinish = await viewModel.finishWorkout(at: date)
            isShowingWorkoutProcessing = false
            isShowingServerActionError = !didFinish && viewModel.serverActionErrorMessage != nil
        }
    }

    func syncRestActivity() {
        guard settings.preferences.restTimerEnabled, viewModel.isResting,
              let exercise = viewModel.currentExercise,
              let setIndex = viewModel.currentSetIndex,
              let restEndsAt = viewModel.activeRestEndsAt else {
            settings.cancelRestNotification(sessionID: liveActivitySessionID)
            Task { await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID) }
            return
        }

        settings.scheduleRestNotification(sessionID: liveActivitySessionID, endsAt: restEndsAt)
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
            isSkipped: false,
            nextSetIsTimed: exercise.measure == .seconds
        )
        Task {
            await WorkoutRestActivityController.shared.startOrUpdate(sessionID: liveActivitySessionID, state: state)
        }
    }

    func showWorkoutProcessing() {
        isConfirmingFinish = false
        isShowingWorkoutProcessing = true
        Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(1_800))
            } catch {
                isShowingWorkoutProcessing = false
                return
            }
            let didFinish = await viewModel.finishWorkout(at: .now)
            isShowingWorkoutProcessing = false
            isShowingServerActionError = !didFinish && viewModel.serverActionErrorMessage != nil
        }
    }

    func showFirstExercisePromptIfNeeded() {
        guard let exercise = viewModel.currentExercise,
              viewModel.exerciseGuidance.shouldShowFirstExercisePrompt(for: exercise),
              !promptedExerciseIDs.contains(exercise.id) else { return }
        promptedExerciseIDs.insert(exercise.id)
        isShowingFirstExercisePrompt = true
    }

    static func makePreviousRecordService() -> ExerciseReadAPIService? {
#if DEBUG
        DebugOnboardingNetworking.makeExerciseReadService()
#else
        nil
#endif
    }

    static func makeProgressService() -> WorkoutSessionProgressing? {
#if DEBUG
        DebugOnboardingNetworking.makeWorkoutSessionService()
#else
        nil
#endif
    }

    static func makeWorkoutReadService() -> WorkoutNextSetReading? {
#if DEBUG
        DebugOnboardingNetworking.makeWorkoutReadService()
#else
        nil
#endif
    }

    static func makeCompletionService() -> WorkoutCompletionProcessing? {
#if DEBUG
        DebugOnboardingNetworking.makeWorkoutHistoryService()
#else
        nil
#endif
    }

    static func makeWorkoutRewardService() -> WorkoutRewardReading? {
#if DEBUG
        DebugOnboardingNetworking.makeWorkoutRewardService()
#else
        nil
#endif
    }
}
