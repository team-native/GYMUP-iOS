import Foundation
import Observation

protocol OnboardingSubmissionServicing {
    func save(_ request: SaveOnboardingRequest) async throws -> SaveOnboardingResponse
}

extension OnboardingAPIService: OnboardingSubmissionServicing {}

enum OnboardingSubmissionRequestMapper {
    private static let experienceLevels = ["FIRST_TIMER", "BEGINNER", "INTERMEDIATE", "ADVANCED"]
    private static let goalTypes = ["PHYSIQUE", "STRENGTH", "HABIT"]

    static func request(for draft: OnboardingDraft) -> SaveOnboardingRequest? {
        guard let experience = draft.experience,
              experienceLevels.indices.contains(experience),
              goalTypes.indices.contains(draft.goal),
              (1...7).contains(draft.frequency)
        else {
            return nil
        }

        return SaveOnboardingRequest(
            experienceLevel: .string(experienceLevels[experience]),
            goalType: .string(goalTypes[draft.goal]),
            weeklyWorkoutTarget: draft.frequency
        )
    }
}

@Observable
@MainActor
final class OnboardingSubmissionViewModel {
    static let unavailableServiceMessage = "이 빌드에서는 서버 저장이 설정되지 않아 저장되지 않았어요. " +
        "로컬에서만 계속할 수 있어요."

    private let service: OnboardingSubmissionServicing?
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?
    private(set) var canRetry = false

    init(service: OnboardingSubmissionServicing?) {
        self.service = service
    }

    func submit(draft: OnboardingDraft) async -> Bool {
        guard !isSubmitting else { return false }
        canRetry = false
        guard let request = OnboardingSubmissionRequestMapper.request(for: draft) else {
            errorMessage = "온보딩 정보를 확인한 뒤 다시 시도해 주세요."
            return false
        }
        guard let service else {
            errorMessage = Self.unavailableServiceMessage
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            _ = try await service.save(request)
            errorMessage = nil
            return true
        } catch {
            errorMessage = Self.message(for: error)
            canRetry = true
            return false
        }
    }

    private static func message(for error: Error) -> String {
        if case let APIClientError.server(_, detail) = error {
            return detail.message
        }
        return "서버 저장에 실패했어요. 다시 시도하거나 로컬에서 계속할 수 있어요."
    }
}
