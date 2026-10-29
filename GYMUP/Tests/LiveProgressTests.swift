import XCTest
@testable import GYMUP

@MainActor
final class LiveProgressTests: XCTestCase {
    func testNewGoalIsStoredAndPreviousGoalIsArchived() throws {
        let suite = "goals-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "onboarding.completed")
        defaults.set(1, forKey: "onboarding.experience")
        defaults.set("근력 향상", forKey: "onboarding.purposes")
        defaults.set(4, forKey: "onboarding.frequency")
        defaults.set(0, forKey: "onboarding.goal")
        defaults.set(12, forKey: "onboarding.weeks")
        let goals = GoalStore(defaults: defaults)
        let history = HistoryStore()
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        goals.start(ProfileGoalRecord(type: .strength, workoutsPerWeek: 4, durationWeeks: 8,
                                      period: "진행 중", growth: 0, completedWeeks: 0, isCurrent: true),
                    historyStore: history, now: now)
        let restored = GoalStore(defaults: defaults)
        XCTAssertEqual(restored.settings?.goal, 1)
        XCTAssertEqual(restored.settings?.frequency, 4)
        XCTAssertEqual(restored.settings?.weeks, 8)
        XCTAssertEqual(restored.settings?.goalStartedAt, now)
        XCTAssertEqual(restored.archived.count, 1)
        XCTAssertEqual(restored.archived.first?.type, .body)
        XCTAssertFalse(restored.archived.first?.isCurrent ?? true)
        XCTAssertEqual(restored.goals(historyStore: history).first?.growth, 0)
    }

    func testEmptyHistoryDoesNotShowSampleXPOrStreak() {
        let progress = WorkoutProgress(records: [], goal: 3)
        XCTAssertEqual(progress.experiencePoints, 0)
        XCTAssertEqual(progress.streakWeeks, 0)
        XCTAssertEqual(progress.longestStreakWeeks, 0)
        let weekly = WeeklyGoalViewModel(records: [], goal: 4)
        XCTAssertTrue(weekly.workouts.isEmpty)
        XCTAssertEqual(weekly.completedWorkouts, 0)
        XCTAssertTrue(weekly.progressBars.allSatisfy { $0.workoutCount == 0 })
    }

    func testSavedExperienceIsUsedWithoutRecalculatingOldGoalBonus() {
        var record = HistorySampleData.records[0]
        record.earnedExperience = 380
        XCTAssertEqual(WorkoutProgress(records: [record], goal: 7).experiencePoints, 380)
    }
}
