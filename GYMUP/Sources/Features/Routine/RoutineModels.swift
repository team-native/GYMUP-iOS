import Foundation
import Observation

struct RoutinePlan: Identifiable, Hashable {
    let id: String
    var name: String
    var title: String
    var exerciseCount: Int
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

    @discardableResult
    func duplicateRoutine(id: String) -> String? {
        guard let originalIndex = routines.firstIndex(where: { $0.id == id }) else { return nil }
        let original = routines[originalIndex]
        let duplicateTitle = nextDuplicateTitle(for: original.title)
        let duplicateID = UUID().uuidString.lowercased()
        let duplicate = RoutinePlan(
            id: duplicateID,
            name: duplicateTitle.uppercased(),
            title: duplicateTitle,
            exerciseCount: original.exerciseCount,
            durationMinutes: original.durationMinutes,
            lastPerformed: "기록 없음",
            coverAssetName: original.coverAssetName,
            isRecommended: false,
            exercises: original.exercises,
            muscleGroups: original.muscleGroups,
            summarySetCount: original.summarySetCount
        )
        routines.insert(duplicate, at: originalIndex + 1)
        return duplicateID
    }

    @discardableResult
    func deleteRoutine(id: String) -> Bool {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return false }
        routines.remove(at: index)
        return true
    }

    func saveRoutine(id: String?, title: String, exercises: [RoutineExercise]) -> String {
        let routineID = id ?? UUID().uuidString.lowercased()
        if let index = routines.firstIndex(where: { $0.id == routineID }) {
            routines[index].name = title.uppercased()
            routines[index].title = title
            routines[index].exerciseCount = exercises.count
            routines[index].exercises = exercises
            routines[index].summarySetCount = nil
            return routineID
        }

        routines.append(
            RoutinePlan(
                id: routineID,
                name: title.uppercased(),
                title: title,
                exerciseCount: exercises.count,
                durationMinutes: 0,
                lastPerformed: "",
                coverAssetName: "R1RoutineUpper",
                isRecommended: false,
                exercises: exercises
            )
        )
        return routineID
    }

    private func nextDuplicateTitle(for title: String) -> String {
        let baseTitle = "\(title) 복사본"
        let firstCandidate = String(baseTitle.prefix(20))
        guard routines.contains(where: { $0.title == firstCandidate }) else { return firstCandidate }

        var suffix = 2
        while true {
            let suffixTitle = " \(suffix)"
            let prefix = String(baseTitle.prefix(20 - suffixTitle.count))
            let candidate = prefix + suffixTitle
            if !routines.contains(where: { $0.title == candidate }) { return candidate }
            suffix += 1
        }
    }
}
