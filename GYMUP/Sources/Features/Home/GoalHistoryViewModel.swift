import Observation

enum GoalFinalStage: String {
    case peak = "PEAK"
    case heavy = "HEAVY"

    var equipmentAssetName: String {
        self == .peak ? "H7PeakEquipment" : "H7HeavyEquipment"
    }
}

struct CompletedGoal: Identifiable {
    let title: String
    let period: String
    let stage: GoalFinalStage
    var id: String { title }
}

@Observable
@MainActor
final class GoalHistoryViewModel {
    let currentGoalTitle = "체형 · 주 3회"
    let currentWeek = 7
    let totalWeeks = 12
    let growth = 67
    let progress = 0.685
    let completedGoals = [
        CompletedGoal(title: "근력 · 주 4회", period: "2026.03 – 2026.06 · 16주", stage: .peak),
        CompletedGoal(title: "꾸준함 · 주 3회", period: "2025.11 – 2026.01 · 8주", stage: .peak),
        CompletedGoal(title: "체형 · 주 2회", period: "2025.08 – 2025.10 · 12주", stage: .heavy)
    ]
}
