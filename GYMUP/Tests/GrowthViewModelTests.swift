import XCTest
@testable import GYMUP

final class GrowthViewModelTests: XCTestCase {
    @MainActor
    func testGrowthScoreUsesGoalWorkoutsWeeklyGoalsRoutineCompletionAndPersonalRecords() {
        let start = date(day: 1)
        let records = [
            record(day: 2, routineCompleted: true, personalRecords: 1),
            record(day: 4),
            record(day: 10)
        ]
        let viewModel = GrowthViewModel(
            historyStore: HistoryStore(records: records),
            goalSettings: settings(startedAt: start, frequency: 2),
            now: date(day: 12)
        )

        XCTAssertEqual(viewModel.growth, 6)
        XCTAssertEqual(viewModel.progress, 0.06, accuracy: 0.001)
        XCTAssertEqual(viewModel.goalTitle, "체형 목표")
        XCTAssertEqual(viewModel.goalDurationWeeks, 12)
    }

    @MainActor
    func testGrowthUsesStoredGoalAndElapsedGoalWeek() {
        let viewModel = GrowthViewModel(
            historyStore: HistoryStore(),
            goalSettings: settings(goal: 1, startedAt: date(day: 1)),
            now: date(day: 43)
        )

        XCTAssertEqual(viewModel.goalTitle, "근력 목표")
        XCTAssertEqual(viewModel.currentWeek, 7)
    }

    @MainActor
    func testRecordsOutsideTheActiveGoalDoNotIncreaseGrowth() {
        let viewModel = GrowthViewModel(
            historyStore: HistoryStore(records: [record(day: 2), record(day: 90)]),
            goalSettings: settings(startedAt: date(day: 1)),
            now: date(day: 90)
        )

        XCTAssertEqual(viewModel.growth, 1)
    }

    @MainActor
    func testGrowthUpdatesWhenACompletedWorkoutIsAdded() {
        let historyStore = HistoryStore()
        let viewModel = GrowthViewModel(
            historyStore: historyStore,
            goalSettings: settings(startedAt: date(day: 1)),
            now: date(day: 3)
        )

        XCTAssertEqual(viewModel.growth, 0)
        historyStore.add(record(day: 2))
        XCTAssertEqual(viewModel.growth, 1)
    }

    @MainActor
    func testStageAndLockStateFollowTheCalculatedGrowth() {
        let records = (1...82).map { _ in record(day: 2) }
        let viewModel = GrowthViewModel(
            historyStore: HistoryStore(records: records),
            goalSettings: settings(startedAt: date(day: 1)),
            now: date(day: 3)
        )

        XCTAssertEqual(viewModel.growth, 84)
        XCTAssertEqual(viewModel.stages.filter(\.isCurrent).map(\.title), ["PEAK"])
        XCTAssertTrue(viewModel.stages.allSatisfy { !$0.isLocked })
    }

    @MainActor
    func testUnconfiguredGoalStartsAtZeroAndShowsFirstStage() {
        let viewModel = GrowthViewModel(historyStore: HistoryStore(records: [record(day: 2)]), goalSettings: nil, now: date(day: 3))

        XCTAssertEqual(viewModel.growth, 0)
        XCTAssertEqual(viewModel.goalTitle, "목표 설정 필요")
        XCTAssertEqual(viewModel.currentWeek, 1)
        XCTAssertEqual(viewModel.stages.filter(\.isCurrent).map(\.title), ["EMPTY BAR"])
    }

    @MainActor
    func testGrowthFactorValuesMatchDesign() {
        let viewModel = GrowthViewModel()

        XCTAssertEqual(viewModel.growthFactors.map(\.value), ["+1", "+2", "+0.5", "+0.5"])
    }

    private func settings(goal: Int = 0, startedAt: Date, frequency: Int = 2) -> OnboardingStoredSettings {
        OnboardingStoredSettings(
            experience: 1,
            purposes: ["근력 향상"],
            frequency: frequency,
            goal: goal,
            weeks: 12,
            goalStartedAt: startedAt
        )
    }

    private func record(day: Int, routineCompleted: Bool = false, personalRecords: Int = 0) -> WorkoutRecord {
        WorkoutRecord(
            id: UUID(),
            date: date(day: day),
            routineName: "상체 A",
            category: "가슴",
            durationMinutes: 45,
            setCount: max(personalRecords, 1),
            volumeKilograms: 100,
            growth: personalRecords,
            photoAssetName: "H1RoutinePhoto",
            exercises: personalRecords == 0 ? [] : [
                WorkoutExerciseRecord(id: 1, name: "벤치프레스", sets: [
                    WorkoutSetRecord(id: 1, weight: 60, repetitions: 8, isPersonalRecord: true)
                ])
            ],
            routineCompleted: routineCompleted
        )
    }

    private func date(day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: day)) ?? .now
    }
}
