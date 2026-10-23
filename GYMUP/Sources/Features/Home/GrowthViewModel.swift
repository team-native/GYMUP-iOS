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
    let growth = 67
    let goalTitle = "체형 목표"
    let goalDurationWeeks = 12
    let currentWeek = 7
    let progress = 0.685

    let stages = [
        GrowthStage(
            title: "EMPTY BAR",
            weight: 20,
            lowerGrowth: 0,
            upperGrowth: 16,
            equipmentAssetName: "H2EquipmentEmpty",
            isCurrent: false,
            isLocked: false
        ),
        GrowthStage(
            title: "WARM-UP",
            weight: 40,
            lowerGrowth: 17,
            upperGrowth: 33,
            equipmentAssetName: "H2EquipmentWarmup",
            isCurrent: false,
            isLocked: false
        ),
        GrowthStage(
            title: "WORKING",
            weight: 60,
            lowerGrowth: 34,
            upperGrowth: 50,
            equipmentAssetName: "H2EquipmentWorking",
            isCurrent: false,
            isLocked: false
        ),
        GrowthStage(
            title: "STRONG",
            weight: 80,
            lowerGrowth: 51,
            upperGrowth: 66,
            equipmentAssetName: "H2EquipmentStrong",
            isCurrent: false,
            isLocked: false
        ),
        GrowthStage(
            title: "HEAVY",
            weight: 130,
            lowerGrowth: 67,
            upperGrowth: 83,
            equipmentAssetName: "H2EquipmentHeavy",
            isCurrent: true,
            isLocked: false
        ),
        GrowthStage(
            title: "PEAK",
            weight: 180,
            lowerGrowth: 84,
            upperGrowth: 100,
            equipmentAssetName: "H2EquipmentPeak",
            isCurrent: false,
            isLocked: true
        )
    ]

    let growthFactors = [
        GrowthFactor(title: "운동 완료", value: "+1"),
        GrowthFactor(title: "주간 목표", value: "+2"),
        GrowthFactor(title: "루틴 100%", value: "+0.5"),
        GrowthFactor(title: "PR 달성", value: "+0.5")
    ]
}
