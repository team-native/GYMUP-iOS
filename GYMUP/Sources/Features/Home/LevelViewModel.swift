import Observation

struct LevelXPFactor: Identifiable {
    let title: String
    let value: String
    var id: String { title }
}

struct LevelXPEntry: Identifiable {
    let title: String
    let date: String
    let value: Int
    var id: String { title }
}

@Observable
@MainActor
final class LevelViewModel {
    private let service: UserLevelReading?
    private var hasAttemptedLoad = false
    private(set) var serverLevel: UserLevelResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(service: UserLevelReading? = nil) {
        self.service = service
    }

    // Keep the existing local preview values only when no service is configured
    // (Release and previews). A configured service is the source of truth.
    var level: Int? { serverLevel?.level ?? (service == nil ? 17 : nil) }
    var experience: Int? { serverLevel?.currentXp ?? (service == nil ? 2_340 : nil) }
    var targetExperience: Int? { serverLevel?.nextLevelXp ?? (service == nil ? 3_000 : nil) }
    var showsLocalSampleDetails: Bool { service == nil }
    let nextReward = "골드 칼라 (바벨 아이템)"
    let factors = [
        LevelXPFactor(title: "운동 완료", value: "+200"),
        LevelXPFactor(title: "루틴 100%", value: "+100"),
        LevelXPFactor(title: "PR", value: "+25/개"),
        LevelXPFactor(title: "주간 목표", value: "+30")
    ]
    let recentExperience = [
        LevelXPEntry(title: "상체 A 완료", date: "10월 11일", value: 380),
        LevelXPEntry(title: "하체 B 완료", date: "10월 8일", value: 300),
        LevelXPEntry(title: "주간 목표 달성", date: "10월 5일", value: 30)
    ]

    var remainingExperience: Int? {
        guard let experience, let targetExperience else { return nil }
        return max(targetExperience - experience, 0)
    }

    var progress: Double? {
        if let serverLevel {
            return min(max(serverLevel.progressPercent / 100, 0), 1)
        }
        guard service == nil,
              let experience,
              let targetExperience,
              targetExperience > 0 else { return nil }
        return min(max(Double(experience) / Double(targetExperience), 0), 1)
    }

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
            serverLevel = try await service.fetch()
        } catch let error as APIClientError {
            if case let .server(_, detail) = error {
                errorMessage = detail.message
            } else {
                errorMessage = "레벨 정보를 불러오지 못했어요. 다시 시도해 주세요."
            }
        } catch {
            errorMessage = "레벨 정보를 불러오지 못했어요. 다시 시도해 주세요."
        }
    }
}
