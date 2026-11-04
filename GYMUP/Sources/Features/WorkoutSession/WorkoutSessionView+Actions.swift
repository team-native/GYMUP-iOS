import SwiftUI
import UIKit

extension WorkoutSessionView {
    func loadPreviousRecord(for exerciseID: String) async {
        await viewModel.loadPreviousRecord(for: exerciseID)
        guard viewModel.currentExercise?.id == exerciseID else { return }
        showFirstExercisePromptIfNeeded()
    }

    func handleRestTick(at date: Date) async {
        if let activityState = WorkoutRestActivityController.shared.currentState(sessionID: liveActivitySessionID) {
            if activityState.isSkipped {
                viewModel.skipRest()
                settings.cancelRestNotification(sessionID: liveActivitySessionID)
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
        isShowingRestFinishedAlert = settings.preferences.restTimerEnabled
        if settings.preferences.hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        await WorkoutRestActivityController.shared.end(sessionID: liveActivitySessionID)
    }

    func completeCurrentSet(at date: Date) {
        guard let currentSetIndex = viewModel.currentSetIndex else { return }
        viewModel.toggleSetCompletion(
            exerciseIndex: viewModel.currentExerciseIndex,
            setIndex: currentSetIndex,
            at: date
        )
        if settings.preferences.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
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

    static func makePreviousRecordService() -> ExerciseReadAPIService? {
#if DEBUG
        DebugOnboardingNetworking.makeExerciseReadService()
#else
        nil
#endif
    }
}
