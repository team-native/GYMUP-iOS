import XCTest
@testable import GYMUP

final class WeeklyGoalViewModelTests: XCTestCase {
    @MainActor
    func testWeeklyGoalAndCompletedDaysMatchDesign() {
        let viewModel = WeeklyGoalViewModel()

        XCTAssertEqual(viewModel.completedWorkouts, 2)
        XCTAssertEqual(viewModel.weeklyGoal, 3)
        XCTAssertEqual(viewModel.remainingWorkouts, 1)
        XCTAssertEqual(viewModel.weekdays.count, 7)
        XCTAssertEqual(viewModel.completedWeekdays, [0, 2])
        XCTAssertEqual(viewModel.currentWeekday, 5)
    }

    @MainActor
    func testStreakAndWeeklyHistoryMatchDesign() {
        let viewModel = WeeklyGoalViewModel()

        XCTAssertEqual(viewModel.streakWeeks, 7)
        XCTAssertEqual(viewModel.longestStreakWeeks, 9)
        XCTAssertEqual(viewModel.progressBars.count, 12)
        XCTAssertEqual(viewModel.progressBars.filter(\.isMissedGoal).map(\.week), [4])
        XCTAssertEqual(viewModel.workouts.map(\.title), ["상체 A", "하체 B"])
    }
}
