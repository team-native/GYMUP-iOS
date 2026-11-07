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

struct HistoryServerPhoto: Identifiable, Equatable {
    let id: String
    let workoutID: String
    let capturedAt: Date
    let thumbnailURL: URL?

    init?(response: PhotoListItem) {
        guard !response.photoId.isEmpty,
              !response.workoutId.isEmpty,
              let capturedAt = Self.date(from: response.capturedAt)
        else {
            return nil
        }

        id = response.photoId
        workoutID = response.workoutId
        self.capturedAt = capturedAt
        thumbnailURL = Self.remoteURL(from: response.thumbnailUrl)
    }

    private static func remoteURL(from value: String?) -> URL? {
        guard let value,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "https"
        else {
            return nil
        }
        return url
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
        return nil
    }
}

struct HistoryServerPhotoSection: Identifiable {
    var id: Date { monthStart }
    let monthStart: Date
    let title: String
    let photos: [HistoryServerPhoto]
}

struct HistoryServerPhotoData {
    let months: [HistoryServerPhotoSection]

    init(photos: [HistoryServerPhoto], calendar: Calendar = .current) {
        let grouped = Dictionary(grouping: photos) { photo in
            calendar.dateInterval(of: .month, for: photo.capturedAt)?.start ?? photo.capturedAt
        }
        let includesYear = Set(photos.map { calendar.component(.year, from: $0.capturedAt) }).count > 1
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = includesYear ? "yyyy년 M월" : "M월"

        months = grouped.keys.sorted(by: >).compactMap { monthStart in
            guard let monthPhotos = grouped[monthStart]?.sorted(by: { $0.capturedAt > $1.capturedAt }) else {
                return nil
            }
            return HistoryServerPhotoSection(
                monthStart: monthStart,
                title: formatter.string(from: monthStart),
                photos: monthPhotos
            )
        }
    }
}
