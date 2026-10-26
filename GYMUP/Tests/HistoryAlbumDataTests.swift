import XCTest
@testable import GYMUP

final class HistoryAlbumDataTests: XCTestCase {
    func testGroupsRecordsByMonthAndSortsNewestFirst() {
        let octoberEleventh = record(year: 2025, month: 10, day: 11, exercises: ["벤치프레스"])
        let octoberEighth = record(year: 2025, month: 10, day: 8, exercises: ["스쿼트"])
        let novemberSecond = record(year: 2025, month: 11, day: 2, exercises: ["랫 풀 다운"])

        let album = HistoryAlbumData(
            records: [octoberEighth, novemberSecond, octoberEleventh],
            calendar: testCalendar
        )

        XCTAssertEqual(album.months.map(\.title), ["11월", "10월"])
        XCTAssertEqual(album.months[1].records.map(\.date), [octoberEleventh.date, octoberEighth.date])
    }

    func testExerciseSelectionFiltersRecordsAndKeepsAvailableOptions() {
        let upperBody = record(year: 2025, month: 10, day: 11, routineName: "상체 A", exercises: ["벤치프레스"])
        let lowerBody = record(year: 2025, month: 10, day: 8, routineName: "하체 B", exercises: ["스쿼트"])

        let album = HistoryAlbumData(
            records: [upperBody, lowerBody],
            selectedExercise: "벤치프레스",
            calendar: testCalendar
        )

        XCTAssertEqual(album.months.flatMap(\.records).map(\.routineName), ["상체 A"])
        XCTAssertEqual(Set(album.exerciseOptions), Set(["벤치프레스", "스쿼트"]))
    }

    func testMonthLabelsIncludeYearWhenRecordsSpanYears() {
        let december = record(year: 2024, month: 12, day: 20, exercises: ["벤치프레스"])
        let january = record(year: 2025, month: 1, day: 5, exercises: ["스쿼트"])

        let album = HistoryAlbumData(records: [december, january], calendar: testCalendar)

        XCTAssertEqual(album.months.map(\.title), ["2025년 1월", "2024년 12월"])
    }

    func testEmptyRecordsHaveNoMonthsOrExerciseOptions() {
        let album = HistoryAlbumData(records: [], calendar: testCalendar)

        XCTAssertFalse(album.hasRecords)
        XCTAssertTrue(album.months.isEmpty)
        XCTAssertTrue(album.exerciseOptions.isEmpty)
    }

    private var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func record(
        year: Int,
        month: Int,
        day: Int,
        routineName: String = "상체 루틴",
        exercises: [String]
    ) -> WorkoutRecord {
        WorkoutRecord(
            id: UUID(),
            date: date(year: year, month: month, day: day),
            routineName: routineName,
            category: "근력 운동",
            durationMinutes: 45,
            setCount: 3,
            volumeKilograms: 1_500,
            growth: 0,
            photoAssetName: "H1RoutinePhoto",
            exercises: exercises.enumerated().map { index, name in
                WorkoutExerciseRecord(id: index + 1, name: name, sets: [])
            }
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        testCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .now
    }
}
