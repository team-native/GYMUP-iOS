import XCTest
@testable import GYMUP

final class WorkoutLevelUpScreenTests: XCTestCase {
    func testSampleRewardMatchesE2PrototypeAndContinuesToStageReward() throws {
        let data = WorkoutCompletionData.sample
        let reward = try XCTUnwrap(data.levelReward)

        XCTAssertEqual(reward.previousLevel, 17)
        XCTAssertEqual(reward.level, 18)
        XCTAssertEqual(reward.currentXP, 100)
        XCTAssertEqual(reward.nextLevelXP, 3_200)
        XCTAssertEqual(reward.itemName, "골드 칼라")

        guard case .stageUp? = data.nextStep(after: .levelUp) else {
            return XCTFail("The E2 continue action should advance to the available stage reward")
        }
    }
}
