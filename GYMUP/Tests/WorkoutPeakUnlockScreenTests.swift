import XCTest
@testable import GYMUP

final class WorkoutPeakUnlockScreenTests: XCTestCase {
    func testSamplePeakRewardMatchesCompletionScreenContent() throws {
        let reward = try XCTUnwrap(WorkoutCompletionData.sample.peakReward)

        XCTAssertEqual(reward.goalGrowth, 100)
        XCTAssertEqual(reward.durationWeeks, 12)
        XCTAssertEqual(reward.workoutCount, 36)
        XCTAssertEqual(reward.longestStreakWeeks, 12)
        XCTAssertEqual(reward.fullyLoadedWeight, 180)
        XCTAssertEqual(reward.rewardXP, 1_000)
    }

    func testPeakRewardFollowsLevelAndStageRewards() {
        let data = WorkoutCompletionData.sample

        guard case .stageUp? = data.nextStep(after: .levelUp) else {
            return XCTFail("The level reward should continue to the stage reward")
        }
        guard case .peakUnlock? = data.nextStep(after: .stageUp) else {
            return XCTFail("The completed goal should continue to the Peak reward")
        }
    }

    func testPeakOnlyRewardOpensDirectlyFromSummaryAndEndsTheRewardFlow() {
        let data = makeCompletionData(peakGrowth: 100)

        guard case .peakUnlock? = data.nextStep(after: .summary) else {
            return XCTFail("The summary should continue directly to Peak when it is the only reward")
        }
        XCTAssertNil(data.nextStep(after: .peakUnlock))
    }

    func testPeakDoesNotUnlockBeforeGoalReachesOneHundredGrowth() {
        let data = makeCompletionData(peakGrowth: 99)

        XCTAssertNil(data.nextStep(after: .summary))
    }

    private func makeCompletionData(peakGrowth: Int) -> WorkoutCompletionData {
        WorkoutCompletionData(
            routineName: "UPPER A",
            completedAt: "10월 25일 일 · 18:02 - 19:00",
            metrics: [],
            previousGrowth: peakGrowth - 1,
            growth: peakGrowth,
            earnedXP: 380,
            weeklyWorkoutCount: 3,
            weeklyWorkoutGoal: 3,
            streakWeeks: 12,
            levelReward: nil,
            stageReward: nil,
            peakReward: WorkoutCompletionData.PeakReward(
                goalGrowth: peakGrowth,
                durationWeeks: 12,
                workoutCount: 36,
                longestStreakWeeks: 12,
                fullyLoadedWeight: 180,
                rewardXP: 1_000
            )
        )
    }
}
