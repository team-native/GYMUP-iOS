import SwiftUI

@main
struct GYMUPApp: App {
    var body: some Scene {
        WindowGroup {
            WorkoutCompletionFlowView()
                .preferredColorScheme(.dark)
        }
    }
}
