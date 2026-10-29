import Foundation

struct WorkoutProgress {
    let records: [WorkoutRecord]
    let goal: Int
    var now: Date = .now

    var experiencePoints: Int {
        records.reduce(0) { total, record in
            total + (record.earnedExperience ?? (record.setCount * 20 + (record.routineCompleted ? 100 : 0) + record.growth * 25))
        }
    }

    var streakWeeks: Int {
        WorkoutSessionCompletionDataFactory.currentStreakWeeks(records: records, goal: goal, at: now)
    }

    var longestStreakWeeks: Int {
        records.map {
            WorkoutSessionCompletionDataFactory.currentStreakWeeks(records: records, goal: goal, at: $0.date)
        }.max() ?? 0
    }
}
