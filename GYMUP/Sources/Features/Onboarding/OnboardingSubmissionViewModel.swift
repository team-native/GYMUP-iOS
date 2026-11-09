import Foundation
import Observation

protocol OnboardingSubmissionServicing {
    func save(_ request: SaveOnboardingRequest) async throws -> SaveOnboardingResponse
    func createGoal(_ request: CreateGoalRequest) async throws
}

extension OnboardingSubmissionServicing {
    func createGoal(_ request: CreateGoalRequest) async throws {
        throw APIClientError.unexpectedStatusCode(501)
    }
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

    static func goalRequest(for draft: OnboardingDraft, startedAt: Date, calendar: Calendar = .current) -> CreateGoalRequest? {
        guard goalTypes.indices.contains(draft.goal), (1...7).contains(draft.frequency),
              [4, 8, 12, 16].contains(draft.weeks)
        else {
            return nil
        }

        let normalizedStart = calendar.startOfDay(for: startedAt)
        guard let end = calendar.date(byAdding: .weekOfYear, value: draft.weeks, to: normalizedStart) else {
            return nil
        }

        return CreateGoalRequest(
            goalType: goalTypes[draft.goal],
            startDate: dateOnlyString(normalizedStart, calendar: calendar),
            endDate: dateOnlyString(end, calendar: calendar),
            weeklyWorkoutTarget: draft.frequency
        )
    }

    private static func dateOnlyString(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
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
    private(set) var submittedGoalStartedAt: Date?

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
        if submittedGoalStartedAt == nil {
            submittedGoalStartedAt = Calendar.current.startOfDay(for: .now)
        }
        guard let startedAt = submittedGoalStartedAt,
              let goalRequest = OnboardingSubmissionRequestMapper.goalRequest(for: draft, startedAt: startedAt)
        else {
            errorMessage = "목표 정보를 확인한 뒤 다시 시도해 주세요."
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
            do {
                _ = try await service.save(request)
            } catch {
                guard Self.isConflict(error, code: "ALREADY_COMPLETED") else { throw error }
            }

            do {
                try await service.createGoal(goalRequest)
            } catch {
                guard Self.isConflict(error, code: "ACTIVE_GOAL_EXISTS") else { throw error }
            }

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

    private static func isConflict(_ error: Error, code: String) -> Bool {
        guard case let APIClientError.server(statusCode, detail) = error else { return false }
        return statusCode == 409 && detail.code == code
    }
}
