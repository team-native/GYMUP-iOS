import XCTest
@testable import GYMUP

final class HistoryWorkoutListTests: XCTestCase {
    func testG1SampleDataMatchesMonthlySummaryAndVisibleDateOrder() {
        let monthRecords = HistoryListSampleData.records(inMonthOf: HistoryListSampleData.sampleMonth)
        let calendar = Calendar.current

        XCTAssertEqual(monthRecords.count, 9)
        XCTAssertEqual(monthRecords.map { calendar.component(.day, from: $0.date) }, [11, 8, 6, 3, 3, 2, 2, 1, 1])
        XCTAssertEqual(monthRecords.reduce(0) { $0 + $1.durationMinutes }, 492)
        XCTAssertEqual(monthRecords.reduce(0) { $0 + $1.volumeKilograms }, 72_400)
    }

    func testSelectingDateKeepsMonthListAndFindsTheWorkoutForDetailNavigation() throws {
        let selectedDate = HistoryListSampleData.date(day: 8, inMonthOf: HistoryListSampleData.sampleMonth)
        let monthRecords = HistoryListSampleData.records(inMonthOf: selectedDate)
        let selectedWorkout = try XCTUnwrap(HistoryListSampleData.records(on: selectedDate).first)

        XCTAssertEqual(monthRecords.count, 9)
        XCTAssertEqual(HistoryListSampleData.record(with: selectedWorkout.id), selectedWorkout)
    }

    func testEmptyMonthHasNoG1Rows() throws {
        let previousMonth = try XCTUnwrap(
            Calendar.current.date(byAdding: .month, value: -1, to: HistoryListSampleData.sampleMonth)
        )
        let sameMonthNextYear = try XCTUnwrap(
            Calendar.current.date(byAdding: .year, value: 1, to: HistoryListSampleData.sampleMonth)
        )

        XCTAssertTrue(HistoryListSampleData.records(inMonthOf: previousMonth).isEmpty)
        XCTAssertTrue(HistoryListSampleData.records(inMonthOf: sameMonthNextYear).isEmpty)
    }
}
