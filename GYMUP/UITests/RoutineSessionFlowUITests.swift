import XCTest

final class RoutineSessionFlowUITests: XCTestCase {
    func testSelectedRoutineOpensItsFirstExercise() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launchArguments += ["--uitest-ephemeral"]
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
        app.launchArguments += ["--uitest-ephemeral"]
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

    func testTimedPlankCompletesRestAndSavesHistory() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launchArguments += ["--uitest-ephemeral"]
        app.launch()
        let routineTab = app.buttons["루틴"]
        XCTAssertTrue(routineTab.waitForExistence(timeout: 15))
        routineTab.tap()

        let start = app.buttons["routine.start.lower-b"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        startExerciseIfPrompted(in: app)
        XCTAssertTrue(app.buttons["workout.train.primary-action"].waitForExistence(timeout: 10))

        let exercisesBeforePlank = [4, 3, 3, 3]
        for setCount in exercisesBeforePlank {
            for setNumber in 1...setCount {
                let completeSet = app.buttons["workout.set.\(setNumber).complete"]
                XCTAssertTrue(completeSet.waitForExistence(timeout: 5))
                completeSet.tap()
                if setNumber < setCount {
                    tapRestSkip(in: app)
                }
            }

            let nextExercise = app.buttons["workout.complete.next-exercise"]
            XCTAssertTrue(nextExercise.waitForExistence(timeout: 5))
            nextExercise.tap()
            startExerciseIfPrompted(in: app)
        }

        XCTAssertTrue(app.staticTexts["SET 1 · SECS"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["45"].exists)
        tapSetCompletion(1, expectsRest: true, in: app)

        let restCountdown = app.staticTexts["workout.rest.countdown"]
        XCTAssertTrue(restCountdown.waitForExistence(timeout: 5))
        XCTAssertTrue(restCountdown.label.contains("초"))
        tapRestSkip(in: app)

        tapSetCompletion(2, expectsRest: true, in: app)
        tapRestSkip(in: app)
        tapSetCompletion(3, expectsRest: false, in: app)

        let summaryDone = app.buttons["완료"]
        XCTAssertTrue(summaryDone.waitForExistence(timeout: 15))
        summaryDone.tap()
        advanceCompletionRewards(in: app)
        assertPlankIsSavedInHistory(in: app)
    }

    private func assertPlankIsSavedInHistory(in app: XCUIApplication) {
        let historyTab = app.buttons["기록"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
        historyTab.tap()
        let savedWorkout = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "history.record.")
        ).firstMatch
        XCTAssertTrue(savedWorkout.waitForExistence(timeout: 10))
        savedWorkout.tap()
        let expandExercises = app.buttons["운동 종목 더 보기"]
        XCTAssertTrue(expandExercises.waitForExistence(timeout: 5))
        expandExercises.tap()
        let plankRecord = app.descendants(matching: .any)["history.detail.exercise.5"]
        let detailScroll = app.scrollViews.firstMatch
        XCTAssertTrue(detailScroll.waitForExistence(timeout: 5))
        for _ in 0..<5 where !plankRecord.exists {
            detailScroll.swipeUp()
        }
        XCTAssertTrue(plankRecord.waitForExistence(timeout: 5))
    }

    private func startExerciseIfPrompted(in app: XCUIApplication) {
        // The prompt container currently exposes its identifier to both child buttons,
        // so use the visible action label until the container's accessibility is fixed.
        let start = app.buttons["바로 시작"]
        if start.waitForExistence(timeout: 5) {
            start.tap()
        }
    }

    private func tapSetCompletion(_ setNumber: Int, expectsRest: Bool, in app: XCUIApplication) {
        let completeSet = app.buttons["workout.train.primary-action"]
        XCTAssertTrue(completeSet.waitForExistence(timeout: 10))
        completeSet.tap()
        if expectsRest {
            XCTAssertTrue(app.buttons["workout.rest.skip"].waitForExistence(timeout: 5), "SET \(setNumber) 완료 후 휴식 화면이 표시되어야 함")
        }
    }

    private func advanceCompletionRewards(in app: XCUIApplication) {
        let levelUpContinue = app.buttons["workout.completion.level-up.continue"]
        if levelUpContinue.waitForExistence(timeout: 3) {
            levelUpContinue.tap()
        }

        // Like the first-exercise prompt, this screen exposes the container ID on its button.
        let stageUpContinue = app.buttons["계속"]
        if stageUpContinue.waitForExistence(timeout: 3) {
            stageUpContinue.tap()
        }

        let finish = app.buttons["운동 완료"]
        if finish.waitForExistence(timeout: 3) {
            finish.tap()
        }
    }

    private func tapRestSkip(in app: XCUIApplication) {
        let skip = app.buttons["workout.rest.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func testHistoryOpensGrowthGraphFromWorkoutRecords() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES", "--uitest-g5-growth"]
        app.launchArguments += ["--uitest-ephemeral"]
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
        app.launchArguments += ["--uitest-ephemeral"]
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
