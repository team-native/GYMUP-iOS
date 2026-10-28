import Foundation
import Observation

struct GrowthStage: Identifiable, Equatable {
    let title: String
    let weight: Int
    let lowerGrowth: Int
    let upperGrowth: Int
    let equipmentAssetName: String
    let isCurrent: Bool
    let isLocked: Bool

    var id: String { title }
    var growthRangeTitle: String { "Growth \(lowerGrowth)–\(upperGrowth)" }
}

struct GrowthFactor: Identifiable, Equatable {
    let title: String
    let value: String

    var id: String { title }
}

@Observable
@MainActor
final class GrowthViewModel {
    private struct StageDefinition {
        let title: String
        let weight: Int
        let lowerGrowth: Int
        let upperGrowth: Int
        let assetName: String
    }

    private static let stageDefinitions = [
        StageDefinition(title: "EMPTY BAR", weight: 20, lowerGrowth: 0, upperGrowth: 16, assetName: "H2EquipmentEmpty"),
        StageDefinition(title: "WARM-UP", weight: 40, lowerGrowth: 17, upperGrowth: 33, assetName: "H2EquipmentWarmup"),
        StageDefinition(title: "WORKING", weight: 60, lowerGrowth: 34, upperGrowth: 50, assetName: "H2EquipmentWorking"),
        StageDefinition(title: "STRONG", weight: 80, lowerGrowth: 51, upperGrowth: 66, assetName: "H2EquipmentStrong"),
        StageDefinition(title: "HEAVY", weight: 130, lowerGrowth: 67, upperGrowth: 83, assetName: "H2EquipmentHeavy"),
        StageDefinition(title: "PEAK", weight: 180, lowerGrowth: 84, upperGrowth: 100, assetName: "H2EquipmentPeak")
    ]

    private let historyStore: HistoryStore
    private let goalSettings: OnboardingStoredSettings?
    private let now: Date

    init(historyStore: HistoryStore? = nil, goalSettings: OnboardingStoredSettings? = .load(), now: Date = .now) {
        self.historyStore = historyStore ?? HistoryStore()
        self.goalSettings = goalSettings
        self.now = now
    }

    var growth: Int {
        guard goalSettings != nil else { return 0 }
        let workoutPoints = Double(goalRecords.count)
        let weeklyGoalPoints = Double(achievedGoalWeekCount * 2)
        let routinePoints = Double(goalRecords.filter(\.routineCompleted).count) * 0.5
        let personalRecordCount = goalRecords.flatMap(\.exercises).flatMap(\.sets).filter(\.isPersonalRecord).count
        let personalRecordPoints = Double(personalRecordCount) * 0.5
        return min(Int((workoutPoints + weeklyGoalPoints + routinePoints + personalRecordPoints).rounded()), 100)
    }

    var goalTitle: String {
        guard let goalSettings, ProfileGoalType.allCases.indices.contains(goalSettings.goal) else { return "목표 설정 필요" }
        return "\(ProfileGoalType.allCases[goalSettings.goal].rawValue) 목표"
    }

    var goalDurationWeeks: Int { goalSettings?.weeks ?? 12 }

    var currentWeek: Int {
        let elapsedDays = max(Calendar.current.dateComponents([.day], from: goalStartDate, to: now).day ?? 0, 0)
        return min(elapsedDays / 7 + 1, goalDurationWeeks)
    }

    var progress: Double { Double(growth) / 100 }

    var currentStage: GrowthStage {
        stages.first(where: \.isCurrent) ?? stages[0]
    }

    var stageTitle: String {
        let stageNumber = (stages.firstIndex(where: \.isCurrent) ?? 0) + 1
        return "STAGE \(stageNumber) · \(currentStage.title)"
    }

    var barbellWeight: Int { currentStage.weight }

    var nextPlateProgress: Int { max(currentStage.upperGrowth - growth + 1, 0) }

    var stages: [GrowthStage] {
        Self.stageDefinitions.map { definition in
            GrowthStage(
                title: definition.title,
                weight: definition.weight,
                lowerGrowth: definition.lowerGrowth,
                upperGrowth: definition.upperGrowth,
                equipmentAssetName: definition.assetName,
                isCurrent: (definition.lowerGrowth...definition.upperGrowth).contains(growth),
                isLocked: growth < definition.lowerGrowth
            )
        }
    }

    var growthFactors: [GrowthFactor] {
        [
            GrowthFactor(title: "운동 완료", value: "+1"),
            GrowthFactor(title: "주간 목표", value: "+2"),
            GrowthFactor(title: "루틴 100%", value: "+0.5"),
            GrowthFactor(title: "PR 달성", value: "+0.5")
        ]
    }

    private var goalStartDate: Date {
        goalSettings?.goalStartedAt ?? historyStore.records.map(\.date).min() ?? now
    }

    private var goalRecords: [WorkoutRecord] {
        guard goalSettings != nil else { return [] }
        let goalEndDate = Calendar.current.date(byAdding: .weekOfYear, value: goalDurationWeeks, to: goalStartDate) ?? now
        return historyStore.records.filter { $0.date >= goalStartDate && $0.date <= min(now, goalEndDate) }
    }

    private var achievedGoalWeekCount: Int {
        guard let weeklyFrequency = goalSettings?.frequency, weeklyFrequency > 0 else { return 0 }
        let countsByGoalWeek = Dictionary(grouping: goalRecords, by: goalWeekIndex)
        return countsByGoalWeek.values.filter { $0.count >= weeklyFrequency }.count
    }

    private func goalWeekIndex(for record: WorkoutRecord) -> Int {
        let elapsedDays = Calendar.current.dateComponents([.day], from: goalStartDate, to: record.date).day ?? 0
        return max(elapsedDays / 7, 0)
    }
}
