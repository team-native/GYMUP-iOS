import XCTest
@testable import GYMUP

@MainActor
final class CurrentWeeklyGoalViewModelTests: XCTestCase {
    func testLoadIfNeededStoresResponseAndUsesCurrentTimeZone() async throws {
        let expected = try makeResponse(target: 4, completed: 2, achieved: false)
        let service = CurrentWeeklyGoalServiceStub(outcomes: [.success(expected)])
        let viewModel = CurrentWeeklyGoalViewModel(service: service)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.response, expected)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(service.fetchCount, 1)
        XCTAssertEqual(service.timeZoneIdentifiers, [TimeZone.current.identifier])
    }

    func testFailedRefreshRetainsResponseAndRetryCanSucceed() async throws {
        let initial = try makeResponse(target: 4, completed: 2, achieved: false)
        let refreshed = try makeResponse(target: 4, completed: 4, achieved: true)
        let service = CurrentWeeklyGoalServiceStub(
            outcomes: [.success(initial), .failure(.offline), .success(refreshed)]
        )
        let viewModel = CurrentWeeklyGoalViewModel(service: service)

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

    func testMissingServiceKeepsLocalMode() {
        let viewModel = CurrentWeeklyGoalViewModel()

        XCTAssertFalse(viewModel.usesServer)
    }

    private func makeResponse(target: Int, completed: Int, achieved: Bool) throws -> CurrentWeeklyGoalResponse {
        let json = """
        {"weekStart":"2026-11-02","weekEnd":"2026-11-08","targetCount":\(target),"completedCount":\(completed),"achieved":\(achieved)}
        """
        return try JSONDecoder().decode(CurrentWeeklyGoalResponse.self, from: Data(json.utf8))
    }
}

@MainActor
private final class CurrentWeeklyGoalServiceStub: CurrentWeeklyGoalReading {
    enum StubError: Error {
        case offline
    }

    enum Outcome {
        case success(CurrentWeeklyGoalResponse)
        case failure(StubError)
    }

    private var outcomes: [Outcome]
    private(set) var fetchCount = 0
    private(set) var timeZoneIdentifiers: [String] = []

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func fetch(timeZoneIdentifier: String) async throws -> CurrentWeeklyGoalResponse {
        fetchCount += 1
        timeZoneIdentifiers.append(timeZoneIdentifier)
        switch outcomes.removeFirst() {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}
