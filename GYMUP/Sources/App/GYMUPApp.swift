import SwiftUI

@main
struct GYMUPApp: App {
    @State private var isShowingSplash = true

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
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
