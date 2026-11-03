import SwiftUI

@main
struct GYMUPApp: App {
    @State private var isShowingSplash = true
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding = false
    private let onboardingSubmissionService: OnboardingSubmissionServicing?
    private let restTimeService: ProfileRestTimeUpdating?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--uitest-reset-onboarding") {
            UserDefaults.standard.removeObject(forKey: "onboarding.completed")
        }

#if DEBUG
        if arguments.contains("--uitest-no-onboarding-service") {
            onboardingSubmissionService = nil
        } else if arguments.contains("--uitest-ephemeral") {
            onboardingSubmissionService = UITestOnboardingSubmissionService(
                failsFirstRequest: arguments.contains("--uitest-onboarding-error")
            )
        } else {
            onboardingSubmissionService = DebugOnboardingNetworking.makeService()
        }
        restTimeService = arguments.contains("--uitest-ephemeral")
            ? nil
            : DebugOnboardingNetworking.makeRestTimeService()
#else
        onboardingSubmissionService = nil
        restTimeService = nil
#endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isShowingSplash {
                    SplashView()
                        .task {
                            try? await Task.sleep(for: .seconds(1.5))
                            guard !Task.isCancelled else { return }
                            isShowingSplash = false
                        }
                } else if !hasCompletedOnboarding {
                    OnboardingFlowView(
                        submissionService: onboardingSubmissionService
                    ) {
                        hasCompletedOnboarding = true
                    }
                } else {
                    MainTabView(restTimeService: restTimeService)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
