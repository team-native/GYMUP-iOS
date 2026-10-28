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

    func testCompletionSummaryShowsCurrentSessionAndWeeklyProgress() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES", "--uitest-e1-completion"]
        app.launch()

        let growth = app.descendants(matching: .any)["workout.completion.growth"]
        XCTAssertTrue(growth.waitForExistence(timeout: 15))
        XCTAssertTrue(growth.label.contains("성장도 2에서"), growth.label)
        XCTAssertTrue(growth.label.contains("상승"), growth.label)
        let experience = app.staticTexts["workout.completion.xp"]
        XCTAssertTrue(experience.waitForExistence(timeout: 5))
        XCTAssertEqual(experience.label, "+535 XP")

        let weeklyGoal = app.descendants(matching: .any)["workout.completion.weekly-goal"]
        XCTAssertTrue(weeklyGoal.waitForExistence(timeout: 5))
        XCTAssertTrue(weeklyGoal.label.contains("주간 목표 3/3 달성"), weeklyGoal.label)
        XCTAssertFalse(app.staticTexts["LV.17 → 18"].exists)
        XCTAssertTrue(app.buttons["오운완 사진"].exists)
        XCTAssertTrue(app.buttons["완료"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "E1 completion summary with actual progress"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
