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
        let promptStart = app.buttons["바로 시작"]
        if promptStart.waitForExistence(timeout: 3) { promptStart.tap() }
        if !app.buttons["workout.quit"].waitForExistence(timeout: 5) {
            print(app.debugDescription)
            XCTFail("운동 화면이 표시되지 않음")
        }
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "벤치프레스")).firstMatch.exists)
    }
}
