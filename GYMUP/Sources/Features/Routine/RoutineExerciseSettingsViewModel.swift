import Foundation
import Observation

@Observable
@MainActor
final class RoutineExerciseSettingsViewModel {
    var exercise: RoutineExercise

    init(exercise: RoutineExercise) {
        self.exercise = exercise
    }

    func adjustSets(by amount: Int) {
        exercise.setCount = min(max(exercise.setCount + amount, 1), 20)
    }

    func adjustRepetitions(by amount: Int) {
        exercise.repetitions = min(max(exercise.repetitions + amount, 1), 100)
    }

    func adjustWeight(by amount: Double) {
        exercise.weight = min(max((exercise.weight + amount).rounded(toPlaces: 1), 0), 999.9)
    }

    func adjustRest(by seconds: Int) {
        exercise.restSeconds = min(max(exercise.restSeconds + seconds, 0), 3600)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let scale = pow(10, Double(places))
        return (self * scale).rounded() / scale
    }
}
