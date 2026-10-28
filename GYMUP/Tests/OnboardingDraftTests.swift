import XCTest
@testable import GYMUP

final class OnboardingDraftTests: XCTestCase {
    func testPurposeSelectionHasTwoItemLimitAndCanBeChanged() {
        var draft = OnboardingDraft()
        draft.togglePurpose("근비대")
        draft.togglePurpose("근력 향상")
        draft.togglePurpose("체지방 감량")
        XCTAssertEqual(draft.purposes, ["근비대", "근력 향상"])
        draft.togglePurpose("근비대")
        draft.togglePurpose("체지방 감량")
        XCTAssertEqual(draft.purposes, ["근력 향상", "체지방 감량"])
    }

    func testFrequencyStaysWithinOneWeek() {
        var draft = OnboardingDraft()
        draft.adjustFrequency(by: -10)
        XCTAssertEqual(draft.frequency, 1)
        draft.adjustFrequency(by: 10)
        XCTAssertEqual(draft.frequency, 7)
    }
}
