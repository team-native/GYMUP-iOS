import XCTest
@testable import GYMUP

final class RoutineSaveValidationTests: XCTestCase {
    func testNewEmptyRoutineReportsBothMissingRequirements() {
        let validation = RoutineSaveValidation(title: "  ", exerciseCount: 0)

        XCTAssertTrue(validation.isRoutineNameMissing)
        XCTAssertTrue(validation.areExercisesMissing)
        XCTAssertFalse(validation.isValid)
    }

    func testRoutineWithNameAndExerciseCanSave() {
        let validation = RoutineSaveValidation(title: "상체 A", exerciseCount: 1)

        XCTAssertFalse(validation.isRoutineNameMissing)
        XCTAssertFalse(validation.areExercisesMissing)
        XCTAssertTrue(validation.isValid)
    }
}
