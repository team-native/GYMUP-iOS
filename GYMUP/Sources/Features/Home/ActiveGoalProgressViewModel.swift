import Foundation
import Observation

@Observable
@MainActor
final class ActiveGoalProgressViewModel {
    private let service: ActiveGoalProgressReading?
    private(set) var response: ActiveGoalProgressResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(service: ActiveGoalProgressReading?) {
        self.service = service
    }

    var isAvailable: Bool { service != nil }

    func refresh() async {
        guard !isLoading, let service else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            response = try await service.fetchActiveProgress()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        if case let APIClientError.server(_, detail) = error {
            return detail.message
        }
        return "Growth를 불러오지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요."
    }
}
