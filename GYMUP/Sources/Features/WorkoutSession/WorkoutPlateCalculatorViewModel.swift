import Foundation
import Observation

protocol WorkoutPlateCalculating {
    func calculate(_ request: PlateCalculatorRequest) async throws -> PlateCalculatorResponse
}

extension PlateCalculatorAPIService: WorkoutPlateCalculating {}

@Observable
@MainActor
final class WorkoutPlateCalculatorViewModel {
    let target: Double

    private let service: WorkoutPlateCalculating?
    private let request: PlateCalculatorRequest?
    private var didAttemptCalculation = false

    private(set) var response: PlateCalculatorResponse?
    private(set) var isCalculating = false
    private(set) var serverErrorMessage: String?

    init(target: Double, service: WorkoutPlateCalculating?) {
        self.target = target
        self.service = service
        request = Self.makeRequest(target: target)
        response = Self.localResponse(target: target)
    }

    var isValidTarget: Bool { request != nil }
    var canRetry: Bool { serverErrorMessage != nil && service != nil && request != nil }
    var canRequestServerResult: Bool { service != nil && request != nil }

    func calculateIfAvailable() async {
        guard !didAttemptCalculation else { return }
        await calculate()
    }

    func retry() async {
        guard canRetry else { return }
        await calculate()
    }

    private func calculate() async {
        guard !isCalculating,
              let service,
              let request
        else {
            return
        }

        didAttemptCalculation = true
        isCalculating = true
        serverErrorMessage = nil
        defer { isCalculating = false }

        do {
            response = try await service.calculate(request)
        } catch {
            serverErrorMessage = Self.errorMessage(for: error, hasLocalResult: response != nil)
        }
    }

    private static func makeRequest(target: Double) -> PlateCalculatorRequest? {
        guard target.isFinite,
              target >= WorkoutPlateCalculator.barWeight,
              target <= 999
        else {
            return nil
        }

        return PlateCalculatorRequest(
            targetWeight: target,
            barWeight: WorkoutPlateCalculator.barWeight,
            availablePlates: WorkoutPlateCalculator.plates.map(JSONValue.number)
        )
    }

    private static func localResponse(target: Double) -> PlateCalculatorResponse? {
        guard target.isFinite,
              target >= WorkoutPlateCalculator.barWeight,
              target <= 999
        else {
            return nil
        }

        let perSideUnits = (target - WorkoutPlateCalculator.barWeight) / 2 / 1.25
        let exactUnits = abs(perSideUnits - perSideUnits.rounded()) < 0.000_001
        let localTarget = exactUnits
            ? target
            : WorkoutPlateCalculator.barWeight + 2 * floor(perSideUnits) * 1.25
        guard let plates = WorkoutPlateCalculator.platesPerSide(for: localTarget) else { return nil }

        let groupedPlates = Dictionary(grouping: plates, by: \.self)
            .map { weight, plates in PlateWeightCount(weight: weight, count: plates.count) }
            .sorted { $0.weight > $1.weight }
        let actualWeight = WorkoutPlateCalculator.barWeight + 2 * plates.reduce(0, +)
        let remainder = max(target - actualWeight, 0)

        return PlateCalculatorResponse(
            achievable: remainder < 0.000_001,
            eachSide: groupedPlates,
            actualWeight: actualWeight,
            remainder: remainder
        )
    }

    private static func errorMessage(for error: Error, hasLocalResult: Bool) -> String {
        if case let APIClientError.server(_, detail) = error {
            return detail.message
        }

        return hasLocalResult
            ? "서버 연결에 실패해 기존 계산 결과를 보여드려요."
            : "계산 결과를 불러오지 못했어요. 다시 시도해 주세요."
    }
}
