import UserNotifications
import XCTest
@testable import GYMUP

final class ProfileNotificationPermissionStateTests: XCTestCase {
    func testSystemAuthorizationStatusesMapToPermissionState() {
        XCTAssertEqual(ProfileNotificationAuthorizationState(.notDetermined), .notDetermined)
        XCTAssertEqual(ProfileNotificationAuthorizationState(.denied), .denied)
        XCTAssertEqual(ProfileNotificationAuthorizationState(.authorized), .allowed)
        XCTAssertEqual(ProfileNotificationAuthorizationState(.provisional), .allowed)
        XCTAssertEqual(ProfileNotificationAuthorizationState(.ephemeral), .allowed)
    }

    func testPermissionBannerIsHiddenOnlyWhenNotificationsAreAllowed() {
        XCTAssertTrue(ProfileNotificationAuthorizationState.notDetermined.shouldShowPermissionBanner)
        XCTAssertTrue(ProfileNotificationAuthorizationState.denied.shouldShowPermissionBanner)
        XCTAssertTrue(ProfileNotificationAuthorizationState.unknown.shouldShowPermissionBanner)
        XCTAssertFalse(ProfileNotificationAuthorizationState.allowed.shouldShowPermissionBanner)
    }

    func testNotificationSettingStatesHaveExpectedDisplayValues() {
        XCTAssertEqual(ProfileNotificationSettingState(.enabled).displayValue, "켜짐")
        XCTAssertEqual(ProfileNotificationSettingState(.disabled).displayValue, "꺼짐")
        XCTAssertEqual(ProfileNotificationSettingState(.notSupported).displayValue, "—")
    }

    func testPermissionSnapshotMapsAlertSettingToBannerRow() {
        let snapshot = ProfileNotificationPermissionSnapshot(
            authorizationStatus: .authorized,
            lockScreenSetting: .enabled,
            alertSetting: .disabled
        )

        XCTAssertEqual(snapshot.authorization, .allowed)
        XCTAssertEqual(snapshot.lockScreen, .enabled)
        XCTAssertEqual(snapshot.banner, .disabled)
    }

    func testDeniedAuthorizationShowsUnavailableCategoryStates() {
        let snapshot = ProfileNotificationPermissionSnapshot(
            authorizationStatus: .denied,
            lockScreenSetting: .enabled,
            alertSetting: .enabled
        )

        XCTAssertEqual(snapshot.lockScreen, .unavailable)
        XCTAssertEqual(snapshot.banner, .unavailable)
    }
}
