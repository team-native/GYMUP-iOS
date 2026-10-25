import XCTest
@testable import GYMUP

final class WorkoutStageUpScreenTests: XCTestCase {
    func testSampleRewardMatchesE4BarbellStagePrototype() throws {
        let reward = try XCTUnwrap(WorkoutCompletionData.sample.stageReward)

        XCTAssertEqual(reward.previousWeight, 80)
        XCTAssertEqual(reward.weight, 130)
        XCTAssertEqual(reward.stage, 5)
        XCTAssertEqual(reward.plateWeight, 25)
    }

    func testStageRewardContinuesToPeakWhenPeakIsAvailable() {
        let data = WorkoutCompletionData.sample

        guard case .stageUp? = data.nextStep(after: .levelUp) else {
            return XCTFail("The level-up screen should continue to E4")
        }
        guard case .peakUnlock? = data.nextStep(after: .stageUp) else {
            return XCTFail("E4 should continue to Peak when Peak is unlocked")
        }
    }

    func testStageOnlyCompletionShowsE4ThenFinishes() {
        let data = stageOnlyCompletionData()

        guard case .stageUp? = data.nextStep(after: .summary) else {
            return XCTFail("A stage-only reward should continue from completion to E4")
        }
        XCTAssertNil(data.nextStep(after: .stageUp))
    }

    private func stageOnlyCompletionData() -> WorkoutCompletionData {
        WorkoutCompletionData(
            routineName: "UPPER A",
            completedAt: "10월 25일 일 · 18:02 - 19:00",
            metrics: [],
            previousGrowth: 67,
            growth: 68,
            earnedXP: 380,
            weeklyWorkoutCount: 3,
            weeklyWorkoutGoal: 3,
            streakWeeks: 8,
            levelReward: nil,
            stageReward: WorkoutCompletionData.StageReward(
                previousWeight: 80,
                weight: 130,
                stage: 5,
                plateWeight: 25
            ),
            peakReward: nil
        )
    }
}
