import Foundation
import Observation

@Observable
@MainActor
final class WeeklyStreakViewModel {
    private let service: WeeklyStreakReading?
    private var hasAttemptedLoad = false
    private(set) var response: WeeklyStreakResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(service: WeeklyStreakReading? = nil) {
        self.service = service
    }

    var usesServer: Bool { service != nil }

    func loadIfNeeded() async {
        guard !hasAttemptedLoad else { return }
        hasAttemptedLoad = true
        await load()
    }

    func retry() async {
        await load()
    }

    private func load() async {
        guard let service, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            response = try await service.fetch()
        } catch let error as APIClientError {
            if case let .server(_, detail) = error {
                errorMessage = detail.message
            } else {
                errorMessage = "주간 스트릭을 불러오지 못했어요. 다시 시도해 주세요."
            }
        } catch {
            errorMessage = "주간 스트릭을 불러오지 못했어요. 다시 시도해 주세요."
        }
    }
}
