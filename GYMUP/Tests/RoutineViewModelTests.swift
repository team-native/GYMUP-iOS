import XCTest
@testable import GYMUP

final class RoutineViewModelTests: XCTestCase {
    @MainActor
    func testRecommendationFilterAndReturnToMyRoutines() {
        let store = RoutineStore()
        let viewModel = RoutineViewModel(store: store)
        viewModel.mode = .recommended
        XCTAssertFalse(viewModel.routines.isEmpty)
        XCTAssertTrue(viewModel.routines.allSatisfy(\.isRecommended))
        XCTAssertFalse(viewModel.routines.contains(where: \.isEmpty))
        viewModel.mode = .mine
        XCTAssertEqual(viewModel.routines, store.routines)
        XCTAssertTrue(viewModel.routines.contains(where: \.isEmpty))
    }
}
