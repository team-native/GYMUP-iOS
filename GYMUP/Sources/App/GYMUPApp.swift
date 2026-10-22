import SwiftUI

@main
struct GYMUPApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(GymupColors.accent)
        }
    }
}
