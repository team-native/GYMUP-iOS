import XCTest

final class PlateCalculatorFlowUITests: XCTestCase {
    func testRestScreenOpensAndClosesPlateCalculator() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["루틴"].waitForExistence(timeout: 15))
        app.buttons["루틴"].tap()
        let start = app.buttons["routine.start.upper-a"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        let prompt = app.buttons["바로 시작"]
        if prompt.waitForExistence(timeout: 5) { prompt.tap() }
        let action = app.buttons["workout.train.primary-action"]
        XCTAssertTrue(action.waitForExistence(timeout: 10))
        action.tap()
        let calculator = app.buttons["workout.plate.open"]
        XCTAssertTrue(calculator.waitForExistence(timeout: 5))
        calculator.tap()
        XCTAssertTrue(app.staticTexts["원판 계산"].waitForExistence(timeout: 5))
        let close = app.buttons["workout.plate.close"]
        if !close.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "W10-plate-calculator"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        close.tap()
        XCTAssertTrue(app.buttons["workout.rest.skip"].waitForExistence(timeout: 5))
    }
}
