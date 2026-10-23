import XCTest
@testable import GYMUP

final class GrowthViewModelTests: XCTestCase {
    @MainActor
    func testInitialGrowthAndGoalProgress() {
        let viewModel = GrowthViewModel()

        XCTAssertEqual(viewModel.growth, 67)
        XCTAssertEqual(viewModel.goalTitle, "체형 목표")
        XCTAssertEqual(viewModel.goalDurationWeeks, 12)
        XCTAssertEqual(viewModel.currentWeek, 7)
        XCTAssertEqual(viewModel.stages.count, 6)
    }

    @MainActor
    func testCurrentAndLockedGrowthStages() {
        let viewModel = GrowthViewModel()
        let currentStages = viewModel.stages.filter(\.isCurrent)
        let lockedStages = viewModel.stages.filter(\.isLocked)

        XCTAssertEqual(currentStages.map(\.title), ["HEAVY"])
        XCTAssertEqual(currentStages.first?.weight, 130)
        XCTAssertEqual(lockedStages.map(\.title), ["PEAK"])
        XCTAssertEqual(lockedStages.first?.lowerGrowth, 84)
    }

    @MainActor
    func testGrowthFactorValuesMatchDesign() {
        let viewModel = GrowthViewModel()

        XCTAssertEqual(viewModel.growthFactors.map(\.value), ["+1", "+2", "+0.5", "+0.5"])
    }
}
