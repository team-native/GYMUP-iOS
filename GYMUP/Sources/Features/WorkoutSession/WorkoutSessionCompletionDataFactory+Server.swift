import Foundation

private struct WorkoutServerCompletionMetrics {
    let duration: Int
    let totalSets: Int
    let volume: Double
    let prs: JSONValue
    let experiencePoints: Int
    let progressShotAvailable: Bool?
}

extension WorkoutSessionCompletionDataFactory {
    static func applyingServerReward(
        _ response: WorkoutRewardResponse,
        to localData: WorkoutCompletionData
    ) -> WorkoutCompletionData {
        WorkoutCompletionData(
            routineName: localData.routineName,
            completedAt: localData.completedAt,
            metrics: localData.metrics,
            previousGrowth: localData.previousGrowth,
            growth: localData.growth,
            earnedXP: response.experiencePoints,
            experienceBreakdown: [],
            weeklyWorkoutCount: localData.weeklyWorkoutCount,
            weeklyWorkoutGoal: localData.weeklyWorkoutGoal,
            streakWeeks: localData.streakWeeks,
            levelReward: localData.levelReward,
            stageReward: localData.stageReward,
            peakReward: localData.peakReward,
            exerciseDetails: localData.exerciseDetails,
            progressShotAvailable: localData.progressShotAvailable,
            rewardGrowthDelta: response.growthDelta,
            rewardBonuses: response.bonuses,
            rewardGrantedAt: response.grantedAt
        )
    }

    static func applyingServerCompletion(
        _ response: CompleteWorkoutResponse,
        to localData: WorkoutCompletionData
    ) -> WorkoutCompletionData {
        applyingServerMetrics(
            WorkoutServerCompletionMetrics(
                duration: response.duration,
                totalSets: response.totalSets,
                volume: response.volume,
                prs: response.prs,
                experiencePoints: response.experiencePoints,
                progressShotAvailable: nil
            ),
            to: localData
        )
    }

    static func applyingServerSummary(
        _ response: WorkoutSummaryResponse,
        to localData: WorkoutCompletionData
    ) -> WorkoutCompletionData {
        applyingServerMetrics(
            WorkoutServerCompletionMetrics(
                duration: response.duration,
                totalSets: response.totalSets,
                volume: response.volume,
                prs: response.prs,
                experiencePoints: response.experiencePoints,
                progressShotAvailable: response.progressShotAvailable
            ),
            to: localData
        )
    }

    private static func applyingServerMetrics(
        _ serverMetrics: WorkoutServerCompletionMetrics,
        to localData: WorkoutCompletionData
    ) -> WorkoutCompletionData {
        let metrics = localData.metrics.map { metric in
            switch metric.title {
            case "TIME":
                return WorkoutCompletionData.Metric(
                    title: metric.title,
                    value: String(Int(ceil(Double(serverMetrics.duration) / 60))),
                    unit: metric.unit
                )
            case "SETS":
                return WorkoutCompletionData.Metric(
                    title: metric.title,
                    value: String(serverMetrics.totalSets),
                    unit: metric.unit
                )
            case "VOLUME":
                return WorkoutCompletionData.Metric(
                    title: metric.title,
                    value: formattedVolume(serverMetrics.volume),
                    unit: metric.unit
                )
            case "PERSONAL RECORD":
                let count = personalRecordCount(in: serverMetrics.prs)
                guard let count else { return metric }
                return WorkoutCompletionData.Metric(
                    title: metric.title,
                    value: String(count),
                    unit: metric.unit
                )
            default:
                return metric
            }
        }

        return WorkoutCompletionData(
            routineName: localData.routineName,
            completedAt: localData.completedAt,
            metrics: metrics,
            previousGrowth: localData.previousGrowth,
            growth: localData.growth,
            earnedXP: serverMetrics.experiencePoints,
            experienceBreakdown: [],
            weeklyWorkoutCount: localData.weeklyWorkoutCount,
            weeklyWorkoutGoal: localData.weeklyWorkoutGoal,
            streakWeeks: localData.streakWeeks,
            levelReward: localData.levelReward,
            stageReward: localData.stageReward,
            peakReward: localData.peakReward,
            exerciseDetails: localData.exerciseDetails,
            progressShotAvailable: serverMetrics.progressShotAvailable ?? localData.progressShotAvailable
        )
    }

    private static func personalRecordCount(in value: JSONValue) -> Int? {
        guard case let .array(items) = value,
              items.allSatisfy(isPersonalRecord) else { return nil }
        return items.count
    }

    private static func isPersonalRecord(_ value: JSONValue) -> Bool {
        guard case let .object(fields) = value,
              case let .string(exerciseID)? = fields["exerciseId"],
              !exerciseID.isEmpty,
              case let .integer(reps)? = fields["reps"],
              reps >= 0,
              let weight = fields["weight"] else { return false }
        switch weight {
        case let .integer(weight):
            return weight >= 0
        case let .number(weight):
            return weight.isFinite && weight >= 0
        default:
            return false
        }
    }
}
