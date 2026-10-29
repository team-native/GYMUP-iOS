import XCTest
@testable import GYMUP

@MainActor
final class WorkoutSettingsTests: XCTestCase {
    func testSettingsSurviveRecreation() throws {
        let suite = "settings-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = WorkoutSettings(defaults: defaults, schedulesNotifications: false)
        settings.restSeconds = 120
        settings.preferences.hapticsEnabled = false
        settings.preferences.restTimerEnabled = false
        settings.preferences.workoutReminderEnabled = false
        settings.schedule.weekdays = [3, 7]
        let restored = WorkoutSettings(defaults: defaults, schedulesNotifications: false)
        XCTAssertEqual(restored.restSeconds, 120)
        XCTAssertFalse(restored.preferences.hapticsEnabled)
        XCTAssertFalse(restored.preferences.restTimerEnabled)
        XCTAssertFalse(restored.preferences.workoutReminderEnabled)
        XCTAssertEqual(restored.schedule.weekdays, [3, 7])
    }

    func testReminderComponentsUseSelectedWeekdaysAndTimeOnly() throws {
        let time = try XCTUnwrap(Calendar.current.date(from: DateComponents(hour: 21, minute: 35)))
        let components = WorkoutSettings.reminderComponents(schedule: ProfileReminderSchedule(weekdays: [1, 4], time: time))
        XCTAssertEqual(components.map(\.weekday), [4, 1])
        XCTAssertTrue(components.allSatisfy { $0.hour == 21 && $0.minute == 35 && $0.day == nil })
        XCTAssertTrue(WorkoutSettings.reminderComponents(schedule: ProfileReminderSchedule(weekdays: [], time: time)).isEmpty)
    }
}
