import XCTest
@testable import GYMUP

final class WorkoutSessionViewModelTests: XCTestCase {
    @MainActor
    func testCompletionDataIncludesActualDurationCompletedSetsAndVolume() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WorkoutSessionViewModel(routineID: "upper-a", startedAt: start)

        viewModel.updateWeight(50, exerciseIndex: 0, setIndex: 0)
        viewModel.updateRepetitions(8, exerciseIndex: 0, setIndex: 0)
        viewModel.toggleSetCompletion(exerciseIndex: 0, setIndex: 0, at: start.addingTimeInterval(20))
        viewModel.updateWeight(20, exerciseIndex: 1, setIndex: 0)
        viewModel.updateRepetitions(10, exerciseIndex: 1, setIndex: 0)
        viewModel.toggleSetCompletion(exerciseIndex: 1, setIndex: 0, at: start.addingTimeInterval(30))
        viewModel.finish(at: start.addingTimeInterval(130))

        let data = try XCTUnwrap(viewModel.completionData)
        XCTAssertEqual(data.routineName, "UPPER A")
        XCTAssertEqual(data.metrics.first(where: { $0.title == "TIME" })?.value, "3")
        XCTAssertEqual(data.metrics.first(where: { $0.title == "SETS" })?.value, "2")
        XCTAssertEqual(data.metrics.first(where: { $0.title == "VOLUME" })?.value, "600")
        let completedExercise = try XCTUnwrap(data.exerciseDetails.first)
        XCTAssertEqual(completedExercise.name, "벤치 프레스")
        XCTAssertEqual(completedExercise.sets.first?.weightKilograms, 50)
        XCTAssertEqual(completedExercise.sets.first?.repetitions, 8)
        XCTAssertEqual(data.exerciseDetails.count, 2)
        XCTAssertEqual(data.exerciseDetails.last?.name, "인클라인 덤벨 프레스")
        XCTAssertNotNil(data.levelReward)
        XCTAssertNotNil(data.stageReward)
        XCTAssertNotNil(data.peakReward)
    }

    func testAllSampleExercisesHavePreSessionFormAndBeginnerGuidance() {
        let plan = WorkoutSessionPlan.sample(for: "upper-a")

        XCTAssertTrue(plan.exercises.allSatisfy { !$0.formSteps.isEmpty })
        XCTAssertTrue(plan.exercises.allSatisfy { !$0.beginnerTip.isEmpty })
    }

    @MainActor
    func testSetValuesCanBeEditedAndNewSetCopiesThePreviousTarget() throws {
        let viewModel = WorkoutSessionViewModel(routineID: "upper-a")
        viewModel.updateWeight(52.5, exerciseIndex: 0, setIndex: 3)
        viewModel.updateRepetitions(8, exerciseIndex: 0, setIndex: 3)
        viewModel.addSet(to: 0)

        let exercise = try XCTUnwrap(viewModel.plan.exercises.first)
        XCTAssertEqual(exercise.sets.count, 5)
        XCTAssertEqual(exercise.sets.last?.weightKilograms, 52.5)
        XCTAssertEqual(exercise.sets.last?.repetitions, 8)
        XCTAssertFalse(try XCTUnwrap(exercise.sets.last).isCompleted)
    }

    @MainActor
    func testRestCountdownAndExerciseProgressRequireCompletedSets() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WorkoutSessionViewModel(routineID: "upper-a", startedAt: start)

        XCTAssertFalse(viewModel.moveToNextExercise())
        XCTAssertNotNil(viewModel.notice)

        viewModel.toggleSetCompletion(exerciseIndex: 0, setIndex: 0, at: start)
        XCTAssertTrue(viewModel.isResting)
        XCTAssertEqual(viewModel.restSecondsRemaining, 90)
        viewModel.refreshClock(at: start.addingTimeInterval(91))
        XCTAssertFalse(viewModel.isResting)

        for setIndex in 1..<4 {
            viewModel.toggleSetCompletion(exerciseIndex: 0, setIndex: setIndex, at: start)
        }
        XCTAssertFalse(viewModel.isResting)
        XCTAssertTrue(viewModel.moveToNextExercise())
        XCTAssertEqual(viewModel.currentExercise?.name, "인클라인 덤벨 프레스")
    }

    @MainActor
    func testElapsedTimeDoesNotIncludePausedDuration() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WorkoutSessionViewModel(routineID: "upper-a", startedAt: start)

        viewModel.togglePause(at: start.addingTimeInterval(60))
        XCTAssertEqual(viewModel.elapsedSeconds(at: start.addingTimeInterval(120)), 60)
        let completedCount = viewModel.currentExercise?.completedSetCount
        viewModel.toggleSetCompletion(exerciseIndex: 0, setIndex: 0, at: start.addingTimeInterval(90))
        XCTAssertEqual(viewModel.currentExercise?.completedSetCount, completedCount)
        viewModel.togglePause(at: start.addingTimeInterval(120))
        XCTAssertEqual(viewModel.elapsedSeconds(at: start.addingTimeInterval(150)), 90)
    }

    @MainActor
    func testFinishIsIdempotent() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WorkoutSessionViewModel(routineID: "upper-a", startedAt: start)

        viewModel.finish(at: start.addingTimeInterval(60))
        let firstCompletion = try XCTUnwrap(viewModel.completionData)
        viewModel.finish(at: start.addingTimeInterval(120))

        XCTAssertEqual(viewModel.completionData?.completedAt, firstCompletion.completedAt)
        XCTAssertEqual(viewModel.completionData?.metrics.first(where: { $0.title == "TIME" })?.value, "1")
    }

    @MainActor
    func testPreparationDoesNotStartWorkoutTimerBeforeUserStarts() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WorkoutSessionViewModel(routineID: "upper-a", startedAt: start, startsImmediately: false)

        XCTAssertFalse(viewModel.hasStarted)
        XCTAssertEqual(viewModel.elapsedSeconds(at: start.addingTimeInterval(120)), 0)

        viewModel.start(at: start.addingTimeInterval(120))

        XCTAssertTrue(viewModel.hasStarted)
        XCTAssertEqual(viewModel.elapsedSeconds(at: start.addingTimeInterval(150)), 30)
    }
}
