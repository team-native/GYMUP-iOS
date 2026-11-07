import Foundation
import Observation

struct HistoryServerWorkout: Identifiable, Hashable {
    let id: String
    let date: Date
    let routineName: String
    let durationMinutes: Int
    let setCount: Int
    let volumeKilograms: Int

    init?(response: WorkoutListItem) {
        guard let date = Self.date(from: response.date),
              response.duration >= 0,
              response.totalSets >= 0,
              response.volume.isFinite,
              response.volume >= 0,
              response.volume < Double(Int.max)
        else {
            return nil
        }

        id = response.workoutId
        self.date = date
        routineName = response.routineName
        durationMinutes = Int(ceil(Double(response.duration) / 60))
        setCount = response.totalSets
        volumeKilograms = Int(response.volume.rounded())
    }

    private static func date(from value: String) -> Date? {
        let options: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime]
        ]
        for formatOptions in options {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = formatOptions
            if let date = formatter.date(from: value) {
                return date
            }
        }

        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        guard let date = calendar.date(from: components),
              calendar.component(.year, from: date) == year,
              calendar.component(.month, from: date) == month,
              calendar.component(.day, from: date) == day
        else {
            return nil
        }
        return date
    }
}

struct HistoryListEntry: Identifiable {
    let id: String
    let date: Date
    let routineName: String
    let durationMinutes: Int
    let setCount: Int
    let volumeKilograms: Int
    let personalRecordCount: Int?
    let localRecordID: UUID?
    let serverWorkout: HistoryServerWorkout?
    let detailRoute: HistoryRoute

    init(localRecord: WorkoutRecord) {
        id = "local-\(localRecord.id.uuidString)"
        date = localRecord.date
        routineName = localRecord.routineName
        durationMinutes = localRecord.durationMinutes
        setCount = localRecord.setCount
        volumeKilograms = localRecord.volumeKilograms
        personalRecordCount = localRecord.growth
        localRecordID = localRecord.id
        serverWorkout = nil
        detailRoute = .detail(localRecord.id)
    }

    init(serverRecord: HistoryServerWorkout) {
        id = "server-\(serverRecord.id)"
        date = serverRecord.date
        routineName = serverRecord.routineName
        durationMinutes = serverRecord.durationMinutes
        setCount = serverRecord.setCount
        volumeKilograms = serverRecord.volumeKilograms
        personalRecordCount = nil
        localRecordID = nil
        serverWorkout = serverRecord
        detailRoute = .serverDetail(serverRecord)
    }

    var detailAccessibilityIdentifier: String {
        if let localRecordID {
            return "history.record.\(localRecordID.uuidString)"
        }
        if let serverWorkout {
            return "history.serverRecord.\(serverWorkout.id)"
        }
        return "history.record.\(id)"
    }

    var accessibilityDescription: String {
        let dateText = HistoryDateText.string(date, format: "M월 d일 EEEE")
        let base = "\(dateText), \(routineName), \(durationMinutes)분, \(setCount)세트"
        guard let personalRecordCount else { return "\(base), 서버 요약 기록" }
        return "\(base), 개인 기록 \(personalRecordCount)개"
    }
}

@Observable
@MainActor
final class HistoryListViewModel {
    private let service: WorkoutListReading?
    private let routineStore: RoutineStore?
    private let nowProvider: () -> Date

    private(set) var serverRecords: [HistoryServerWorkout] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(
        service: WorkoutListReading?,
        routineStore: RoutineStore?,
        nowProvider: @escaping () -> Date = { .now }
    ) {
        self.service = service
        self.routineStore = routineStore
        self.nowProvider = nowProvider
    }

    func entries(localRecords: [WorkoutRecord]) -> [HistoryListEntry] {
        let entries = localRecords.map(HistoryListEntry.init(localRecord:))
            + serverRecords.map(HistoryListEntry.init(serverRecord:))
        return entries.sorted { $0.date > $1.date }
    }

    func refresh() async {
        let routineIDs = currentServerRoutineIDs
        guard let service,
              !routineIDs.isEmpty,
              !isLoading
        else {
            return
        }
        await load(routineIDs: routineIDs, using: service)
    }

    func retry() async {
        await refresh()
    }

    private var currentServerRoutineIDs: Set<String> {
        Set(routineStore?.routines.compactMap(\.serverRoutineId).filter { !$0.isEmpty } ?? [])
    }

    private func load(routineIDs: Set<String>, using service: WorkoutListReading) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            serverRecords = try await fetchRecords(for: routineIDs, using: service)
            errorMessage = nil
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    private func fetchRecords(
        for routineIDs: Set<String>,
        using service: WorkoutListReading
    ) async throws -> [HistoryServerWorkout] {
        var recordsByID: [String: HistoryServerWorkout] = [:]
        let dateRange = Self.dateRange(now: nowProvider())

        for routineID in routineIDs.sorted() {
            var cursor: String?
            var seenCursors = Set<String>()

            while true {
                let query = ListWorkoutsQuery(
                    cursor: cursor,
                    size: 100,
                    from: dateRange.from,
                    endDate: dateRange.to,
                    routineId: routineID
                )
                let response = try await service.list(query)

                for item in response.items {
                    guard let record = HistoryServerWorkout(response: item) else {
                        throw APIClientError.invalidResponse
                    }
                    recordsByID[record.id] = record
                }

                guard let nextCursor = response.nextCursor, !nextCursor.isEmpty else { break }
                guard seenCursors.insert(nextCursor).inserted else {
                    throw APIClientError.invalidResponse
                }
                cursor = nextCursor
            }
        }

        return recordsByID.values.sorted { $0.date > $1.date }
    }

    private static func dateRange(now: Date = .now) -> (from: String, to: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return ("1970-01-01", formatter.string(from: now))
    }

    private static func message(for error: Error) -> String {
        if let apiError = error as? APIClientError,
           case let .server(_, detail) = apiError {
            return detail.message
        }
        return "운동 기록을 불러오지 못했어요. 다시 시도해 주세요."
    }
}
