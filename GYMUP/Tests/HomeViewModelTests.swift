import XCTest
@testable import GYMUP

final class HomeViewModelTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let viewModel = HomeViewModel()

        XCTAssertEqual(viewModel.greeting, "디자인 시스템 기본 구성이 준비되었습니다.")
        XCTAssertFalse(viewModel.hasStarted)
    }

    @MainActor
    func testGreetingUsesEnteredName() {
        let viewModel = HomeViewModel()
        viewModel.name = "시우"

        XCTAssertEqual(viewModel.greeting, "안녕하세요, 시우님.")
    }

    @MainActor
    func testStartUpdatesState() {
        let viewModel = HomeViewModel()

        viewModel.start()

        XCTAssertTrue(viewModel.hasStarted)
    }
}

final class WorkoutCompletionDataTests: XCTestCase {
    func testSummarySkipsLevelUpWhenOnlyStageRewardExists() {
        let data = makeWorkoutCompletionData(
            stageReward: .init(previousWeight: 80, weight: 130, stage: 5, plateWeight: 25)
        )

        guard case .stageUp? = data.nextStep(after: .summary) else {
            return XCTFail("Expected the summary to continue directly to the stage-up screen")
        }
    }

    func testSummarySkipsLevelUpAndStageUpWhenOnlyPeakRewardExists() {
        let data = makeWorkoutCompletionData(
            peakReward: .init(
                goalGrowth: 100,
                durationWeeks: 12,
                workoutCount: 36,
                longestStreakWeeks: 12,
                fullyLoadedWeight: 180,
                rewardXP: 1_000
            )
        )

        guard case .peakUnlock? = data.nextStep(after: .summary) else {
            return XCTFail("Expected the summary to continue directly to the Peak screen")
        }
    }

    private func makeWorkoutCompletionData(
        levelReward: WorkoutCompletionData.LevelReward? = nil,
        stageReward: WorkoutCompletionData.StageReward? = nil,
        peakReward: WorkoutCompletionData.PeakReward? = nil
    ) -> WorkoutCompletionData {
        WorkoutCompletionData(
            routineName: "UPPER A",
            completedAt: "",
            metrics: [],
            previousGrowth: 0,
            growth: 0,
            earnedXP: 0,
            weeklyWorkoutCount: 0,
            weeklyWorkoutGoal: 0,
            streakWeeks: 0,
            levelReward: levelReward,
            stageReward: stageReward,
            peakReward: peakReward
        )
    }
}
