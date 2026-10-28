import XCTest
@testable import GYMUP

final class HistoryGrowthRecordDataTests: XCTestCase {
    func testActualExerciseSetsDetermineGraphValues() throws {
        let record = try XCTUnwrap(HistorySampleData.records.first)
        let points = HistoryGrowthRecordData.points(from: [record], exercise: "벤치프레스", metric: .maxWeight)
        XCTAssertEqual(try XCTUnwrap(points.first).value, 62.5, accuracy: 0.001)
        XCTAssertTrue(HistoryGrowthRecordData.points(from: [record], exercise: "없는 운동", metric: .volume).isEmpty)
    }

    func testSelectedDateRangeFiltersByDateNotPointCount() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let points = [HistoryGrowthDataPoint(date: now.addingTimeInterval(-29 * 86_400), value: 1),
                      HistoryGrowthDataPoint(date: now.addingTimeInterval(-10 * 86_400), value: 2),
                      HistoryGrowthDataPoint(date: now.addingTimeInterval(-5 * 86_400), value: 3)]
        XCTAssertEqual(HistoryGrowthRange.fourWeeks.recordedPoints(from: points, now: now).map(\.value), [2, 3])
    }
}
