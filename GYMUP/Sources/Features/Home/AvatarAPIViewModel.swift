import Foundation
import Observation

@Observable
@MainActor
final class AvatarAPIViewModel {
    private let service: AvatarReading?

    private(set) var avatar: AvatarResponse?
    private(set) var growthStage: AvatarGrowthStageResponse?
    private(set) var items: AvatarItemsResponse?
    private(set) var isLoadingAvatar = false
    private(set) var isLoadingGrowthStage = false
    private(set) var isLoadingItems = false
    private(set) var avatarErrorMessage: String?
    private(set) var growthStageErrorMessage: String?
    private(set) var itemsErrorMessage: String?

    init(service: AvatarReading?) {
        self.service = service
    }

    var isAvailable: Bool { service != nil }

    func loadAvatar() async {
        guard !isLoadingAvatar, let service else { return }
        isLoadingAvatar = true
        avatarErrorMessage = nil
        defer { isLoadingAvatar = false }
        do {
            avatar = try await service.fetchAvatar()
        } catch is CancellationError {
            return
        } catch {
            avatarErrorMessage = Self.message(for: error)
        }
    }

    func loadGrowthStage() async {
        guard !isLoadingGrowthStage, let service else { return }
        isLoadingGrowthStage = true
        growthStageErrorMessage = nil
        defer { isLoadingGrowthStage = false }
        do {
            growthStage = try await service.fetchGrowthStage()
        } catch is CancellationError {
            return
        } catch {
            growthStageErrorMessage = Self.message(for: error)
        }
    }

    func loadItems() async {
        guard !isLoadingItems, let service else { return }
        isLoadingItems = true
        itemsErrorMessage = nil
        defer { isLoadingItems = false }
        do {
            items = try await service.fetchItems(AvatarItemsQuery(status: "all", cursor: nil, size: 20))
        } catch is CancellationError {
            return
        } catch {
            itemsErrorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        if case let APIClientError.server(_, detail) = error { return detail.message }
        return "서버 정보를 불러오지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요."
    }
}
