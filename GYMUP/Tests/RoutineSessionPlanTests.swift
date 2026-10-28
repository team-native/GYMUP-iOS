import XCTest
@testable import GYMUP

final class RoutineSessionPlanTests: XCTestCase {
    func testCustomRoutineKeepsSelectedExercisesAndSetSettings() throws {
        let exercise = RoutineExercise(id: "bench", name: "벤치프레스", imageAssetName: "H1RoutinePhoto",
                                       setCount: 2, repetitions: 12, weight: 47.5, restSeconds: 75)
        let routine = RoutinePlan(id: "custom", name: "MY PLAN", title: "내 루틴", exerciseCount: 1,
                                  durationMinutes: 30, lastPerformed: "", coverAssetName: "",
                                  isRecommended: false, exercises: [exercise])
        let plan = try XCTUnwrap(WorkoutSessionPlan.make(from: routine))
        XCTAssertEqual(plan.id, "custom")
        XCTAssertEqual(plan.title, "내 루틴")
        let selected = try XCTUnwrap(plan.exercises.first)
        XCTAssertEqual(selected.id, "bench-press")
        XCTAssertEqual(selected.restDurationSeconds, 75)
        XCTAssertEqual(selected.imageAssetName, "H1RoutinePhoto")
        XCTAssertEqual(selected.sets.count, 2)
        XCTAssertTrue(selected.sets.allSatisfy { $0.weightKilograms == 47.5 && $0.repetitions == 12 })
        XCTAssertNil(selected.personalRecordKilograms)
        XCTAssertNil(selected.previousPerformance(for: 0))
    }

    func testTimeBasedRoutineIsNotMisrepresentedAsRepetitions() {
        var exercise = RoutineExercise(id: "plank", name: "플랭크", imageAssetName: "", setCount: 3,
                                       repetitions: 30, weight: 0, restSeconds: 60)
        exercise.measure = .seconds
        let routine = RoutinePlan(id: "timed", name: "TIME", title: "시간 운동", exerciseCount: 1,
                                  durationMinutes: 5, lastPerformed: "", coverAssetName: "",
                                  isRecommended: false, exercises: [exercise])
        XCTAssertNil(WorkoutSessionPlan.make(from: routine))
    }
}

extension RoutineSessionPlanTests {
    func testTimedSetsDoNotContributeToWeightVolume() throws {
        var plan = WorkoutSessionPlan.sample(for: "upper-a")
        plan.exercises[0].measure = .seconds
        plan.exercises[0].sets[0].isCompleted = true
        XCTAssertEqual(plan.exercises[0].completedVolumeKilograms, 0)
        let record = WorkoutSessionCompletionDataFactory.makeHistoryRecord(
            plan: plan, elapsedSeconds: 30, completedAt: Date()
        )
        XCTAssertEqual(record.volumeKilograms, 0)
        XCTAssertEqual(record.exercises.first?.sets.first?.valueTitle, "8초")
    }
}
