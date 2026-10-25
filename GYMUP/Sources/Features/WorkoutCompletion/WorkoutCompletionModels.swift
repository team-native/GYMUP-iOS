import Foundation

struct WorkoutCompletionSetDetail: Identifiable {
    let id: String
    let number: Int
    let weightKilograms: Double
    let repetitions: Int
}

struct WorkoutCompletionExerciseDetail: Identifiable {
    let id: String
    let name: String
    let sets: [WorkoutCompletionSetDetail]
}

struct WorkoutCompletionExperienceItem: Identifiable {
    let title: String
    let amount: Int

    var id: String { title }
}

struct WorkoutCompletionData {
    struct Metric: Identifiable {
        let title: String
        let value: String
        let unit: String

        var id: String { title }
    }

    struct LevelReward {
        let previousLevel: Int
        let level: Int
        let currentXP: Int
        let nextLevelXP: Int
        let itemName: String
    }

    struct StageReward {
        let previousWeight: Int
        let weight: Int
        let stage: Int
        let plateWeight: Int
    }

    struct PeakReward {
        let goalGrowth: Int
        let durationWeeks: Int
        let workoutCount: Int
        let longestStreakWeeks: Int
        let fullyLoadedWeight: Int
        let rewardXP: Int
    }

    let routineName: String
    let completedAt: String
    let metrics: [Metric]
    let previousGrowth: Int
    let growth: Int
    let earnedXP: Int
    var experienceBreakdown: [WorkoutCompletionExperienceItem] = []
    let weeklyWorkoutCount: Int
    let weeklyWorkoutGoal: Int
    let streakWeeks: Int
    let levelReward: LevelReward?
    let stageReward: StageReward?
    let peakReward: PeakReward?
    var exerciseDetails: [WorkoutCompletionExerciseDetail] = []

    static let sample = WorkoutCompletionData(
        routineName: "UPPER A",
        completedAt: "10월 11일 토 · 18:02 - 19:00",
        metrics: [
            Metric(title: "TIME", value: "58", unit: "MIN"),
            Metric(title: "SETS", value: "18", unit: "SETS"),
            Metric(title: "VOLUME", value: "8,420", unit: "KG"),
            Metric(title: "PERSONAL RECORD", value: "2", unit: "PR")
        ],
        previousGrowth: 67,
        growth: 68,
        earnedXP: 380,
        experienceBreakdown: [
            WorkoutCompletionExperienceItem(title: "운동 완료", amount: 200),
            WorkoutCompletionExperienceItem(title: "루틴 100% 완료", amount: 100),
            WorkoutCompletionExperienceItem(title: "PR 2개", amount: 50),
            WorkoutCompletionExperienceItem(title: "주간 목표 달성", amount: 30)
        ],
        weeklyWorkoutCount: 3,
        weeklyWorkoutGoal: 3,
        streakWeeks: 8,
        levelReward: LevelReward(
            previousLevel: 17,
            level: 18,
            currentXP: 3_420,
            nextLevelXP: 5_000,
            itemName: "골드 칼라"
        ),
        stageReward: StageReward(previousWeight: 80, weight: 130, stage: 5, plateWeight: 25),
        peakReward: PeakReward(
            goalGrowth: 100,
            durationWeeks: 12,
            workoutCount: 36,
            longestStreakWeeks: 12,
            fullyLoadedWeight: 180,
            rewardXP: 1_000
        )
    )
}

enum WorkoutCompletionStep {
    case summary
    case levelUp
    case stageUp
    case peakUnlock
}

extension WorkoutCompletionData {
    func nextStep(after step: WorkoutCompletionStep) -> WorkoutCompletionStep? {
        let canUnlockPeak = peakReward?.goalGrowth == 100

        switch step {
        case .summary:
            if levelReward != nil { return .levelUp }
            if stageReward != nil { return .stageUp }
            if canUnlockPeak { return .peakUnlock }
        case .levelUp:
            if stageReward != nil { return .stageUp }
            if canUnlockPeak { return .peakUnlock }
        case .stageUp:
            if canUnlockPeak { return .peakUnlock }
        case .peakUnlock:
            break
        }

        return nil
    }
}
