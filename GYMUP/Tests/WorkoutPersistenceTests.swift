import XCTest
@testable import GYMUP

@MainActor
final class WorkoutPersistenceTests: XCTestCase {
    func testRoutineEditsAndDeletionSurviveStoreRecreation() throws {
        let suite = "persistence-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RoutineStore(defaults: defaults)
        var exercise = RoutineExercise.lower[4]
        exercise.restSeconds = 120
        let id = store.saveRoutine(id: nil, title: "시간 루틴", exercises: [exercise])
        let restored = RoutineStore(defaults: defaults)
        XCTAssertEqual(restored.routine(id: id)?.exercises, [exercise])
        XCTAssertTrue(restored.deleteRoutine(id: id))
        XCTAssertNil(RoutineStore(defaults: defaults).routine(id: id))
        restored.routines = []
        XCTAssertTrue(RoutineStore(defaults: defaults).routines.isEmpty)
    }

    func testWorkoutRecordRoundTripPreservesTimedSetsAndPreventsDuplicates() throws {
        let suite = "history-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let record = WorkoutRecord(
            id: UUID(), date: .now, routineName: "코어", category: "코어", durationMinutes: 5,
            setCount: 1, volumeKilograms: 0, growth: 0, photoAssetName: "H1RoutinePhoto",
            exercises: [WorkoutExerciseRecord(id: 1, name: "플랭크", sets: [
                WorkoutSetRecord(id: 1, weight: 0, repetitions: 45, measure: .seconds)
            ])], routineCompleted: true
        )
        let store = HistoryStore(defaults: defaults)
        store.add(record)
        let restored = HistoryStore(defaults: defaults)
        restored.add(record)
        XCTAssertEqual(restored.records, [record])
        XCTAssertEqual(HistoryStore(defaults: defaults).records, [record])
    }

    func testCorruptStoredDataUsesSafeInitialState() throws {
        let suite = "corrupt-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid".utf8), forKey: "workout.records.v1")
        defaults.set(Data("invalid".utf8), forKey: "routine.plans.v1")
        XCTAssertTrue(HistoryStore(defaults: defaults).records.isEmpty)
        XCTAssertEqual(RoutineStore(defaults: defaults).routines, RoutinePlan.samples)
    }
}
