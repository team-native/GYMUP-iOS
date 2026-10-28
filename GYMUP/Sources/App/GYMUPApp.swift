import SwiftUI

@main
struct GYMUPApp: App {
    @State private var startupStep = StartupStep.splash
    @State private var experience: Int?
    @State private var purposes: Set<String> = []
    @State private var frequency = 3

    var body: some Scene {
        WindowGroup {
            Group {
                switch startupStep {
                case .splash:
                    SplashView()
                        .task {
                            try? await Task.sleep(for: .seconds(1.5))
                            guard !Task.isCancelled else { return }
                            startupStep = .welcome
                        }
                case .welcome:
                    OnboardingWelcomeView { startupStep = .experience }
                case .experience:
                    OnboardingExperienceView(
                        selection: $experience,
                        onBack: { startupStep = .welcome },
                        onNext: { startupStep = .purpose }
                    )
                case .purpose:
                    OnboardingPurposeView(
                        selection: $purposes,
                        onBack: { startupStep = .experience },
                        onNext: { startupStep = .frequency }
                    )
                case .frequency:
                    OnboardingFrequencyView(
                        frequency: $frequency,
                        onBack: { startupStep = .purpose },
                        onNext: { startupStep = .home }
                    )
                case .home:
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

private enum StartupStep {
    case splash
    case welcome
    case experience
    case purpose
    case frequency
    case home
}
