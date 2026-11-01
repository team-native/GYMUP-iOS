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
    private let service: OnboardingSubmissionServicing?
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    init(service: OnboardingSubmissionServicing?) {
        self.service = service
    }

    func submit(draft: OnboardingDraft) async -> Bool {
        guard !isSubmitting else { return false }
        guard let request = OnboardingSubmissionRequestMapper.request(for: draft) else {
            errorMessage = "온보딩 정보를 확인한 뒤 다시 시도해 주세요."
            return false
        }
        guard let service else {
            errorMessage = nil
            return true
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            _ = try await service.save(request)
            return true
        } catch {
            errorMessage = Self.message(for: error)
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
