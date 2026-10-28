import XCTest

final class ProfileNotificationSettingsFlowUITests: XCTestCase {
    func testNotificationSettingsMatchDesignAndRetainToggleOnReturn() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launch()

        let myTab = app.buttons["마이"]
        XCTAssertTrue(myTab.waitForExistence(timeout: 15))
        myTab.tap()

        let settingsRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "알림 설정,")).firstMatch
        XCTAssertTrue(settingsRow.waitForExistence(timeout: 10))
        settingsRow.tap()

        XCTAssertTrue(app.staticTexts["알림 설정"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["홈"].exists)
        XCTAssertTrue(app.switches["휴식 종료 알림"].exists)
        XCTAssertTrue(app.switches["햅틱"].exists)
        XCTAssertTrue(app.switches["운동 리마인더"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "일정,")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts["알림 권한이 꺼져 있으면 위 설정이 켜져 있어도 알림이 오지 않아요."].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "S3-notification-settings"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let hapticsSwitch = app.switches["햅틱"]
        XCTAssertTrue(hapticsSwitch.waitForExistence(timeout: 5))
        let originalValue = String(describing: hapticsSwitch.value ?? "")
        hapticsSwitch.tap()
        let toggledValue = String(describing: hapticsSwitch.value ?? "")
        XCTAssertNotEqual(toggledValue, originalValue)

        app.buttons["뒤로"].tap()
        XCTAssertTrue(settingsRow.waitForExistence(timeout: 5))
        settingsRow.tap()

        let reopenedSwitch = app.switches["햅틱"]
        XCTAssertTrue(reopenedSwitch.waitForExistence(timeout: 5))
        XCTAssertEqual(String(describing: reopenedSwitch.value ?? ""), toggledValue)

    }
}
