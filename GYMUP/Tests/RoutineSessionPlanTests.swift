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

    func testTimeBasedRoutinePreservesDuration() throws {
        var exercise = RoutineExercise(id: "plank", name: "플랭크", imageAssetName: "", setCount: 3,
                                       repetitions: 30, weight: 0, restSeconds: 60)
        exercise.measure = .seconds
        let routine = RoutinePlan(id: "timed", name: "TIME", title: "시간 운동", exerciseCount: 1,
                                  durationMinutes: 5, lastPerformed: "", coverAssetName: "",
                                  isRecommended: false, exercises: [exercise])
        let plan = try XCTUnwrap(WorkoutSessionPlan.make(from: routine))
        let timed = try XCTUnwrap(plan.exercises.first)
        XCTAssertEqual(timed.measure, .seconds)
        XCTAssertEqual(timed.sets.first?.repetitions, 30)
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

@MainActor
extension RoutineSessionPlanTests {
    func testTimedExerciseRestAndCompletionPreserveSecondsInHistory() throws {
        let exercise = RoutineExercise(id: "plank", name: "플랭크", imageAssetName: "", setCount: 2,
                                       repetitions: 45, weight: 0, restSeconds: 60, measure: .seconds)
        let routine = RoutinePlan(id: "timed", name: "TIME", title: "시간 운동", exerciseCount: 1,
                                  durationMinutes: 5, lastPerformed: "", coverAssetName: "",
                                  isRecommended: false, exercises: [exercise])
        let plan = try XCTUnwrap(WorkoutSessionPlan.make(from: routine))
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let session = WorkoutSessionViewModel(plan: plan, startedAt: start)
        session.toggleSetCompletion(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(session.isResting)
        session.skipRest()
        session.toggleSetCompletion(exerciseIndex: 0, setIndex: 1, at: start.addingTimeInterval(45))
        session.finish(at: start.addingTimeInterval(90))
        let history = WorkoutSessionCompletionDataFactory.makeHistoryRecord(
            plan: session.plan, elapsedSeconds: session.elapsedSeconds, completedAt: start
        )
        XCTAssertEqual(history.setCount, 2)
        XCTAssertEqual(history.volumeKilograms, 0)
        XCTAssertEqual(history.exercises.first?.sets.map(\.valueTitle), ["45초", "45초"])
        XCTAssertNotNil(session.completionData)
    }
}
