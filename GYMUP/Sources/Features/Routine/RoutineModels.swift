import Observation

struct RoutinePlan: Identifiable, Hashable {
    let id: String
    let name: String
    let title: String
    let exerciseCount: Int
    let durationMinutes: Int
    let lastPerformed: String
    let coverAssetName: String
    let isRecommended: Bool

    var isEmpty: Bool { exerciseCount == 0 }
    var summary: String { "\(title) · \(exerciseCount)종목 · 약 \(durationMinutes)분 · \(lastPerformed)" }

    static let samples = [
        RoutinePlan(id: "upper-a", name: "UPPER A", title: "상체 A", exerciseCount: 6,
                    durationMinutes: 55, lastPerformed: "3일 전", coverAssetName: "R1RoutineUpper", isRecommended: true),
        RoutinePlan(id: "lower-b", name: "LOWER B", title: "하체 B", exerciseCount: 5,
                    durationMinutes: 60, lastPerformed: "5일 전", coverAssetName: "R1RoutineLower", isRecommended: false),
        RoutinePlan(id: "back-c", name: "BACK C", title: "등 · 이두 C", exerciseCount: 6,
                    durationMinutes: 50, lastPerformed: "1주 전", coverAssetName: "R1RoutineBack", isRecommended: false),
        RoutinePlan(id: "empty", name: "", title: "빈 루틴", exerciseCount: 0,
                    durationMinutes: 0, lastPerformed: "", coverAssetName: "", isRecommended: false)
    ]
}

@Observable
@MainActor
final class RoutineStore {
    var routines = RoutinePlan.samples
}
