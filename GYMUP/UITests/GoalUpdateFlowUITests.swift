import XCTest

final class GoalUpdateFlowUITests: XCTestCase {
    func testGoalCreatedFromGrowthUpdatesOnReturnAndAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES", "--uitest-ephemeral",
                               "-onboarding.experience", "1", "-onboarding.purposes", "테스트", "-onboarding.frequency", "3"]
        app.launch()
        let growth = app.buttons["home.growth"]
        XCTAssertTrue(growth.waitForExistence(timeout: 15))
        growth.tap()
        app.buttons["성장 기록"].tap()
        XCTAssertTrue(app.buttons["새 목표"].waitForExistence(timeout: 5))
        app.buttons["새 목표"].tap()
        let strength = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "근력,")).firstMatch
        XCTAssertTrue(strength.waitForExistence(timeout: 5))
        strength.tap()
        app.buttons["목표 기간 8주"].tap()
        app.buttons["목표 시작하기"].tap()
        XCTAssertTrue(app.staticTexts["목표 히스토리"].waitForExistence(timeout: 5))
        app.buttons["뒤로"].tap()
        let description = app.descendants(matching: .any)["home.growth.goal"]
        XCTAssertTrue(description.waitForExistence(timeout: 5))
        XCTAssertTrue(description.label.contains("근력 목표 · 8주"))
        app.terminate()
        app.launch()
        XCTAssertTrue(growth.waitForExistence(timeout: 15))
        growth.tap()
        XCTAssertTrue(description.waitForExistence(timeout: 5))
        XCTAssertTrue(description.label.contains("근력 목표 · 8주"))
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "H2-new-goal-restored"
        image.lifetime = .keepAlways
        add(image)
    }
}
