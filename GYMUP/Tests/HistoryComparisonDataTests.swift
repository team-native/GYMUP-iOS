import XCTest
@testable import GYMUP

final class HistoryComparisonDataTests: XCTestCase {
    func testInitialSelectionUsesTheNewestRecordUnlessAnAfterRecordIsProvided() {
        let oldest = record(day: 1)
        let middle = record(day: 5)
        let newest = record(day: 10)
        let data = HistoryComparisonData(records: [newest, middle, oldest])

        XCTAssertEqual(
            data.initialSelection(),
            HistoryComparisonSelection(beforeRecordID: middle.id, afterRecordID: newest.id)
        )
        XCTAssertEqual(
            data.initialSelection(preferredAfterRecordID: middle.id),
            HistoryComparisonSelection(beforeRecordID: oldest.id, afterRecordID: middle.id)
        )
    }

    func testChangingEitherSideOnlyOffersChronologicallyValidDistinctRecords() {
        let oldest = record(day: 1)
        let middle = record(day: 5)
        let newest = record(day: 10)
        let data = HistoryComparisonData(records: [newest, middle, oldest])

        XCTAssertEqual(data.beforeChoices(forAfterRecordID: newest.id).map(\.id), [oldest.id, middle.id])
        XCTAssertEqual(data.afterChoices(forBeforeRecordID: middle.id).map(\.id), [newest.id])
        XCTAssertNil(data.selection(beforeRecordID: newest.id, afterRecordID: oldest.id))
        XCTAssertNil(data.selection(beforeRecordID: middle.id, afterRecordID: middle.id))
    }

    func testSelectionIsUnavailableWithFewerThanTwoRecords() {
        XCTAssertNil(HistoryComparisonData(records: []).initialSelection())
        XCTAssertNil(HistoryComparisonData(records: [record(day: 1)]).initialSelection())
    }

    private func record(day: Int) -> WorkoutRecord {
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: day)) ?? .now
        return WorkoutRecord(
            id: UUID(),
            date: date,
            routineName: "상체 A",
            category: "가슴 · 어깨 · 삼두",
            durationMinutes: 50,
            setCount: 18,
            volumeKilograms: 8_420,
            growth: 1,
            photoAssetName: "H1RoutinePhoto",
            exercises: []
        )
    }
}
