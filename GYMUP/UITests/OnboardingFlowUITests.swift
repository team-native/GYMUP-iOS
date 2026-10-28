import XCTest

final class OnboardingFlowUITests: XCTestCase {
    func testOnboardingMovesThroughAllScreensAndEntersHome() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-reset-onboarding"]
        app.launch()

        let start = app.buttons["시작하기"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        start.tap()
        let experience = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "입문")).firstMatch
        XCTAssertTrue(experience.waitForExistence(timeout: 5))
        let next = app.buttons["다음"]
        XCTAssertFalse(next.isEnabled)
        experience.tap()
        next.tap()
        let purpose = app.buttons["근비대"]
        XCTAssertTrue(purpose.waitForExistence(timeout: 5))
        purpose.tap()
        next.tap()
        let increase = app.buttons["횟수 늘리기"]
        XCTAssertTrue(increase.waitForExistence(timeout: 5))
        increase.tap()
        next.tap()
        let startGoal = app.buttons["목표 시작하기"]
        XCTAssertTrue(startGoal.waitForExistence(timeout: 5))
        startGoal.tap()
        XCTAssertTrue(app.staticTexts["0/4"].waitForExistence(timeout: 5))
        next.tap()
        let later = app.buttons["나중에"]
        XCTAssertTrue(later.waitForExistence(timeout: 5))
        later.tap()
        XCTAssertTrue(app.buttons["홈"].waitForExistence(timeout: 5))
    }
}
