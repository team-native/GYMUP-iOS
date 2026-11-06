import Foundation

extension WorkoutSessionViewModel {
    var currentExercise: WorkoutSessionExercise? {
        guard plan.exercises.indices.contains(currentExerciseIndex) else { return nil }
        return plan.exercises[currentExerciseIndex]
    }

    var currentSetIndex: Int? {
        currentExercise?.sets.firstIndex(where: { !$0.isCompleted })
    }

    func adjustCurrentWeight(by increment: Double) {
        guard let currentSetIndex, let currentExercise else { return }
        let weight = currentExercise.sets[currentSetIndex].weightKilograms + increment
        updateWeight(weight, exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex)
    }

    func adjustCurrentRepetitions(by increment: Int) {
        guard let currentSetIndex, let currentExercise else { return }
        let repetitions = currentExercise.sets[currentSetIndex].repetitions + increment
        updateRepetitions(repetitions, exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex)
    }

    @discardableResult
    func completeSet(exerciseIndex: Int, setIndex: Int, at date: Date = Date()) async -> Bool {
        guard canCompleteSet(exerciseIndex: exerciseIndex, setIndex: setIndex) else { return false }
        guard let serverWorkoutID else {
            toggleSetCompletion(exerciseIndex: exerciseIndex, setIndex: setIndex, at: date)
            return true
        }
        guard currentExerciseIndex == exerciseIndex,
              currentSetIndex == setIndex,
              !isSubmittingWorkoutAction else { return false }

        let exercise = plan.exercises[exerciseIndex]
        if exercise.measure == .seconds {
            markSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex, at: date)
            return true
        }
        return await submitServerSet(
            exerciseIndex: exerciseIndex,
            setIndex: setIndex,
            exercise: exercise,
            workoutID: serverWorkoutID,
            completedAt: date
        )
    }

    @discardableResult
    func advanceToNextExercise() async -> Bool {
        guard let serverWorkoutID else { return moveToNextExerciseLocally() }
        guard hasStarted, !isPaused, !isFinished,
              let currentExercise,
              plan.exercises.indices.contains(currentExerciseIndex + 1) else { return false }
        guard currentExercise.isComplete else {
            notice = "현재 운동의 세트를 모두 완료한 뒤 다음으로 이동할 수 있어요."
            return false
        }
        guard !isSubmittingWorkoutAction else { return false }
        guard let progressService else {
            failServerAction(.advanceExercise, error: APIClientError.invalidBaseURL)
            return false
        }

        let request = pendingExerciseAdvance ?? AdvanceWorkoutExerciseRequest(
            completedExerciseId: currentExercise.id
        )
        guard request.completedExerciseId == currentExercise.id else { return false }
        pendingExerciseAdvance = request
        isSubmittingWorkoutAction = true
        clearServerActionError()
        defer { isSubmittingWorkoutAction = false }

        do {
            let response = try await progressService.advanceExercise(workoutId: serverWorkoutID, request: request)
            guard response.workoutId == serverWorkoutID else {
                throw APIClientError.invalidResponse
            }
            guard moveToNextExerciseLocally() else { throw APIClientError.invalidResponse }
            pendingExerciseAdvance = nil
            return true
        } catch {
            failServerAction(.advanceExercise, error: error)
            return false
        }
    }

    @discardableResult
    func retryFailedServerAction() async -> Bool {
        guard let failedServerAction else { return false }
        switch failedServerAction {
        case let .recordSet(exerciseIndex, setIndex):
            return await completeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
        case .advanceExercise:
            return await advanceToNextExercise()
        }
    }

    func dismissServerActionError() {
        clearServerActionError()
    }

    private func canCompleteSet(exerciseIndex: Int, setIndex: Int) -> Bool {
        guard hasStarted, !isPaused, !isFinished,
              plan.exercises.indices.contains(exerciseIndex),
              plan.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return false }
        return !plan.exercises[exerciseIndex].sets[setIndex].isCompleted
    }

    private func submitServerSet(
        exerciseIndex: Int,
        setIndex: Int,
        exercise: WorkoutSessionExercise,
        workoutID: String,
        completedAt date: Date
    ) async -> Bool {
        guard let progressService else {
            failServerAction(
                .recordSet(exerciseIndex: exerciseIndex, setIndex: setIndex),
                error: APIClientError.invalidBaseURL
            )
            return false
        }
        guard let pendingSetSubmission = makePendingSetSubmission(
            exerciseIndex: exerciseIndex,
            setIndex: setIndex,
            exercise: exercise,
            date: date
        ) else { return false }

        isSubmittingWorkoutAction = true
        clearServerActionError()
        defer { isSubmittingWorkoutAction = false }
        do {
            let response = try await progressService.createSet(
                workoutId: workoutID,
                request: pendingSetSubmission.request,
                idempotencyKey: pendingSetSubmission.idempotencyKey
            )
            try validateCreatedSet(response, workoutID: workoutID, exercise: exercise, setIndex: setIndex)
            markSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex, at: date)
            self.pendingSetSubmission = nil
            return true
        } catch {
            failServerAction(.recordSet(exerciseIndex: exerciseIndex, setIndex: setIndex), error: error)
            return false
        }
    }

    private func makePendingSetSubmission(
        exerciseIndex: Int,
        setIndex: Int,
        exercise: WorkoutSessionExercise,
        date: Date
    ) -> PendingWorkoutSetSubmission? {
        if let pendingSetSubmission {
            guard pendingSetSubmission.exerciseIndex == exerciseIndex,
                  pendingSetSubmission.setIndex == setIndex else { return nil }
            return pendingSetSubmission
        }
        let set = exercise.sets[setIndex]
        let submission = PendingWorkoutSetSubmission(
            exerciseIndex: exerciseIndex,
            setIndex: setIndex,
            request: CreateWorkoutSetRequest(
                exerciseId: exercise.id,
                setIndex: setIndex + 1,
                weight: set.weightKilograms,
                reps: set.repetitions,
                completedAt: Self.iso8601String(from: date)
            ),
            idempotencyKey: UUID().uuidString
        )
        pendingSetSubmission = submission
        return submission
    }

    private func validateCreatedSet(
        _ response: CreateWorkoutSetResponse,
        workoutID: String,
        exercise: WorkoutSessionExercise,
        setIndex: Int
    ) throws {
        guard response.workoutId == workoutID,
              response.exerciseId == exercise.id,
              response.setIndex == setIndex + 1 else {
            throw APIClientError.invalidResponse
        }
    }

    func isPendingServerSet(exerciseIndex: Int, setIndex: Int) -> Bool {
        pendingSetSubmission?.exerciseIndex == exerciseIndex && pendingSetSubmission?.setIndex == setIndex
    }

    func failServerAction(_ action: FailedWorkoutServerAction, error: Error) {
        failedServerAction = action
        if let apiError = error as? APIClientError,
           case let .server(_, detail) = apiError {
            serverActionErrorMessage = detail.message
        } else {
            serverActionErrorMessage = error.localizedDescription
        }
    }

    func clearServerActionError() {
        serverActionErrorMessage = nil
        failedServerAction = nil
    }

    private static func iso8601String(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func moveToNextExerciseLocally() -> Bool {
        guard hasStarted, !isPaused, !isFinished, let currentExercise else { return false }
        guard currentExercise.isComplete else {
            notice = "현재 운동의 세트를 모두 완료한 뒤 다음으로 이동할 수 있어요."
            return false
        }
        guard plan.exercises.indices.contains(currentExerciseIndex + 1) else { return false }
        currentExerciseIndex += 1
        restEndsAt = nil
        activeRestDurationSeconds = 0
        notice = nil
        return true
    }

    @discardableResult
    func moveToNextExercise() -> Bool {
        guard serverWorkoutID == nil else { return false }
        return moveToNextExerciseLocally()
    }
}

enum FailedWorkoutServerAction: Equatable {
    case recordSet(exerciseIndex: Int, setIndex: Int)
    case advanceExercise
}

struct PendingWorkoutSetSubmission {
    let exerciseIndex: Int
    let setIndex: Int
    let request: CreateWorkoutSetRequest
    let idempotencyKey: String
}
