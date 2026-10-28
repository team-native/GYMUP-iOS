import XCTest
@testable import GYMUP

final class WorkoutSummaryRegressionTests: XCTestCase {
    func testE1SampleMatchesSummaryContentAndStartsRewardFlow() throws {
        let data = WorkoutCompletionData.sample

        XCTAssertEqual(data.routineName, "UPPER A")
        XCTAssertEqual(data.completedAt, "10월 11일 토 · 18:02 - 19:00")
        XCTAssertEqual(data.metrics.map(\.title), ["TIME", "SETS", "VOLUME", "PERSONAL RECORD"])
        XCTAssertEqual(data.metrics.map(\.value), ["58", "18", "8,420", "2"])
        XCTAssertEqual(data.earnedXP, data.experienceBreakdown.reduce(0) { $0 + $1.amount })

        guard case .levelUp? = data.nextStep(after: .summary) else {
            return XCTFail("E1 should continue to the level-up reward when it is available")
        }
    }

    func testE1RewardFlowAdvancesThroughAvailableScreensInOrder() {
        let data = WorkoutCompletionData.sample

        guard case .stageUp? = data.nextStep(after: .levelUp) else {
            return XCTFail("Level-up should continue to the stage-up reward")
        }
        guard case .peakUnlock? = data.nextStep(after: .stageUp) else {
            return XCTFail("Stage-up should continue to the Peak reward")
        }
        XCTAssertNil(data.nextStep(after: .peakUnlock))
    }

    @MainActor
    func testSessionSummaryIncludesLocalizedMetricsAndConsistentExperienceBreakdown() {
        var plan = WorkoutSessionPlan.sample(for: "upper-a")
        XCTAssertEqual(plan.exercises.filter { $0.personalRecordKilograms != nil }.count, 1)
        for exerciseIndex in plan.exercises.indices {
            for setIndex in plan.exercises[exerciseIndex].sets.indices {
                var set = plan.exercises[exerciseIndex].sets[setIndex]
                set.isCompleted = true
                if exerciseIndex == 0 {
                    set.weightKilograms = setIndex < 2 ? 70 : 50
                }
                plan.exercises[exerciseIndex].sets[setIndex] = set
            }
        }

        let data = WorkoutSessionCompletionDataFactory.make(
            plan: plan,
            elapsedSeconds: 3_480,
            completedAt: Date(timeIntervalSince1970: 1_800_000_000),
            context: WorkoutCompletionProgressContext(historyStore: HistoryStore(), goalSettings: nil)
        )

        XCTAssertEqual(data.metrics.count, 4)
        XCTAssertEqual(data.metrics.last?.title, "PERSONAL RECORD")
        XCTAssertEqual(data.metrics.last?.value, "1")
        XCTAssertEqual(data.experienceBreakdown.map(\.amount), [380, 100, 25])
        XCTAssertEqual(data.earnedXP, 505)
        XCTAssertEqual(data.earnedXP, data.experienceBreakdown.reduce(0) { $0 + $1.amount })
        XCTAssertTrue(data.completedAt.contains(" - "))
    }

    @MainActor
    func testSessionSummaryUsesGoalHistoryAndAwardsWeeklyBonusOnlyWhenGoalIsReached() throws {
        let calendar = Calendar.current
        let goalStart = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 12)))
        let completedAt = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 12)))
        let settings = OnboardingStoredSettings(
            experience: 1,
            purposes: ["근력 향상"],
            frequency: 3,
            goal: 1,
            weeks: 12,
            goalStartedAt: goalStart
        )
        let priorRecords = try [
            workoutRecord(on: DateComponents(year: 2026, month: 10, day: 26, hour: 12), calendar: calendar),
            workoutRecord(on: DateComponents(year: 2026, month: 10, day: 27, hour: 12), calendar: calendar)
        ]
        let historyStore = HistoryStore(records: priorRecords)
        var plan = WorkoutSessionPlan.sample(for: "upper-a")
        for exerciseIndex in plan.exercises.indices {
            for setIndex in plan.exercises[exerciseIndex].sets.indices {
                plan.exercises[exerciseIndex].sets[setIndex].isCompleted = true
            }
        }

        let data = WorkoutSessionCompletionDataFactory.make(
            plan: plan,
            elapsedSeconds: 1_200,
            completedAt: completedAt,
            context: WorkoutCompletionProgressContext(historyStore: historyStore, goalSettings: settings)
        )

        XCTAssertEqual(data.previousGrowth, 2)
        XCTAssertGreaterThan(data.growth, data.previousGrowth)
        XCTAssertEqual(data.weeklyWorkoutCount, 3)
        XCTAssertEqual(data.weeklyWorkoutGoal, 3)
        XCTAssertEqual(data.streakWeeks, 1)
        XCTAssertTrue(data.experienceBreakdown.contains { $0.title == "주간 목표 달성" && $0.amount == 30 })
        XCTAssertEqual(data.earnedXP, data.experienceBreakdown.reduce(0) { $0 + $1.amount })

        let alreadyReached = WorkoutSessionCompletionDataFactory.make(
            plan: plan,
            elapsedSeconds: 1_200,
            completedAt: completedAt,
            context: WorkoutCompletionProgressContext(
                historyStore: HistoryStore(records: priorRecords + [
                    try workoutRecord(on: DateComponents(year: 2026, month: 10, day: 28, hour: 11), calendar: calendar)
                ]),
                goalSettings: settings
            )
        )
        XCTAssertFalse(alreadyReached.experienceBreakdown.contains { $0.title == "주간 목표 달성" })
    }

    private func workoutRecord(on components: DateComponents, calendar: Calendar) throws -> WorkoutRecord {
        let date = try XCTUnwrap(calendar.date(from: components))
        return WorkoutRecord(
            id: UUID(), date: date, routineName: "상체 A", category: "가슴", durationMinutes: 40,
            setCount: 6, volumeKilograms: 1_200, growth: 0, photoAssetName: "H1RoutinePhoto", exercises: []
        )
    }
}
