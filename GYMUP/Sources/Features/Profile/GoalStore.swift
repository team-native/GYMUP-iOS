import Foundation
import Observation

@Observable
@MainActor
final class GoalStore {
    static let shared = GoalStore()
    private let defaults: UserDefaults
    private(set) var revision = 0
    private(set) var archived: [ProfileGoalRecord]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        archived = defaults.data(forKey: "goals.archive.v1")
            .flatMap { try? JSONDecoder().decode([ProfileGoalRecord].self, from: $0) } ?? []
    }

    var settings: OnboardingStoredSettings? {
        _ = revision
        return OnboardingStoredSettings.load(from: defaults)
    }

    func goals(historyStore: HistoryStore) -> [ProfileGoalRecord] {
        guard let settings else { return archived }
        let growth = GrowthViewModel(historyStore: historyStore, goalSettings: settings)
        let current = ProfileGoalRecord(
            type: ProfileGoalType.allCases[settings.goal], workoutsPerWeek: settings.frequency,
            durationWeeks: settings.weeks, period: "진행 중", growth: growth.growth,
            completedWeeks: max(growth.currentWeek - 1, 0), isCurrent: true
        )
        return [current] + archived
    }

    func start(_ goal: ProfileGoalRecord, historyStore: HistoryStore, now: Date = .now) {
        if var previous = goals(historyStore: historyStore).first(where: \.isCurrent) {
            previous.isCurrent = false
            previous.period = settings?.goalStartedAt.map { HistoryDateText.string($0, format: "yyyy.MM.dd") } ?? "이전 목표"
            previous.period += " – " + HistoryDateText.string(now, format: "yyyy.MM.dd")
            archived.insert(previous, at: 0)
        }
        defaults.set(try? JSONEncoder().encode(archived), forKey: "goals.archive.v1")
        defaults.set(ProfileGoalType.allCases.firstIndex(of: goal.type) ?? 0, forKey: "onboarding.goal")
        defaults.set(goal.workoutsPerWeek, forKey: "onboarding.frequency")
        defaults.set(goal.durationWeeks, forKey: "onboarding.weeks")
        defaults.set(ISO8601DateFormatter().string(from: now), forKey: "onboarding.goal.startedAt")
        revision += 1
    }
}
