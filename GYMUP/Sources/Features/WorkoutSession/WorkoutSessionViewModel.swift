import Foundation
import Observation

@Observable
@MainActor
final class WorkoutSessionViewModel {
    private(set) var plan: WorkoutSessionPlan
    private(set) var currentExerciseIndex = 0
    private(set) var now: Date
    private(set) var finishedAt: Date?
    private(set) var notice: String?

    private(set) var startedAt: Date?
    private var pausedAt: Date?
    private var accumulatedPauseSeconds: TimeInterval = 0
    private var restEndsAt: Date?

    init(routineID: String, startedAt: Date = Date(), startsImmediately: Bool = true) {
        plan = .sample(for: routineID)
        self.startedAt = startsImmediately ? startedAt : nil
        now = startedAt
    }

    var currentExercise: WorkoutSessionExercise? {
        guard plan.exercises.indices.contains(currentExerciseIndex) else { return nil }
        return plan.exercises[currentExerciseIndex]
    }

    var currentSetIndex: Int? {
        currentExercise?.sets.firstIndex(where: { !$0.isCompleted })
    }

    var isPaused: Bool { pausedAt != nil }
    var hasStarted: Bool { startedAt != nil }
    var isFinished: Bool { finishedAt != nil }
    var isResting: Bool { !isPaused && restEndsAt.map { $0 > now } == true }
    var completedExerciseCount: Int { plan.exercises.filter(\.isComplete).count }
    var elapsedSeconds: Int { elapsedSeconds(at: now) }
    var completionData: WorkoutCompletionData? {
        guard let finishedAt else { return nil }
        return WorkoutSessionCompletionDataFactory.make(
            plan: plan,
            elapsedSeconds: elapsedSeconds(at: finishedAt),
            completedAt: finishedAt
        )
    }

    var restSecondsRemaining: Int {
        guard isResting, let restEndsAt else { return 0 }
        return max(0, Int(ceil(restEndsAt.timeIntervalSince(now))))
    }

    func elapsedSeconds(at date: Date) -> Int {
        guard let startedAt else { return 0 }
        let endDate = finishedAt ?? pausedAt ?? date
        let activeDuration = endDate.timeIntervalSince(startedAt) - accumulatedPauseSeconds
        return max(0, Int(activeDuration.rounded(.down)))
    }

    func start(at date: Date = Date()) {
        guard !hasStarted, !isFinished else { return }
        startedAt = date
        now = date
    }

    func refreshClock(at date: Date) {
        now = date
        if !isPaused, let restEndsAt, date >= restEndsAt {
            self.restEndsAt = nil
        }
    }

    func updateWeight(_ weight: Double, exerciseIndex: Int, setIndex: Int) {
        guard hasStarted,
              !isPaused,
              !isFinished,
              plan.exercises.indices.contains(exerciseIndex),
              plan.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        plan.exercises[exerciseIndex].sets[setIndex].weightKilograms = min(max(weight, 0), 999)
        notice = nil
    }

    func updateRepetitions(_ repetitions: Int, exerciseIndex: Int, setIndex: Int) {
        guard hasStarted,
              !isPaused,
              !isFinished,
              plan.exercises.indices.contains(exerciseIndex),
              plan.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        plan.exercises[exerciseIndex].sets[setIndex].repetitions = min(max(repetitions, 0), 999)
        notice = nil
    }

    func adjustCurrentWeight(by increment: Double) {
        guard let currentSetIndex, let currentExercise else { return }
        let weight = currentExercise.sets[currentSetIndex].weightKilograms + increment
        updateWeight(weight, exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex)
    }

    func adjustCurrentRepetitions(by increment: Int) {
        guard let currentSetIndex, let currentExercise else { return }
        let repetitions = currentExercise.sets[currentSetIndex].repetitions + increment
        updateRepetitions(repetitions, exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex)
    }

    func addSet(to exerciseIndex: Int) {
        guard hasStarted,
              !isPaused,
              !isFinished,
              plan.exercises.indices.contains(exerciseIndex) else { return }
        let lastSet = plan.exercises[exerciseIndex].sets.last
        let newSet = WorkoutSessionSet(
            weightKilograms: lastSet?.weightKilograms ?? 0,
            repetitions: lastSet?.repetitions ?? 10
        )
        plan.exercises[exerciseIndex].sets.append(newSet)
        notice = nil
    }

    func toggleSetCompletion(exerciseIndex: Int, setIndex: Int, at date: Date? = nil) {
        guard hasStarted,
              !isPaused,
              !isFinished,
              plan.exercises.indices.contains(exerciseIndex),
              plan.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }

        let wasCompleted = plan.exercises[exerciseIndex].sets[setIndex].isCompleted
        plan.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
        notice = nil

        guard !wasCompleted else {
            restEndsAt = nil
            return
        }

        let hasMoreSets = plan.exercises[exerciseIndex].sets.contains { !$0.isCompleted }
        if hasMoreSets, let date {
            now = date
            restEndsAt = date.addingTimeInterval(TimeInterval(plan.exercises[exerciseIndex].restDurationSeconds))
        } else if hasMoreSets {
            restEndsAt = now.addingTimeInterval(TimeInterval(plan.exercises[exerciseIndex].restDurationSeconds))
        } else {
            restEndsAt = nil
        }
    }

    @discardableResult
    func moveToNextExercise() -> Bool {
        guard hasStarted, !isPaused, !isFinished else { return false }
        guard let currentExercise else { return false }
        guard currentExercise.isComplete else {
            notice = "현재 운동의 세트를 모두 완료한 뒤 다음으로 이동할 수 있어요."
            return false
        }
        guard plan.exercises.indices.contains(currentExerciseIndex + 1) else { return false }

        currentExerciseIndex += 1
        restEndsAt = nil
        notice = nil
        return true
    }

    func skipRest() {
        restEndsAt = nil
    }

    func extendRest(by seconds: Int) {
        guard seconds > 0, isResting, let restEndsAt else { return }
        self.restEndsAt = restEndsAt.addingTimeInterval(TimeInterval(seconds))
    }

    func togglePause(at date: Date) {
        guard hasStarted, !isFinished else { return }
        now = date

        if let pausedAt {
            let pauseDuration = max(0, date.timeIntervalSince(pausedAt))
            accumulatedPauseSeconds += pauseDuration
            if let restEndsAt {
                self.restEndsAt = restEndsAt.addingTimeInterval(pauseDuration)
            }
            self.pausedAt = nil
        } else {
            pausedAt = date
        }
    }

    func finish(at date: Date = Date()) {
        guard hasStarted, !isFinished else { return }
        now = date
        if let pausedAt {
            accumulatedPauseSeconds += max(0, date.timeIntervalSince(pausedAt))
            self.pausedAt = nil
        }
        finishedAt = date
        restEndsAt = nil
        notice = nil
    }
}
