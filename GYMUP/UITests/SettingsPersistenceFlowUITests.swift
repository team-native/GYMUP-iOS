import XCTest

final class SettingsPersistenceFlowUITests: XCTestCase {
    func testHapticsSettingSurvivesAppRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES", "--uitest-ephemeral"]
        app.launch()
        XCTAssertTrue(app.buttons["마이"].waitForExistence(timeout: 15))
        app.buttons["마이"].tap()
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "알림 설정,")).firstMatch
        row.tap()
        let haptics = app.switches["햅틱"]
        XCTAssertTrue(haptics.waitForExistence(timeout: 5))
        let original = haptics.value as? String
        haptics.tap()
        let changed = haptics.value as? String
        XCTAssertNotEqual(changed, original)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["마이"].waitForExistence(timeout: 15))
        app.buttons["마이"].tap()
        row.tap()
        XCTAssertTrue(haptics.waitForExistence(timeout: 5))
        XCTAssertEqual(haptics.value as? String, changed)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "S3-setting-retained-after-relaunch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        haptics.tap()
        XCTAssertEqual(haptics.value as? String, original)
    }
}
