import Foundation

enum WorkoutPlateCalculator {
    static let barWeight = 20.0
    static let plates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25]

    static func platesPerSide(for target: Double) -> [Double]? {
        guard target.isFinite, target >= barWeight, target <= 999 else { return nil }
        let units = (target - barWeight) / 2 / 1.25
        guard abs(units - units.rounded()) < 0.000_001 else { return nil }
        var remaining = Int(units.rounded())
        var result: [Double] = []
        for plate in plates {
            let plateUnits = Int((plate / 1.25).rounded())
            let count = remaining / plateUnits
            result.append(contentsOf: Array(repeating: plate, count: count))
            remaining %= plateUnits
        }
        return remaining == 0 ? result : nil
    }
}
