import XCTest
@testable import GYMUP

final class HomeViewModelTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let viewModel = HomeViewModel()

        XCTAssertEqual(viewModel.dateTitle, "10월 11일 토요일")
        XCTAssertEqual(viewModel.growth, 67)
        XCTAssertEqual(viewModel.weeklyWorkoutCount, 2)
        XCTAssertEqual(viewModel.weeklyWorkoutGoal, 3)
        XCTAssertEqual(viewModel.streakWeeks, 7)
        XCTAssertEqual(viewModel.experiencePoints, 2_340)
        XCTAssertEqual(viewModel.todayRoutine, "UPPER A")
    }

    @MainActor
    func testRoutineCategoryFiltersPlans() {
        let viewModel = RoutineViewModel()
        viewModel.selectedCategory = "하체"

        XCTAssertEqual(viewModel.routines.filter(viewModel.matchesCategory).map(\.name), ["LOWER A"])
    }

    @MainActor
    func testWorkoutSessionAdvancesAfterAllSets() {
        let routine = RoutinePlan.samples[0]
        let viewModel = WorkoutSessionViewModel(routine: routine)

        XCTAssertEqual(viewModel.completionButtonTitle, "세트 완료")
        viewModel.completeSet()
        XCTAssertEqual(viewModel.completedSets, 1)
        XCTAssertTrue(viewModel.isResting)
        viewModel.skipRest()
        viewModel.completeSet()
        viewModel.skipRest()
        viewModel.completeSet()
        viewModel.skipRest()
        viewModel.completeSet()

        XCTAssertEqual(viewModel.exerciseIndex, 1)
        XCTAssertEqual(viewModel.completedSets, 0)
        XCTAssertFalse(viewModel.isComplete)
        XCTAssertEqual(viewModel.completionButtonTitle, "세트 완료")
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
