import Foundation

struct HistoryAlbumData {
    let hasRecords: Bool
    let exerciseOptions: [String]
    let months: [HistoryAlbumSection]

    init(
        records: [WorkoutRecord],
        selectedExercise: String? = nil,
        calendar: Calendar = .current
    ) {
        hasRecords = !records.isEmpty
        exerciseOptions = Array(Set(records.flatMap { $0.exercises.map(\.name) }))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

        let filteredRecords = records.filter { record in
            guard let selectedExercise else { return true }
            return record.exercises.contains { $0.name == selectedExercise }
        }
        let grouped = Dictionary(grouping: filteredRecords) { record in
            calendar.dateInterval(of: .month, for: record.date)?.start ?? record.date
        }
        let includesYear = Set(filteredRecords.map { calendar.component(.year, from: $0.date) }).count > 1
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = includesYear ? "yyyy년 M월" : "M월"

        months = grouped.keys.sorted(by: >).compactMap { monthStart in
            guard let monthRecords = grouped[monthStart]?.sorted(by: { $0.date > $1.date }) else { return nil }
            return HistoryAlbumSection(
                monthStart: monthStart,
                title: formatter.string(from: monthStart),
                records: monthRecords
            )
        }
    }
}

struct HistoryAlbumSection: Identifiable {
    var id: Date { monthStart }
    let monthStart: Date
    let title: String
    let records: [WorkoutRecord]
}
