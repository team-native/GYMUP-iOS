import Foundation
import Observation

@Observable
@MainActor
final class WorkoutExerciseGuidanceViewModel {
    private let service: ExerciseGuidanceReading?

    private(set) var firstTimeStatuses: [String: ExerciseFirstTimeStatusResponse] = [:]
    private(set) var firstTimeStatusErrors: [String: String] = [:]
    private(set) var loadingFirstTimeStatusExerciseIDs: Set<String> = []
    private(set) var exerciseGuides: [String: ExerciseGuideResponse] = [:]
    private(set) var exerciseGuideErrors: [String: String] = [:]
    private(set) var loadingExerciseGuideIDs: Set<String> = []

    init(service: ExerciseGuidanceReading?) {
        self.service = service
    }

    func shouldShowFirstExercisePrompt(for exercise: WorkoutSessionExercise) -> Bool {
        guard let status = firstTimeStatuses[exercise.id], status.exerciseId == exercise.id else {
            return !exercise.hasPreviousPerformance
        }
        return status.isFirstTime && status.guideAvailable
    }

    func loadFirstTimeStatus(for exerciseID: String, in plan: WorkoutSessionPlan) async {
        guard let service,
              plan.exercises.contains(where: { $0.id == exerciseID }),
              !loadingFirstTimeStatusExerciseIDs.contains(exerciseID) else { return }

        loadingFirstTimeStatusExerciseIDs.insert(exerciseID)
        defer { loadingFirstTimeStatusExerciseIDs.remove(exerciseID) }

        do {
            let response = try await service.firstTimeStatus(exerciseId: exerciseID)
            guard response.exerciseId == exerciseID else {
                throw APIClientError.invalidResponse
            }

            firstTimeStatuses[exerciseID] = response
            firstTimeStatusErrors.removeValue(forKey: exerciseID)
        } catch {
            guard !Task.isCancelled else { return }
            firstTimeStatusErrors[exerciseID] = Self.errorMessage(
                for: error,
                fallback: "첫 기록 상태를 불러오지 못했어요."
            )
        }
    }

    func exerciseGuide(for exerciseID: String) -> ExerciseGuideResponse? {
        exerciseGuides[exerciseID]
    }

    func exerciseGuideError(for exerciseID: String) -> String? {
        exerciseGuideErrors[exerciseID]
    }

    func isLoadingExerciseGuide(for exerciseID: String) -> Bool {
        loadingExerciseGuideIDs.contains(exerciseID)
    }

    func loadExerciseGuide(for exerciseID: String, in plan: WorkoutSessionPlan) async {
        guard let service,
              plan.exercises.contains(where: { $0.id == exerciseID }),
              !loadingExerciseGuideIDs.contains(exerciseID) else { return }

        loadingExerciseGuideIDs.insert(exerciseID)
        defer { loadingExerciseGuideIDs.remove(exerciseID) }

        do {
            let response = try await service.guide(exerciseId: exerciseID)
            guard response.exerciseId == exerciseID else {
                throw APIClientError.invalidResponse
            }

            exerciseGuides[exerciseID] = response
            exerciseGuideErrors.removeValue(forKey: exerciseID)
        } catch {
            guard !Task.isCancelled else { return }
            exerciseGuideErrors[exerciseID] = Self.errorMessage(
                for: error,
                fallback: "자세 가이드를 불러오지 못했어요."
            )
        }
    }

    private static func errorMessage(for error: Error, fallback: String) -> String {
        if let apiError = error as? APIClientError,
           case let .server(_, detail) = apiError {
            return detail.message
        }
        return fallback
    }
}
