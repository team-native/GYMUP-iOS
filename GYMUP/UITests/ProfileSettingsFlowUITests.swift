import XCTest

final class ProfileSettingsFlowUITests: XCTestCase {
    func testMyProfileSettingsScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", "YES"]
        app.launch()

        let myTab = app.buttons["마이"]
        XCTAssertTrue(myTab.waitForExistence(timeout: 15))
        myTab.tap()

        XCTAssertTrue(app.staticTexts["마이"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "운동 목표")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "기본 휴식 시간")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "알림 설정")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "카메라 · 사진 권한")).firstMatch.exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "S1-my-settings"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
