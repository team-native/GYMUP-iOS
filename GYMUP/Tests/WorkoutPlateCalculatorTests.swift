import XCTest
@testable import GYMUP

final class WorkoutPlateCalculatorTests: XCTestCase {
    func testCalculatesPlatesPerSide() {
        XCTAssertEqual(WorkoutPlateCalculator.platesPerSide(for: 62.5), [20, 1.25])
        XCTAssertEqual(WorkoutPlateCalculator.platesPerSide(for: 20), [])
        XCTAssertEqual(WorkoutPlateCalculator.platesPerSide(for: 100), [25, 15])
    }

    func testRejectsWeightsThatCannotBeLoaded() {
        XCTAssertNil(WorkoutPlateCalculator.platesPerSide(for: 19))
        XCTAssertNil(WorkoutPlateCalculator.platesPerSide(for: 21))
        XCTAssertNil(WorkoutPlateCalculator.platesPerSide(for: .infinity))
    }
}
