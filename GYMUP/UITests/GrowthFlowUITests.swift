import XCTest

final class GrowthFlowUITests: XCTestCase {
    func testGrowthScreenUsesConfiguredGoalAndStartsWithoutSampleProgress() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-onboarding.completed", "YES",
            "-onboarding.experience", "1",
            "-onboarding.purposes", "테스트",
            "-onboarding.frequency", "2",
            "-onboarding.goal", "1",
            "-onboarding.weeks", "12",
            "-onboarding.goal.startedAt", "2026-10-28T00:00:00Z"
        ]
        app.launch()

        let growthCard = app.buttons["home.growth"]
        XCTAssertTrue(growthCard.waitForExistence(timeout: 5))
        growthCard.tap()

        let growthScore = app.descendants(matching: .any)["home.growth.score"]
        let goalDescription = app.descendants(matching: .any)["home.growth.goal"]
        XCTAssertTrue(growthScore.waitForExistence(timeout: 5))
        XCTAssertTrue(goalDescription.waitForExistence(timeout: 5))
        XCTAssertEqual(growthScore.label, "Growth 0 / 100")
        XCTAssertEqual(goalDescription.label, "근력 목표 · 12주 중 1주차")
        XCTAssertTrue(app.staticTexts["EMPTY BAR"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "H2 growth screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
