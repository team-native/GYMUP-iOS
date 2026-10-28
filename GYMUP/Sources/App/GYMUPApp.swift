import SwiftUI

@main
struct GYMUPApp: App {
    @State private var startupStep = StartupStep.splash
    @State private var experience: Int?

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
    case home
}
