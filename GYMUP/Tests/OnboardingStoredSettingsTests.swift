import XCTest
@testable import GYMUP

final class OnboardingStoredSettingsTests: XCTestCase {
    func testLoadsOnlyCompletedValidSelections() throws {
        let suite = "gymup.onboarding.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(1, forKey: "onboarding.experience")
        defaults.set("근비대,근력 향상", forKey: "onboarding.purposes")
        defaults.set(4, forKey: "onboarding.frequency")
        defaults.set(1, forKey: "onboarding.goal")
        defaults.set(12, forKey: "onboarding.weeks")
        XCTAssertNil(OnboardingStoredSettings.load(from: defaults))
        defaults.set(true, forKey: "onboarding.completed")
        let settings = try XCTUnwrap(OnboardingStoredSettings.load(from: defaults))
        XCTAssertEqual(settings.frequency, 4)
        XCTAssertEqual(settings.goal, 1)
        XCTAssertEqual(settings.purposes, ["근비대", "근력 향상"])
        defaults.set(9, forKey: "onboarding.frequency")
        XCTAssertNil(OnboardingStoredSettings.load(from: defaults))
    }
}
