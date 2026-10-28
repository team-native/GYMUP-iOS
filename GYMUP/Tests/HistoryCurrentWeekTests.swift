import XCTest
@testable import GYMUP

final class HistoryCurrentWeekTests: XCTestCase {
    @MainActor
    func testCurrentWeekIncludesStartAndExcludesNextWeek() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        calendar.firstWeekday = 2
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let week = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: now))
        let plan = WorkoutSessionPlan.sample(for: "upper-a")
        let start = WorkoutSessionCompletionDataFactory.makeHistoryRecord(plan: plan, elapsedSeconds: 60,
                                                                          completedAt: week.start)
        let end = WorkoutSessionCompletionDataFactory.makeHistoryRecord(plan: plan, elapsedSeconds: 60,
                                                                        completedAt: week.end)
        let store = HistoryStore(records: [start, end])
        XCTAssertEqual(store.recordsInCurrentWeek(now: now, calendar: calendar).map(\.id), [start.id])
    }
}
