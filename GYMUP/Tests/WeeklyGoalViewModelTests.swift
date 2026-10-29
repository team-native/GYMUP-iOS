import XCTest
@testable import GYMUP

@MainActor
final class WeeklyGoalViewModelTests: XCTestCase {
    func testWeeklyCountsExcludePreviousWeekAndFutureWorkouts() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 12)))
        let start = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: now)?.start)
        let dates = [start, start.addingTimeInterval(3600), start.addingTimeInterval(-3600), now.addingTimeInterval(86400)]
        let records = dates.map { date in
            WorkoutRecord(id: UUID(), date: date, routineName: "실제 루틴", category: "코어", durationMinutes: 10,
                          setCount: 3, volumeKilograms: 0, growth: 0, photoAssetName: "H1RoutinePhoto", exercises: [])
        }
        let model = WeeklyGoalViewModel(records: records, goal: 3, now: now)
        XCTAssertEqual(model.completedWorkouts, 2)
        XCTAssertEqual(model.remainingWorkouts, 1)
        XCTAssertEqual(model.workouts.count, 2)
        XCTAssertEqual(model.progressBars.last?.workoutCount, 2)
    }

    func testEmptyHistoryHasNoInventedStreakOrWorkouts() {
        let model = WeeklyGoalViewModel()
        XCTAssertEqual(model.streakWeeks, 0)
        XCTAssertEqual(model.longestStreakWeeks, 0)
        XCTAssertEqual(model.progressBars.count, 12)
        XCTAssertFalse(model.progressBars.contains(where: \.isMissedGoal))
        XCTAssertTrue(model.workouts.isEmpty)
    }
}
