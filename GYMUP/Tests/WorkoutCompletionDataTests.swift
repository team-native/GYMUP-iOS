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
            completedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        XCTAssertEqual(data.metrics.count, 4)
        XCTAssertEqual(data.metrics.last?.title, "PERSONAL RECORD")
        XCTAssertEqual(data.metrics.last?.value, "1")
        XCTAssertEqual(data.experienceBreakdown.map(\.amount), [380, 100, 25, 30])
        XCTAssertEqual(data.earnedXP, 535)
        XCTAssertEqual(data.earnedXP, data.experienceBreakdown.reduce(0) { $0 + $1.amount })
        XCTAssertTrue(data.completedAt.contains(" - "))
    }
}
