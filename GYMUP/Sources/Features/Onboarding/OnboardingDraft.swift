import Foundation

struct OnboardingDraft {
    var experience: Int?
    private(set) var purposes: Set<String> = []
    private(set) var frequency = 3
    var goal = 0
    var weeks = 12

    mutating func togglePurpose(_ purpose: String) {
        if purposes.contains(purpose) {
            purposes.remove(purpose)
        } else if purposes.count < 2 {
            purposes.insert(purpose)
        }
    }

    mutating func adjustFrequency(by amount: Int) {
        frequency = min(max(frequency + amount, 1), 7)
    }
}
