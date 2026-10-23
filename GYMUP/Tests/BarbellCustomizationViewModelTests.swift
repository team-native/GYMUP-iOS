import XCTest
@testable import GYMUP

final class BarbellCustomizationViewModelTests: XCTestCase {
    @MainActor
    func testCategoryFiltersInventory() {
        let viewModel = BarbellCustomizationViewModel()
        viewModel.selectedCategory = .plate
        XCTAssertEqual(viewModel.filteredItems.map(\.id), [.redPlate, .blackPlate])
        viewModel.selectedCategory = .bar
        XCTAssertEqual(viewModel.filteredItems.map(\.id), [.olympicBar, .chain])
        viewModel.selectedCategory = .all
        XCTAssertEqual(viewModel.filteredItems.count, 6)
    }

    @MainActor
    func testLockedItemCannotReplaceEquippedPlate() {
        let viewModel = BarbellCustomizationViewModel()
        XCTAssertFalse(viewModel.equipPlate(.olympicBar))
        XCTAssertFalse(viewModel.equipPlate(.goldCollar))
        XCTAssertEqual(viewModel.equippedPlateID, .redPlate)
    }

    @MainActor
    func testEquippingNewPlateClearsNewStatus() {
        let viewModel = BarbellCustomizationViewModel()
        XCTAssertTrue(viewModel.equipPlate(.blackPlate))
        XCTAssertEqual(viewModel.equippedPlateID, .blackPlate)
        XCTAssertEqual(viewModel.equippedDescription, "블랙 원판 · 기본 칼라 착용 중")
        XCTAssertFalse(viewModel.items.first { $0.id == .blackPlate }?.isNew ?? true)
        XCTAssertTrue(viewModel.equipPlate(.redPlate))
        XCTAssertEqual(viewModel.equippedPlateID, .redPlate)
    }
}
