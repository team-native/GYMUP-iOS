import Observation

@Observable
@MainActor
final class RoutineDetailViewModel {
    let store: RoutineStore
    let routineID: String
    var isMoreActionsPresented = false
    var isDeleteConfirmationPresented = false

    init(store: RoutineStore, routineID: String) {
        self.store = store
        self.routineID = routineID
    }

    var routine: RoutinePlan? { store.routine(id: routineID) }

    func presentMoreActions() {
        isMoreActionsPresented = true
    }

    func duplicateRoutine() -> String? {
        store.duplicateRoutine(id: routineID)
    }

    func presentDeleteConfirmation() {
        isDeleteConfirmationPresented = true
    }

    func cancelDeleteConfirmation() {
        isDeleteConfirmationPresented = false
    }

    @discardableResult
    func confirmDeleteRoutine() -> Bool {
        guard store.deleteRoutine(id: routineID) else { return false }
        isDeleteConfirmationPresented = false
        return true
    }

    var summary: String {
        guard let routine else { return "" }
        return "\(routine.title) · \(routine.exerciseCount)종목 · 약 \(routine.durationMinutes)분 · \(routine.displayedSetCount)세트"
    }
}
