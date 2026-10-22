import Observation

@Observable
@MainActor
final class RoutineViewModel {
    let routines = RoutinePlan.samples
    var selectedCategory = "전체"
    let categories = ["전체", "상체", "하체", "PPL", "직접 만든 루틴"]

    func matchesCategory(_ routine: RoutinePlan) -> Bool {
        switch selectedCategory {
        case "상체": return routine.name.hasPrefix("UPPER") || routine.name.hasPrefix("PULL")
        case "하체": return routine.name.hasPrefix("LOWER")
        case "PPL": return routine.name.hasPrefix("PUSH") || routine.name.hasPrefix("PULL")
        default: return true
        }
    }
}
