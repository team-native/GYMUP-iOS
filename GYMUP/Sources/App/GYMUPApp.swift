import SwiftUI

@main
struct GYMUPApp: App {
    @State private var startupStep = StartupStep.splash

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
                    OnboardingWelcomeView { startupStep = .home }
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
    case home
}
