import XCTest
@testable import GYMUP

final class WorkoutPlateCalculatorViewModelTests: XCTestCase {
    @MainActor
    func testServerResponseReplacesLocalPlateComposition() async throws {
        let serverResponse = PlateCalculatorResponse(
            achievable: true,
            eachSide: [PlateWeightCount(weight: 20, count: 2)],
            actualWeight: 100,
            remainder: 0
        )
        let service = PlateCalculatorServiceStub(outcomes: [.success(serverResponse)])
        let viewModel = WorkoutPlateCalculatorViewModel(target: 100, service: service)

        XCTAssertEqual(
            viewModel.response?.eachSide,
            [PlateWeightCount(weight: 25, count: 1), PlateWeightCount(weight: 15, count: 1)]
        )

        await viewModel.calculateIfAvailable()

        XCTAssertEqual(viewModel.response, serverResponse)
        XCTAssertNil(viewModel.serverErrorMessage)
        XCTAssertFalse(viewModel.canRetry)
        XCTAssertEqual(service.requests.count, 1)
    }

    @MainActor
    func testRequestFailureKeepsLocalResultAndAllowsRetry() async throws {
        let service = PlateCalculatorServiceStub(outcomes: [.failure(.offline)])
        let viewModel = WorkoutPlateCalculatorViewModel(target: 100.5, service: service)
        let localResult = try XCTUnwrap(viewModel.response)

        await viewModel.calculateIfAvailable()

        XCTAssertEqual(viewModel.response, localResult)
        XCTAssertEqual(viewModel.serverErrorMessage, "서버 연결에 실패해 기존 계산 결과를 보여드려요.")
        XCTAssertTrue(viewModel.canRetry)
        XCTAssertFalse(viewModel.isCalculating)
    }

    @MainActor
    func testRetrySendsTheOriginalRequestAndAppliesSuccessfulResponse() async {
        let serverResponse = PlateCalculatorResponse(
            achievable: true,
            eachSide: [PlateWeightCount(weight: 20, count: 2)],
            actualWeight: 100,
            remainder: 0
        )
        let service = PlateCalculatorServiceStub(outcomes: [.failure(.offline), .success(serverResponse)])
        let viewModel = WorkoutPlateCalculatorViewModel(target: 100, service: service)

        await viewModel.calculateIfAvailable()
        await viewModel.retry()

        let expectedRequest = PlateCalculatorRequest(
            targetWeight: 100,
            barWeight: 20,
            availablePlates: [25, 20, 15, 10, 5, 2.5, 1.25].map(JSONValue.number)
        )
        XCTAssertEqual(service.requests, [expectedRequest, expectedRequest])
        XCTAssertEqual(viewModel.response, serverResponse)
        XCTAssertNil(viewModel.serverErrorMessage)
        XCTAssertFalse(viewModel.canRetry)
    }

    @MainActor
    func testInvalidTargetDoesNotCreateOrSendServerRequest() async {
        let service = PlateCalculatorServiceStub(outcomes: [])
        let viewModel = WorkoutPlateCalculatorViewModel(target: 19, service: service)

        await viewModel.calculateIfAvailable()

        XCTAssertFalse(viewModel.isValidTarget)
        XCTAssertNil(viewModel.response)
        XCTAssertTrue(service.requests.isEmpty)
        XCTAssertNil(viewModel.serverErrorMessage)
    }
}

@MainActor
private final class PlateCalculatorServiceStub: WorkoutPlateCalculating {
    enum Outcome {
        case success(PlateCalculatorResponse)
        case failure(StubError)
    }

    enum StubError: Error {
        case offline
    }

    private var outcomes: [Outcome]
    private(set) var requests: [PlateCalculatorRequest] = []

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func calculate(_ request: PlateCalculatorRequest) async throws -> PlateCalculatorResponse {
        requests.append(request)
        switch outcomes.removeFirst() {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}
