import Foundation
import Observation

struct WeeklyWorkout: Identifiable, Equatable {
    let title: String
    let date: String
    let duration: String
    let volume: String

    var id: String { title }
}

struct WeeklyProgressBar: Identifiable, Equatable {
    let week: Int
    let workoutCount: Int
    let isMissedGoal: Bool

    var id: Int { week }
}

@Observable
@MainActor
final class WeeklyGoalViewModel {
    private let records: [WorkoutRecord]
    let weeklyGoal: Int
    private let now: Date
    let weekdays = ["월", "화", "수", "목", "금", "토", "일"]

    init(records: [WorkoutRecord] = [], goal: Int = 3, now: Date = .now) {
        self.records = records
        self.weeklyGoal = goal
        self.now = now
    }

    private var currentWeek: [WorkoutRecord] {
        records.filter { Calendar.current.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) && $0.date <= now }
    }
    var completedWorkouts: Int { currentWeek.count }
    var streakWeeks: Int { WorkoutProgress(records: records, goal: weeklyGoal, now: now).streakWeeks }
    var longestStreakWeeks: Int { WorkoutProgress(records: records, goal: weeklyGoal, now: now).longestStreakWeeks }
    var completedWeekdays: Set<Int> {
        Set(currentWeek.map { (Calendar.current.component(.weekday, from: $0.date) + 5) % 7 })
    }
    var currentWeekday: Int { (Calendar.current.component(.weekday, from: now) + 5) % 7 }
    var progressBars: [WeeklyProgressBar] {
        let calendar = Calendar.current
        guard let currentStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        return (0..<12).compactMap { index in
            guard let start = calendar.date(byAdding: .weekOfYear, value: index - 11, to: currentStart),
                  let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { return nil }
            let count = records.filter { $0.date >= start && $0.date < end && $0.date <= now }.count
            let hasStarted = start >= (records.map(\.date).min() ?? now)
            return WeeklyProgressBar(week: index + 1, workoutCount: count,
                                     isMissedGoal: index < 11 && count < weeklyGoal && hasStarted)
        }
    }
    var workouts: [WeeklyWorkout] {
        currentWeek.sorted { $0.date > $1.date }.map {
            WeeklyWorkout(title: $0.routineName, date: HistoryDateText.string($0.date, format: "M월 d일 (E)"),
                          duration: "\($0.durationMinutes)분", volume: "\($0.volumeKilograms.formatted())kg")
        }
    }
    var remainingWorkouts: Int { max(weeklyGoal - completedWorkouts, 0) }
}
