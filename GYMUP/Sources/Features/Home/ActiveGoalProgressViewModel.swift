import Foundation
import Observation

@Observable
@MainActor
final class ActiveGoalProgressViewModel {
    private let service: ActiveGoalProgressReading?
    private let completionService: GoalCompleting?
    private(set) var response: ActiveGoalProgressResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isCompletingGoal = false
    private(set) var completionResponse: CompleteGoalResponse?
    private(set) var completionErrorMessage: String?

    init(service: ActiveGoalProgressReading?, completionService: GoalCompleting? = nil) {
        self.service = service
        self.completionService = completionService ?? (service as? GoalCompleting)
    }

    var isAvailable: Bool { service != nil }
    var canCompleteCurrentGoal: Bool {
        completionService != nil && response?.growth == 100 && !(response?.goalId?.isEmpty ?? true)
    }

    func refresh() async {
        guard !isLoading, let service else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            response = try await service.fetchActiveProgress()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func completeCurrentGoal() async -> CompleteGoalResponse? {
        guard !isCompletingGoal,
              let goalId = response?.goalId,
              !goalId.isEmpty,
              response?.growth == 100,
              let completionService else {
            completionErrorMessage = "Growth 100에 도달한 활성 목표가 없어요. 진행 정보를 다시 불러와 주세요."
            return nil
        }

        isCompletingGoal = true
        completionErrorMessage = nil
        defer { isCompletingGoal = false }

        do {
            let result = try await completionService.completeGoal(
                goalId: goalId,
                request: CompleteGoalRequest(expectedVersion: 1)
            )
            guard result.goalId == goalId,
                  result.status == "COMPLETED" else {
                throw APIClientError.invalidResponse
            }
            completionResponse = result
            return result
        } catch {
            completionErrorMessage = Self.message(for: error)
            return nil
        }
    }

    func clearCompletionError() {
        completionErrorMessage = nil
    }

    private static func message(for error: Error) -> String {
        if case let APIClientError.server(_, detail) = error {
            return detail.message
        }
        return "목표를 완료하지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요."
    }
}
