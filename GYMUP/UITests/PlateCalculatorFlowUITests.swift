import XCTest

final class PlateCalculatorFlowUITests: XCTestCase {
    func testRestScreenOpensAndClosesPlateCalculator() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["루틴"].waitForExistence(timeout: 15))
        app.buttons["루틴"].tap()
        let card = app.buttons["routine.card.upper-a"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        let start = app.buttons["운동 시작"]
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
        XCTAssertTrue(app.buttons["workout.plate.close"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "W10-plate-calculator"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["workout.plate.close"].tap()
        XCTAssertTrue(app.buttons["workout.rest.skip"].waitForExistence(timeout: 5))
    }
}
