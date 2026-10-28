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
    func testRoutineContainingTimedExerciseCanStart() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launch()
        let routineTab = app.buttons["루틴"]
        XCTAssertTrue(routineTab.waitForExistence(timeout: 15))
        routineTab.tap()
        let start = app.buttons["routine.start.lower-b"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        XCTAssertTrue(app.buttons["workout.quit"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "스쿼트")).firstMatch.exists)
    }

    func testHistoryOpensGrowthGraphFromWorkoutRecords() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES", "--uitest-g5-growth"]
        app.launch()

        let openGrowth = app.buttons["history.openGrowth"]
        XCTAssertTrue(openGrowth.waitForExistence(timeout: 15))
        while !openGrowth.isHittable {
            app.swipeUp()
        }
        openGrowth.tap()

        let exercisePicker = app.buttons["history.growth.exercise"]
        XCTAssertTrue(exercisePicker.waitForExistence(timeout: 5))
        exercisePicker.tap()
        app.buttons["벤치프레스"].tap()
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "최고 무게 62.5 KG")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts["V2 · MVP 제외"].exists)

        app.buttons["history.growth.metric.예상 1RM"].tap()
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "예상 1RM 79.2 KG")).firstMatch.exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "G5 growth graph with workout records"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
