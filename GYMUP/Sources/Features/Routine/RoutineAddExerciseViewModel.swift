import Foundation
import Observation

struct RoutineExerciseOption: Identifiable, Hashable {
    let exercise: RoutineExercise
    let equipment: String
    let muscleGroup: String
    let difficulty: String?

    var id: String { exercise.id }
    var descriptor: String {
        [equipment, muscleGroup, difficulty].compactMap { $0 }.joined(separator: " · ")
    }

    static let all: [RoutineExerciseOption] = [
        .init(exercise: RoutineExercise.upper[0], equipment: "바벨", muscleGroup: "가슴", difficulty: nil),
        .init(exercise: RoutineExercise.upper[1], equipment: "덤벨", muscleGroup: "가슴", difficulty: "처음"),
        .init(exercise: RoutineExercise.upper[3], equipment: "케이블", muscleGroup: "가슴", difficulty: nil),
        .init(exercise: .init(id: "dips", name: "딥스", imageAssetName: "ExerciseHeroPhoto",
                              setCount: 3, repetitions: 10, weight: 0, restSeconds: 90),
               equipment: "맨몸", muscleGroup: "가슴", difficulty: "가슴 하부"),
        .init(exercise: .init(id: "chest-press", name: "체스트 프레스 머신", imageAssetName: "ExerciseHeroPhoto",
                              setCount: 3, repetitions: 10, weight: 40, restSeconds: 90),
               equipment: "머신", muscleGroup: "가슴", difficulty: nil),
        .init(exercise: RoutineExercise.back[0], equipment: "케이블", muscleGroup: "등", difficulty: nil),
        .init(exercise: RoutineExercise.lower[0], equipment: "바벨", muscleGroup: "하체", difficulty: nil),
        .init(exercise: RoutineExercise.upper[2], equipment: "덤벨", muscleGroup: "어깨", difficulty: nil)
    ]
}

@Observable
@MainActor
final class RoutineAddExerciseViewModel {
    let existingExerciseIDs: Set<String>
    var selectedExerciseIDs: Set<String>
    var searchText = ""
    var selectedCategory = "가슴"

    init(existingExercises: [RoutineExercise]) {
        existingExerciseIDs = Set(existingExercises.map(\.id))
        selectedExerciseIDs = existingExercises.isEmpty ? ["incline", "fly"] : []
    }

    var selectedCount: Int { selectedExerciseIDs.subtracting(existingExerciseIDs).count }

    var visibleOptions: [RoutineExerciseOption] {
        RoutineExerciseOption.all.filter { option in
            let matchesCategory = selectedCategory == "전체" || option.muscleGroup == selectedCategory
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = search.isEmpty ||
                option.exercise.name.localizedCaseInsensitiveContains(search) ||
                option.descriptor.localizedCaseInsensitiveContains(search)
            return matchesCategory && matchesSearch
        }
    }

    func isSelected(_ option: RoutineExerciseOption) -> Bool {
        existingExerciseIDs.contains(option.id) || selectedExerciseIDs.contains(option.id)
    }

    func toggle(_ option: RoutineExerciseOption) {
        guard !existingExerciseIDs.contains(option.id) else { return }
        if selectedExerciseIDs.contains(option.id) {
            selectedExerciseIDs.remove(option.id)
        } else {
            selectedExerciseIDs.insert(option.id)
        }
    }

    func exercisesToAdd() -> [RoutineExercise] {
        RoutineExerciseOption.all
            .filter { selectedExerciseIDs.contains($0.id) && !existingExerciseIDs.contains($0.id) }
            .map { option in
                var exercise = option.exercise
                exercise.restSeconds = WorkoutSettings.shared.restSeconds
                return exercise
            }
    }
}
