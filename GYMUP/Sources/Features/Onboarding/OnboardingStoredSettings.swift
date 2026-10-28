import Foundation

struct OnboardingStoredSettings: Equatable {
    let experience: Int
    let purposes: [String]
    let frequency: Int
    let goal: Int
    let weeks: Int
    let goalStartedAt: Date?

    static func load(from defaults: UserDefaults = .standard) -> OnboardingStoredSettings? {
        guard defaults.bool(forKey: "onboarding.completed") else { return nil }
        let experience = defaults.integer(forKey: "onboarding.experience")
        let frequency = defaults.integer(forKey: "onboarding.frequency")
        let goal = defaults.integer(forKey: "onboarding.goal")
        let weeks = defaults.integer(forKey: "onboarding.weeks")
        let goalStartedAt = defaults.string(forKey: "onboarding.goal.startedAt")
            .flatMap { ISO8601DateFormatter().date(from: $0) }
        let purposes = (defaults.string(forKey: "onboarding.purposes") ?? "")
            .split(separator: ",").map(String.init)
        guard (0...3).contains(experience), (1...7).contains(frequency), (0...2).contains(goal),
              [4, 8, 12, 16].contains(weeks), !purposes.isEmpty else { return nil }
        return OnboardingStoredSettings(experience: experience, purposes: purposes,
                                        frequency: frequency, goal: goal, weeks: weeks,
                                        goalStartedAt: goalStartedAt)
    }
}
