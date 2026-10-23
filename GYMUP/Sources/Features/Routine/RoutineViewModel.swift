import Observation

enum RoutineListMode: String, CaseIterable, Identifiable {
    case mine = "내 루틴"
    case recommended = "추천"
    var id: Self { self }
}

@Observable
@MainActor
final class RoutineViewModel {
    let store: RoutineStore
    var mode = RoutineListMode.mine

    init(store: RoutineStore) { self.store = store }

    var routines: [RoutinePlan] {
        mode == .mine ? store.routines : store.routines.filter(\.isRecommended)
    }
}
