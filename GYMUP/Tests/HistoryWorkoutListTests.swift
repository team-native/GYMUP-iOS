import XCTest
@testable import GYMUP

final class HistoryWorkoutListTests: XCTestCase {
    @MainActor
    func testFirstRunHistoryStoreStartsEmpty() {
        XCTAssertTrue(HistoryStore().records.isEmpty)
    }

    @MainActor
    func testCompletedWorkoutAddsRecordAndClearsEmptyStateCondition() {
        let store = HistoryStore()
        let completedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let exercise = WorkoutSessionExercise(
            id: "bench-press",
            name: "벤치 프레스",
            target: "가슴",
            restDurationSeconds: 90,
            formSteps: [],
            beginnerTip: "",
            sets: [
                WorkoutSessionSet(weightKilograms: 50, repetitions: 10, isCompleted: true),
                WorkoutSessionSet(weightKilograms: 62.5, repetitions: 8, isCompleted: true)
            ]
        )
        let plan = WorkoutSessionPlan(
            id: "upper-a",
            name: "UPPER A",
            title: "상체 A",
            estimatedDurationMinutes: 55,
            exercises: [exercise]
        )

        XCTAssertTrue(store.records.isEmpty)

        let record = WorkoutSessionCompletionDataFactory.makeHistoryRecord(
            plan: plan,
            elapsedSeconds: 65,
            completedAt: completedAt
        )
        store.add(record)

        XCTAssertFalse(store.records.isEmpty)
        XCTAssertEqual(store.records, [record])
        XCTAssertEqual(store.records(inMonthOf: completedAt), [record])
        XCTAssertEqual(record.routineName, "상체 A")
        XCTAssertEqual(record.durationMinutes, 2)
        XCTAssertEqual(record.setCount, 2)
        XCTAssertEqual(record.volumeKilograms, 1_000)
        XCTAssertEqual(record.growth, 1)
        XCTAssertEqual(record.exercises.first?.sets.filter(\.isPersonalRecord).count, 1)

        store.add(record)
        XCTAssertEqual(store.records.count, 1)
    }

    func testG1SampleDataMatchesMonthlySummaryAndVisibleDateOrder() {
        let monthRecords = HistoryListSampleData.records(inMonthOf: HistoryListSampleData.sampleMonth)
        let calendar = Calendar.current

        XCTAssertEqual(monthRecords.count, 9)
        XCTAssertEqual(monthRecords.map { calendar.component(.day, from: $0.date) }, [11, 8, 6, 3, 3, 2, 2, 1, 1])
        XCTAssertEqual(monthRecords.reduce(0) { $0 + $1.durationMinutes }, 492)
        XCTAssertEqual(monthRecords.reduce(0) { $0 + $1.volumeKilograms }, 72_400)
    }

    func testSelectingDateKeepsMonthListAndFindsTheWorkoutForDetailNavigation() throws {
        let selectedDate = HistoryListSampleData.date(day: 8, inMonthOf: HistoryListSampleData.sampleMonth)
        let monthRecords = HistoryListSampleData.records(inMonthOf: selectedDate)
        let selectedWorkout = try XCTUnwrap(HistoryListSampleData.records(on: selectedDate).first)

        XCTAssertEqual(monthRecords.count, 9)
        XCTAssertEqual(HistoryListSampleData.record(with: selectedWorkout.id), selectedWorkout)
    }

    func testEmptyMonthHasNoG1Rows() throws {
        let previousMonth = try XCTUnwrap(
            Calendar.current.date(byAdding: .month, value: -1, to: HistoryListSampleData.sampleMonth)
        )
        let sameMonthNextYear = try XCTUnwrap(
            Calendar.current.date(byAdding: .year, value: 1, to: HistoryListSampleData.sampleMonth)
        )

        XCTAssertTrue(HistoryListSampleData.records(inMonthOf: previousMonth).isEmpty)
        XCTAssertTrue(HistoryListSampleData.records(inMonthOf: sameMonthNextYear).isEmpty)
    }
}
