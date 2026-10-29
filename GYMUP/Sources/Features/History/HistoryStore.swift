import Foundation
import Observation

@Observable
@MainActor
final class HistoryStore {
    private(set) var records: [WorkoutRecord] {
        didSet { persist() }
    }
    private let defaults: UserDefaults?
    private let storageKey = "workout.records.v1"

    init(records: [WorkoutRecord] = [], defaults: UserDefaults? = nil) {
        self.defaults = defaults
        let saved = defaults?.data(forKey: storageKey)
            .flatMap { try? JSONDecoder().decode([WorkoutRecord].self, from: $0) }
        self.records = (saved ?? records).sorted { $0.date > $1.date }
    }

    private func persist() {
        guard let defaults, let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func add(_ record: WorkoutRecord) {
        guard !records.contains(where: { $0.id == record.id }) else { return }
        records.append(record)
        records.sort { $0.date > $1.date }
    }

    func recordsInCurrentWeek(now: Date = .now, calendar: Calendar = .current) -> [WorkoutRecord] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return records.filter { $0.date >= week.start && $0.date < week.end }
    }

    func records(inMonthOf date: Date) -> [WorkoutRecord] {
        guard let month = Calendar.current.dateInterval(of: .month, for: date) else { return [] }
        return records.filter { $0.date >= month.start && $0.date < month.end }
    }

    func records(on date: Date) -> [WorkoutRecord] {
        records.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func record(with id: UUID) -> WorkoutRecord? {
        records.first { $0.id == id }
    }
}
