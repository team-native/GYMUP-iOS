import Foundation

struct HistoryComparisonSelection: Equatable {
    let beforeRecordID: UUID
    let afterRecordID: UUID
}

struct HistoryComparisonData {
    let records: [WorkoutRecord]

    init(records: [WorkoutRecord]) {
        self.records = records.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.date == rhs.element.date {
                    return lhs.offset < rhs.offset
                }
                return lhs.element.date < rhs.element.date
            }
            .map(\.element)
    }

    func initialSelection(preferredAfterRecordID: UUID? = nil) -> HistoryComparisonSelection? {
        guard records.count > 1 else { return nil }

        let preferredIndex = preferredAfterRecordID.flatMap { id in
            records.firstIndex { $0.id == id }
        }
        let afterIndex = preferredIndex.flatMap { $0 > 0 ? $0 : nil } ?? records.count - 1
        return selection(beforeRecordID: records[afterIndex - 1].id, afterRecordID: records[afterIndex].id)
    }

    func beforeChoices(forAfterRecordID afterRecordID: UUID) -> [WorkoutRecord] {
        guard let afterIndex = records.firstIndex(where: { $0.id == afterRecordID }) else { return [] }
        return Array(records[..<afterIndex])
    }

    func afterChoices(forBeforeRecordID beforeRecordID: UUID) -> [WorkoutRecord] {
        guard let beforeIndex = records.firstIndex(where: { $0.id == beforeRecordID }) else { return [] }
        return Array(records.dropFirst(beforeIndex + 1))
    }

    func selection(
        beforeRecordID: UUID,
        afterRecordID: UUID
    ) -> HistoryComparisonSelection? {
        guard
            let beforeIndex = records.firstIndex(where: { $0.id == beforeRecordID }),
            let afterIndex = records.firstIndex(where: { $0.id == afterRecordID }),
            beforeIndex < afterIndex
        else {
            return nil
        }

        return HistoryComparisonSelection(beforeRecordID: beforeRecordID, afterRecordID: afterRecordID)
    }

    func record(with id: UUID) -> WorkoutRecord? {
        records.first { $0.id == id }
    }
}
