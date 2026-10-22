import Observation

@Observable
@MainActor
final class WorkoutSessionViewModel {
    let routine: RoutinePlan
    private(set) var exerciseIndex = 0
    private(set) var completedSets = 0
    private(set) var restSecondsRemaining = 0
    private(set) var isResting = false
    private(set) var isComplete = false
    private var restTask: Task<Void, Never>?

    init(routine: RoutinePlan) {
        self.routine = routine
    }

    var currentExercise: WorkoutExercise {
        routine.exercises[exerciseIndex]
    }

    var totalSets: Int {
        Int(currentExercise.detail.prefix(while: \.isNumber)) ?? 3
    }

    var isLastSet: Bool {
        completedSets + 1 == totalSets
    }

    var isLastExercise: Bool {
        exerciseIndex + 1 == routine.exercises.count
    }

    var completionButtonTitle: String {
        guard isLastSet, isLastExercise else {
            return isLastSet ? "다음 운동" : "세트 완료"
        }
        return "운동 완료"
    }

    var progress: Double {
        Double(exerciseIndex) / Double(routine.exercises.count)
    }

    func completeSet() {
        completedSets += 1
        if completedSets < totalSets {
            startRest(seconds: 90)
        } else {
            moveToNextExercise()
        }
    }

    func skipRest() {
        restTask?.cancel()
        restTask = nil
        restSecondsRemaining = 0
        isResting = false
    }

    func moveToNextExercise() {
        skipRest()
        guard exerciseIndex + 1 < routine.exercises.count else {
            isComplete = true
            return
        }
        exerciseIndex += 1
        completedSets = 0
    }

    func cancelTimer() {
        restTask?.cancel()
    }

    private func startRest(seconds: Int) {
        restTask?.cancel()
        restSecondsRemaining = seconds
        isResting = true
        restTask = Task { [weak self] in
            guard let self else { return }
            while self.restSecondsRemaining > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.restSecondsRemaining -= 1
            }
            guard !Task.isCancelled else { return }
            self.isResting = false
        }
    }
}
