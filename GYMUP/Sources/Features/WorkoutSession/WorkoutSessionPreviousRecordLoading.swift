import Foundation

@MainActor
protocol WorkoutPreviousRecordLoading {
    func fetchPreviousRecord(for exerciseID: String) async throws -> PreviousExerciseRecordResponse
}

extension ExerciseReadAPIService: WorkoutPreviousRecordLoading {
    @MainActor
    func fetchPreviousRecord(for exerciseID: String) async throws -> PreviousExerciseRecordResponse {
        try await previousRecord(exerciseId: exerciseID)
    }
}
