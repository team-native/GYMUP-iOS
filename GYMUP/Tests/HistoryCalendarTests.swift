import XCTest
@testable import GYMUP

final class HistoryCalendarTests: XCTestCase {
    func testMonthlySummaryUsesUniqueWorkoutDaysAndCurrentMonthRecords() {
        let records = HistoryListSampleData.records(inMonthOf: HistoryListSampleData.sampleMonth)
        let summary = HistoryCalendarSummary(records: records)

        XCTAssertEqual(summary.workoutDays, 6)
    }

    @MainActor
    func testSelectedCalendarDateReturnsEveryWorkoutOnThatDay() throws {
        let date = HistoryListSampleData.date(day: 3, inMonthOf: HistoryListSampleData.sampleMonth)
        let store = HistoryStore(records: HistoryListSampleData.records)

        XCTAssertEqual(store.records(on: date).count, 2)
        XCTAssertTrue(store.records(inMonthOf: date).contains { Calendar.current.isDate($0.date, inSameDayAs: date) })
    }

    @MainActor
    func testDateWithoutWorkoutHasNoCalendarRecords() {
        let date = HistoryListSampleData.date(day: 4, inMonthOf: HistoryListSampleData.sampleMonth)
        let store = HistoryStore(records: HistoryListSampleData.records)

        XCTAssertTrue(store.records(on: date).isEmpty)
    }
}
