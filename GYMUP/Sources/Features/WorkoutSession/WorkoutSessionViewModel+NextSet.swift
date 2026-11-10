import Foundation

extension WorkoutSessionViewModel {
    func loadNextSetPreview() async {
        guard !isLoadingNextSetPreview,
              isServerManagedRest,
              let workoutID = serverWorkoutID,
              let nextSetService,
              let exercise = currentExercise,
              exercise.measure == .repetitions,
              let localSetIndex = currentSetIndex else { return }

        let expectedSetIndex = localSetIndex + 1
        isLoadingNextSetPreview = true
        nextSetPreview = nil
        nextSetPreviewError = nil
        defer { isLoadingNextSetPreview = false }

        do {
            let response = try await nextSetService.nextSet(workoutId: workoutID)
            guard isCurrentNextSetRequest(
                workoutID: workoutID,
                exerciseID: exercise.id,
                setIndex: localSetIndex
            ) else { return }
            guard response.exerciseId == exercise.id,
                  response.setIndex == expectedSetIndex,
                  !response.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  response.weight.isFinite,
                  response.weight >= 0,
                  response.reps >= 0 else {
                throw APIClientError.invalidResponse
            }

            nextSetPreview = response
        } catch {
            guard !Task.isCancelled,
                  isCurrentNextSetRequest(
                    workoutID: workoutID,
                    exerciseID: exercise.id,
                    setIndex: localSetIndex
                  ) else { return }
            nextSetPreviewError = Self.nextSetPreviewMessage(for: error)
        }
    }

    private func isCurrentNextSetRequest(workoutID: String, exerciseID: String, setIndex: Int) -> Bool {
        serverWorkoutID == workoutID &&
            isServerManagedRest &&
            currentExercise?.id == exerciseID &&
            currentSetIndex == setIndex
    }

    private static func nextSetPreviewMessage(for error: Error) -> String {
        if let apiError = error as? APIClientError,
           case let .server(_, detail) = apiError {
            return detail.message
        }
        return "다음 세트 정보를 불러오지 못했어요."
    }
}
