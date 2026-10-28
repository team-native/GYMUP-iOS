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
        XCTAssertFalse(app.buttons["홈"].exists)
        exercisePicker.tap()
        app.buttons["벤치프레스"].tap()
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "최고 무게 62.5 KG")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts["V2 · MVP 제외"].exists)

        app.buttons["history.growth.metric.예상 1RM"].tap()
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "예상 1RM 79.2 KG")).firstMatch.exists)

        let fourWeekRange = app.buttons["history.growth.range.4주"]
        if !fourWeekRange.isHittable { app.swipeUp() }
        fourWeekRange.tap()
        XCTAssertTrue(fourWeekRange.isSelected)
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "기간 내 첫 기록보다 +9.5KG")).firstMatch.exists)

        let allTimeRange = app.buttons["history.growth.range.전체"]
        allTimeRange.tap()
        XCTAssertTrue(allTimeRange.isSelected)
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "첫 기록보다 +15.8KG")).firstMatch.exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "G5 growth graph with workout records"
        screenshot.lifetime = .keepAlways
        add(screenshot)
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
