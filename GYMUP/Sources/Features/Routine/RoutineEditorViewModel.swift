import Observation

@Observable
@MainActor
final class RoutineEditorViewModel {
    let store: RoutineStore
    let routineID: String?
    var title: String
    var exercises: [RoutineExercise]
    var draggingExerciseID: String?

    init(store: RoutineStore, routineID: String?) {
        self.store = store
        self.routineID = routineID
        let routine = routineID.flatMap(store.routine(id:))
        title = routine?.title ?? ""
        exercises = routine?.exercises ?? []
    }

    var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var exerciseCount: Int { exercises.count }

    func limitTitle(_ value: String) {
        title = String(value.prefix(20))
    }

    func moveExercise(id draggedID: String, before targetID: String) {
        guard draggedID != targetID,
              let source = exercises.firstIndex(where: { $0.id == draggedID }),
              let target = exercises.firstIndex(where: { $0.id == targetID }) else { return }
        let movingExercise = exercises.remove(at: source)
        let destination = source < target ? target - 1 : target
        exercises.insert(movingExercise, at: destination)
    }

    func updateExercise(_ exercise: RoutineExercise) {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        exercises[index] = exercise
    }

    func removeExercise(id: String) {
        exercises.removeAll { $0.id == id }
    }

    @discardableResult
    func save() -> String? {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else { return nil }
        return store.saveRoutine(id: routineID, title: normalizedTitle, exercises: exercises)
    }
}
