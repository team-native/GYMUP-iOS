import Foundation

struct RoutineSaveValidation: Equatable {
    let isRoutineNameMissing: Bool
    let areExercisesMissing: Bool

    init(title: String, exerciseCount: Int) {
        isRoutineNameMissing = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        areExercisesMissing = exerciseCount < 1
    }

    var isValid: Bool { !isRoutineNameMissing && !areExercisesMissing }
}
