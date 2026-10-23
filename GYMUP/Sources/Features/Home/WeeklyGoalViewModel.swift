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
    let completedWorkouts = 2
    let weeklyGoal = 3
    let streakWeeks = 7
    let longestStreakWeeks = 9
    let weekdays = ["월", "화", "수", "목", "금", "토", "일"]
    let completedWeekdays: Set<Int> = [0, 2]
    let currentWeekday = 5
    let progressBars = (1...12).map { week in
        WeeklyProgressBar(week: week, workoutCount: week == 4 ? 0 : (week < 4 ? 1 : 2), isMissedGoal: week == 4)
    }
    let workouts = [
        WeeklyWorkout(title: "상체 A", date: "10월 6일 (월)", duration: "58분", volume: "8,420kg"),
        WeeklyWorkout(title: "하체 B", date: "10월 8일 (수)", duration: "62분", volume: "11,200kg")
    ]

    var remainingWorkouts: Int { max(weeklyGoal - completedWorkouts, 0) }
}
