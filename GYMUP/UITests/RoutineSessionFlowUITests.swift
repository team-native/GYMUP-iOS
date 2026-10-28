import XCTest

final class RoutineSessionFlowUITests: XCTestCase {
    func testSelectedRoutineOpensItsFirstExercise() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launch()
        let routineTab = app.buttons["루틴"]
        XCTAssertTrue(routineTab.waitForExistence(timeout: 15))
        routineTab.tap()
        let start = app.buttons["routine.start.upper-a"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        let promptStart = app.buttons["workout.first-exercise.start"]
        if promptStart.waitForExistence(timeout: 3) { promptStart.tap() }
        XCTAssertTrue(app.buttons["workout.quit"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["벤치프레스"].exists)
    }
}
