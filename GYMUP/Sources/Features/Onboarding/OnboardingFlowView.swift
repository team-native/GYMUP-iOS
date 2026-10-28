import SwiftUI

struct OnboardingFlowView: View {
    let onFinish: () -> Void
    @State private var step = 2
    @State private var draft = OnboardingDraft()
    @AppStorage("onboarding.experience") private var savedExperience = -1
    @AppStorage("onboarding.purposes") private var savedPurposes = ""
    @AppStorage("onboarding.frequency") private var savedFrequency = 3
    @AppStorage("onboarding.goal") private var savedGoal = 0
    @AppStorage("onboarding.weeks") private var savedWeeks = 12
    @AppStorage("onboarding.goal.startedAt") private var savedGoalStartedAt = ""

    var body: some View {
        Group {
            switch step {
            case 2: OnboardingWelcomeView { step = 3 }
            case 3: OnboardingExperienceView(selection: $draft.experience, onBack: { step = 2 }, onNext: { step = 4 })
            case 4: OnboardingPurposeView(draft: $draft, onBack: { step = 3 }, onNext: { step = 5 })
            case 5: OnboardingFrequencyView(draft: $draft, onBack: { step = 4 }, onNext: { step = 6 })
            case 6: OnboardingGoalView(goal: $draft.goal, weeks: $draft.weeks, frequency: draft.frequency,
                                      onBack: { step = 5 }, onNext: { step = 7 })
            case 7: OnboardingGoalCreatedView(frequency: draft.frequency, weeks: draft.weeks) { step = 8 }
            default: OnboardingNotificationView(onFinish: finish)
            }
        }.preferredColorScheme(.dark)
    }

    private func finish() {
        savedExperience = draft.experience ?? -1
        savedPurposes = draft.purposes.sorted().joined(separator: ",")
        savedFrequency = draft.frequency
        savedGoal = draft.goal
        savedWeeks = draft.weeks
        savedGoalStartedAt = ISO8601DateFormatter().string(from: .now)
        onFinish()
    }
}
