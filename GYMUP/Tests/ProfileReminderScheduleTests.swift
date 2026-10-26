import XCTest
@testable import GYMUP

final class ProfileReminderScheduleTests: XCTestCase {
    func testDefaultScheduleMatchesS5Recommendation() {
        let schedule = ProfileReminderSchedule()

        XCTAssertEqual(schedule.weekdays, [2, 4, 6])
        XCTAssertEqual(schedule.selectedWeekdaySummary, "월 · 수 · 금")
        XCTAssertEqual(schedule.summary, "월 · 수 · 금 오후 7:00")
    }

    func testWeekdaySummaryUsesMondayFirstOrder() {
        var schedule = ProfileReminderSchedule()
        schedule.weekdays = [1, 3]

        XCTAssertEqual(schedule.selectedWeekdaySummary, "화 · 일")
        XCTAssertEqual(schedule.summary, "화 · 일 오후 7:00")
    }

    func testSelectingEveryWeekdayUsesDailySummary() {
        var schedule = ProfileReminderSchedule()
        schedule.weekdays = Set(ProfileReminderSchedule.weekdayOrder)

        XCTAssertEqual(schedule.selectedWeekdaySummary, "매일")
        XCTAssertEqual(schedule.summary, "매일 오후 7:00")
    }

    func testClearingAllWeekdaysRemovesTheReminderSummary() {
        var schedule = ProfileReminderSchedule()
        schedule.weekdays.removeAll()

        XCTAssertFalse(schedule.isEnabled)
        XCTAssertEqual(schedule.selectedWeekdaySummary, "")
        XCTAssertEqual(schedule.summary, "일정 없음")
    }

    func testWeekdayCanBeAddedAfterScheduleWasCleared() {
        var schedule = ProfileReminderSchedule(weekdays: [], time: .now)

        schedule.toggleWeekday(3)

        XCTAssertTrue(schedule.isEnabled)
        XCTAssertEqual(schedule.selectedWeekdaySummary, "화")
    }

    func testTogglingAWeekdayRemovesAndRestoresIt() {
        var schedule = ProfileReminderSchedule()

        schedule.toggleWeekday(4)
        XCTAssertFalse(schedule.weekdays.contains(4))

        schedule.toggleWeekday(4)
        XCTAssertTrue(schedule.weekdays.contains(4))
    }

    func testInvalidWeekdayDoesNotChangeSchedule() {
        var schedule = ProfileReminderSchedule()
        let originalWeekdays = schedule.weekdays

        schedule.toggleWeekday(8)

        XCTAssertEqual(schedule.weekdays, originalWeekdays)
    }
}
