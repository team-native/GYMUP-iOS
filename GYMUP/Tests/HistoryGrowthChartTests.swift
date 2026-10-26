import XCTest
@testable import GYMUP

final class HistoryGrowthChartTests: XCTestCase {
    func testRangesFilterMonthlySamplesToTheirExpectedPeriods() {
        let anchorDate = date(year: 2026, month: 10, day: 26)
        let samples = HistoryGrowthSampleData.points(
            for: .maxWeight,
            exercise: "벤치프레스",
            anchorDate: anchorDate
        )

        XCTAssertEqual(samples.count, 11)
        XCTAssertEqual(HistoryGrowthRange.fourWeeks.points(from: samples).count, 1)
        XCTAssertEqual(HistoryGrowthRange.twelveWeeks.points(from: samples).count, 4)
        XCTAssertEqual(HistoryGrowthRange.sixMonths.points(from: samples).count, 7)
        XCTAssertEqual(HistoryGrowthRange.all.points(from: samples).count, 11)
    }

    func testSampleValuesReflectTheSelectedExerciseAndMetric() throws {
        let anchorDate = date(year: 2026, month: 10, day: 26)
        let benchPress = HistoryGrowthSampleData.points(
            for: .maxWeight,
            exercise: "벤치프레스",
            anchorDate: anchorDate
        )
        let squat = HistoryGrowthSampleData.points(
            for: .maxWeight,
            exercise: "스쿼트",
            anchorDate: anchorDate
        )
        let benchPressOneRepMax = HistoryGrowthSampleData.points(
            for: .estimatedOneRepMax,
            exercise: "벤치프레스",
            anchorDate: anchorDate
        )

        XCTAssertEqual(try XCTUnwrap(benchPress.last).value, 62.5, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(squat.last).value, 90, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(benchPressOneRepMax.last).value, 70, accuracy: 0.001)
    }

    func testChartAvailabilitySupportsEmptySparseAndReadySeries() {
        let point = HistoryGrowthDataPoint(date: date(year: 2026, month: 10, day: 26), value: 62.5)

        XCTAssertEqual(HistoryGrowthChartAvailability(points: []), .empty)
        XCTAssertEqual(HistoryGrowthChartAvailability(points: [point]), .sparse)
        XCTAssertEqual(HistoryGrowthChartAvailability(points: [point, point]), .ready)
    }

    func testAxisLabelsSpanVisibleChartPoints() {
        let samples = HistoryGrowthSampleData.points(
            for: .maxWeight,
            exercise: "벤치프레스",
            anchorDate: date(year: 2026, month: 10, day: 26)
        )
        let visiblePoints = HistoryGrowthRange.twelveWeeks.points(from: samples)
        let labels = HistoryGrowthRange.twelveWeeks.axisLabels(for: visiblePoints)

        XCTAssertEqual(labels.first?.position, 0)
        XCTAssertEqual(labels.last?.position, 1)
        XCTAssertEqual(labels.count, visiblePoints.count)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}
