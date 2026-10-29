import XCTest

final class OnboardingFlowUITests: XCTestCase {
    func testOnboardingMovesThroughAllScreensAndEntersHome() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-reset-onboarding"]
        app.launchArguments += ["--uitest-ephemeral"]
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
        app.buttons["마이"].tap()
        XCTAssertTrue(app.staticTexts["체형 · 12주 · 주 4회"].waitForExistence(timeout: 5))

        let workoutGoalRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "운동 목표")
        ).firstMatch
        XCTAssertTrue(workoutGoalRow.waitForExistence(timeout: 5))
        workoutGoalRow.tap()
        XCTAssertTrue(app.staticTexts["목표 히스토리"].waitForExistence(timeout: 5))
        app.buttons["뒤로"].tap()
        XCTAssertTrue(workoutGoalRow.waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = []
        app.launchArguments += ["--uitest-ephemeral"]
        app.launch()
        XCTAssertTrue(app.buttons["홈"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["시작하기"].exists)
    }

    func testMyProfileRemainsAccessibleAtLargeTextSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
            "-onboarding.completed", "YES"
        ]
        app.launchArguments += ["--uitest-ephemeral"]
        app.launch()

        XCTAssertTrue(app.buttons["홈"].waitForExistence(timeout: 15))
        let myTab = app.buttons["마이"]
        XCTAssertTrue(myTab.waitForExistence(timeout: 15))
        myTab.tap()

        let profileTitle = app.staticTexts["마이"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 5))

        let goalRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "운동 목표")).firstMatch
        let restTimeRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "기본 휴식 시간")).firstMatch
        let notificationRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "알림 설정")).firstMatch
        let photoRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "카메라 · 사진 권한")).firstMatch
        let playlistRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "루틴별 플레이리스트")).firstMatch

        XCTAssertTrue(goalRow.exists)
        XCTAssertTrue(restTimeRow.exists)
        XCTAssertTrue(notificationRow.exists)
        XCTAssertTrue(photoRow.exists)
        XCTAssertTrue(playlistRow.exists)
        XCTAssertTrue(myTab.isHittable)

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
        let topScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        topScreenshot.name = "S1-accessibility-xxxl-top"
        topScreenshot.lifetime = .keepAlways
        add(topScreenshot)

        for _ in 0..<8 {
            if playlistRow.frame.maxY <= myTab.frame.minY { break }
            scrollView.swipeUp()
        }
        print("S1 playlist frame: \(playlistRow.frame); My tab frame: \(myTab.frame)")
        XCTAssertLessThanOrEqual(playlistRow.frame.maxY, myTab.frame.minY)
        XCTAssertTrue(playlistRow.isHittable)
        XCTAssertTrue(myTab.isHittable)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "S1-accessibility-xxxl-scrolled"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
