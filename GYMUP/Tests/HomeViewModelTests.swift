import XCTest
@testable import GYMUP

final class HomeViewModelTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let viewModel = HomeViewModel()

        XCTAssertEqual(viewModel.greeting, "디자인 시스템 기본 구성이 준비되었습니다.")
        XCTAssertFalse(viewModel.hasStarted)
    }

    @MainActor
    func testGreetingUsesEnteredName() {
        let viewModel = HomeViewModel()
        viewModel.name = "시우"

        XCTAssertEqual(viewModel.greeting, "안녕하세요, 시우님.")
    }

    @MainActor
    func testStartUpdatesState() {
        let viewModel = HomeViewModel()

        viewModel.start()

        XCTAssertTrue(viewModel.hasStarted)
    }
}
