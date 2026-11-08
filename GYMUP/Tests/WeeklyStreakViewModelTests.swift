import XCTest
@testable import GYMUP

@MainActor
final class WeeklyStreakViewModelTests: XCTestCase {
    func testLoadIfNeededStoresSuccessfulResponse() async throws {
        let expected = try makeResponse(currentStreak: 3, longestStreak: 7, lastAchievedWeek: "2026-W44")
        let service = WeeklyStreakServiceStub(outcomes: [.success(expected)])
        let viewModel = WeeklyStreakViewModel(service: service)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.response, expected)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(service.fetchCount, 1)
    }

    func testFailedRefreshKeepsLastResponseAndRetryCanSucceed() async throws {
        let initial = try makeResponse(currentStreak: 3, longestStreak: 7, lastAchievedWeek: "2026-W44")
        let refreshed = try makeResponse(currentStreak: 4, longestStreak: 7, lastAchievedWeek: "2026-W45")
        let service = WeeklyStreakServiceStub(
            outcomes: [.success(initial), .failure(.offline), .success(refreshed)]
        )
        let viewModel = WeeklyStreakViewModel(service: service)

        await viewModel.loadIfNeeded()
        await viewModel.retry()

        XCTAssertEqual(viewModel.response, initial)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)

        await viewModel.retry()

        XCTAssertEqual(viewModel.response, refreshed)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(service.fetchCount, 3)
    }

    private func makeResponse(
        currentStreak: Int,
        longestStreak: Int,
        lastAchievedWeek: String
    ) throws -> WeeklyStreakResponse {
        let json = """
        {"currentStreak":\(currentStreak),"longestStreak":\(longestStreak),"lastAchievedWeek":"\(lastAchievedWeek)","status":"ACTIVE"}
        """
        let data = Data(json.utf8)
        return try JSONDecoder().decode(WeeklyStreakResponse.self, from: data)
    }
}

@MainActor
private final class WeeklyStreakServiceStub: WeeklyStreakReading {
    enum StubError: Error {
        case offline
    }

    enum Outcome {
        case success(WeeklyStreakResponse)
        case failure(StubError)
    }

    private var outcomes: [Outcome]
    private(set) var fetchCount = 0

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func fetch() async throws -> WeeklyStreakResponse {
        fetchCount += 1
        switch outcomes.removeFirst() {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}
