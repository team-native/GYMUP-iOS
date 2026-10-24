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

    var exercises: [RoutineExercise] = []
    var muscleGroups: [String] = []
    var summarySetCount: Int?
    var totalPlannedSets: Int { exercises.reduce(0) { $0 + $1.setCount } }
    var displayedSetCount: Int { summarySetCount ?? totalPlannedSets }

    var isEmpty: Bool { exerciseCount == 0 }
    var summary: String { "\(title) · \(exerciseCount)종목 · 약 \(durationMinutes)분 · \(lastPerformed)" }

    static let samples: [RoutinePlan] = {
        var plans = [
        RoutinePlan(id: "upper-a", name: "UPPER A", title: "상체 A", exerciseCount: 6,
                    durationMinutes: 55, lastPerformed: "3일 전", coverAssetName: "R1RoutineUpper", isRecommended: true),
        RoutinePlan(id: "lower-b", name: "LOWER B", title: "하체 B", exerciseCount: 5,
                    durationMinutes: 60, lastPerformed: "5일 전", coverAssetName: "R1RoutineLower", isRecommended: false),
        RoutinePlan(id: "back-c", name: "BACK C", title: "등 · 이두 C", exerciseCount: 6,
                    durationMinutes: 50, lastPerformed: "1주 전", coverAssetName: "R1RoutineBack", isRecommended: false),
        RoutinePlan(id: "empty", name: "", title: "빈 루틴", exerciseCount: 0,
                    durationMinutes: 0, lastPerformed: "", coverAssetName: "", isRecommended: false)
        ]
        for index in plans.indices {
            switch plans[index].id {
            case "upper-a":
                plans[index].exercises = RoutineExercise.upper
                plans[index].muscleGroups = ["가슴", "어깨", "삼두"]
                plans[index].summarySetCount = 21
            case "lower-b":
                plans[index].exercises = RoutineExercise.lower
                plans[index].muscleGroups = ["하체", "코어"]
            case "back-c":
                plans[index].exercises = RoutineExercise.back
                plans[index].muscleGroups = ["등", "이두"]
            default: break
            }
        }
        return plans
    }()
}

@Observable
@MainActor
final class RoutineStore {
    var routines = RoutinePlan.samples

    func routine(id: String) -> RoutinePlan? { routines.first { $0.id == id } }
}
