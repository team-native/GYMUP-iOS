import XCTest
@testable import GYMUP

@MainActor
final class OnboardingSubmissionTests: XCTestCase {
    func testRequestMapperUsesStableWireValues() throws {
        let experienceValues = ["FIRST_TIMER", "BEGINNER", "INTERMEDIATE", "ADVANCED"]
        let goalValues = ["PHYSIQUE", "STRENGTH", "HABIT"]

        for (index, experienceValue) in experienceValues.enumerated() {
            var draft = OnboardingDraft()
            draft.experience = index
            draft.goal = index % goalValues.count
            draft.adjustFrequency(by: 1)

            let request = try XCTUnwrap(OnboardingSubmissionRequestMapper.request(for: draft))

            XCTAssertEqual(request.experienceLevel, .string(experienceValue))
            XCTAssertEqual(request.goalType, .string(goalValues[index % goalValues.count]))
            XCTAssertEqual(request.weeklyWorkoutTarget, 4)
        }
    }

    func testSubmissionPreservesServerMessageAndAllowsRetryAfterConflict() async throws {
        let service = OnboardingSubmissionTestService(failuresBeforeSuccess: 1)
        let viewModel = OnboardingSubmissionViewModel(service: service)
        var draft = OnboardingDraft()
        draft.experience = 1
        draft.goal = 2
        draft.adjustFrequency(by: 1)

        let firstResult = await viewModel.submit(draft: draft)

        XCTAssertFalse(firstResult)
        XCTAssertEqual(viewModel.errorMessage, "Already completed by another session.")
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertTrue(viewModel.canRetry)

        let retryResult = await viewModel.submit(draft: draft)
        let requests = await service.recordedRequests()

        XCTAssertTrue(retryResult)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.canRetry)
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].experienceLevel, .string("BEGINNER"))
        XCTAssertEqual(requests[0].goalType, .string("HABIT"))
        XCTAssertEqual(requests[0].weeklyWorkoutTarget, 4)
    }

    func testRequestMapperRejectsMissingExperience() {
        XCTAssertNil(OnboardingSubmissionRequestMapper.request(for: OnboardingDraft()))
    }

    func testUnavailableServiceIsNotASuccessAndCannotBeRetried() async {
        let viewModel = OnboardingSubmissionViewModel(service: nil)
        var draft = OnboardingDraft()
        draft.experience = 1

        let result = await viewModel.submit(draft: draft)

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, OnboardingSubmissionViewModel.unavailableServiceMessage)
        XCTAssertFalse(viewModel.canRetry)
    }
}

private actor OnboardingSubmissionTestService: OnboardingSubmissionServicing {
    private var failuresBeforeSuccess: Int
    private var requests: [SaveOnboardingRequest] = []

    init(failuresBeforeSuccess: Int) {
        self.failuresBeforeSuccess = failuresBeforeSuccess
    }

    func save(_ request: SaveOnboardingRequest) async throws -> SaveOnboardingResponse {
        requests.append(request)
        if failuresBeforeSuccess > 0 {
            failuresBeforeSuccess -= 1
            throw APIClientError.server(
                statusCode: 409,
                detail: ServerErrorDetail(code: "ALREADY_COMPLETED", message: "Already completed by another session.")
            )
        }

        return SaveOnboardingResponse(
            userId: "test-user",
            profileCompleted: true,
            experienceLevel: request.experienceLevel,
            goalType: request.goalType,
            weeklyWorkoutTarget: request.weeklyWorkoutTarget
        )
    }

    func recordedRequests() -> [SaveOnboardingRequest] {
        requests
    }
}
