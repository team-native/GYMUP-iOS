import XCTest
@testable import GYMUP

final class HistoryWorkoutDetailTests: XCTestCase {
    func testG1DetailExercisesMatchSummarySetAndPersonalRecordCounts() {
        for record in HistoryListSampleData.records {
            let detailSets = record.exercises.flatMap(\.sets)

            XCTAssertEqual(detailSets.count, record.setCount, "Set total mismatch for \(record.routineName)")
            XCTAssertEqual(
                detailSets.filter(\.isPersonalRecord).count,
                record.growth,
                "Personal record total mismatch for \(record.routineName)"
            )
        }
    }

    func testG1UpperBodyDetailContainsAllEighteenSetsAndTwoPersonalRecords() throws {
        let workoutDate = HistoryListSampleData.date(day: 11, inMonthOf: HistoryListSampleData.sampleMonth)
        let record = try XCTUnwrap(HistoryListSampleData.records(on: workoutDate).first)
        let sets = record.exercises.flatMap(\.sets)

        XCTAssertEqual(record.setCount, 18)
        XCTAssertEqual(sets.count, 18)
        XCTAssertEqual(sets.filter(\.isPersonalRecord).count, 2)
        XCTAssertTrue(record.exercises.contains { $0.sets.contains(where: \.isPersonalRecord) })
    }
}
