import SwiftUI

@main
struct GYMUPApp: App {
    @State private var isShowingSplash = true
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding = false

    init() {
        if ProcessInfo.processInfo.arguments.contains("--uitest-reset-onboarding") {
            UserDefaults.standard.removeObject(forKey: "onboarding.completed")
        }
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
                    OnboardingFlowView { hasCompletedOnboarding = true }
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
