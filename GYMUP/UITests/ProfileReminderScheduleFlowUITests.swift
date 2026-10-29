import XCTest

final class ProfileReminderScheduleFlowUITests: XCTestCase {
    func testReminderScheduleMatchesDesignAndPersistsSelectedWeekday() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launchArguments += ["--uitest-ephemeral", "--uitest-reset-settings"]
        app.launch()

        let myTab = app.buttons["마이"]
        XCTAssertTrue(myTab.waitForExistence(timeout: 15))
        myTab.tap()
        let notificationRow = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "알림 설정,")
        ).firstMatch
        XCTAssertTrue(notificationRow.waitForExistence(timeout: 10))
        notificationRow.tap()

        let scheduleRow = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "일정,")
        ).firstMatch
        XCTAssertTrue(scheduleRow.waitForExistence(timeout: 10))
        scheduleRow.tap()

        XCTAssertTrue(app.staticTexts["리마인더 일정"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["언제 알려드릴까요?"].exists)
        XCTAssertTrue(app.staticTexts["주 3회 목표에 맞춰 월 · 수 · 금을 추천했어요."].exists)
        let hourWheel = app.descendants(matching: .any)["reminder.hourPicker"]
        XCTAssertTrue(hourWheel.waitForExistence(timeout: 5))
        let selectedHour = app.buttons["reminder.hourPicker.7"]
        XCTAssertTrue(selectedHour.isHittable)
        XCTAssertEqual(selectedHour.frame.midY, hourWheel.frame.midY, accuracy: 2)
        XCTAssertFalse(app.buttons["홈"].exists)
        XCTAssertTrue(app.buttons["reminder.save"].isHittable)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "S5-reminder-schedule"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["reminder.hourPicker.8"].tap()
        XCTAssertEqual(hourWheel.value as? String, "8")

        let tuesday = app.buttons["화요일"]
        XCTAssertEqual(tuesday.value as? String, "선택 안 됨")
        tuesday.tap()
        XCTAssertEqual(tuesday.value as? String, "선택됨")
        XCTAssertEqual(hourWheel.value as? String, "8")
        hourWheel.swipeUp()
        let draggedHour = hourWheel.value as? String
        XCTAssertNotEqual(draggedHour, "8")
        app.buttons["reminder.save"].tap()
        XCTAssertTrue(app.staticTexts["알림 설정"].waitForExistence(timeout: 5))

        app.buttons["뒤로"].tap()
        notificationRow.tap()
        scheduleRow.tap()
        XCTAssertEqual(app.buttons["화요일"].value as? String, "선택됨")
        XCTAssertEqual(hourWheel.value as? String, draggedHour)
    }
}
