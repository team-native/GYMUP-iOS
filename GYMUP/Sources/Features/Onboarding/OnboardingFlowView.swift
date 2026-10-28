import SwiftUI

struct OnboardingFlowView: View {
    let onFinish: () -> Void
    @State private var step = 2
    @State private var experience: Int?
    @State private var purposes: Set<String> = []
    @State private var frequency = 3
    @State private var goal = 0
    @State private var weeks = 12
    @AppStorage("onboarding.experience") private var savedExperience = -1
    @AppStorage("onboarding.purposes") private var savedPurposes = ""
    @AppStorage("onboarding.frequency") private var savedFrequency = 3
    @AppStorage("onboarding.goal") private var savedGoal = 0
    @AppStorage("onboarding.weeks") private var savedWeeks = 12

    var body: some View {
        Group {
            switch step {
            case 2: OnboardingWelcomeView { step = 3 }
            case 3: OnboardingExperienceView(selection: $experience, onBack: { step = 2 }, onNext: { step = 4 })
            case 4: OnboardingPurposeView(selection: $purposes, onBack: { step = 3 }, onNext: { step = 5 })
            case 5: OnboardingFrequencyView(frequency: $frequency, onBack: { step = 4 }, onNext: { step = 6 })
            case 6: OnboardingGoalView(goal: $goal, weeks: $weeks, frequency: frequency, onBack: { step = 5 }, onNext: { step = 7 })
            case 7: OnboardingGoalCreatedView(frequency: frequency, weeks: weeks) { step = 8 }
            default: OnboardingNotificationView(onFinish: finish)
            }
        }.preferredColorScheme(.dark)
    }

    private func finish() {
        savedExperience = experience ?? -1
        savedPurposes = purposes.sorted().joined(separator: ",")
        savedFrequency = frequency
        savedGoal = goal
        savedWeeks = weeks
        onFinish()
    }
}
