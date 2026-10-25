import SwiftUI
import UIKit

struct WorkoutPhotoSharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct WorkoutPhotoShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let onCompletion: (WorkoutPhotoActivityResult) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let configuration = WorkoutPhotoShareConfiguration.make(for: image)
        let controller = UIActivityViewController(activityItemsConfiguration: configuration)
        controller.completionWithItemsHandler = { activityType, completed, _, error in
            let result = WorkoutPhotoActivityResult.resolve(
                isPhotoSaveActivity: activityType == .saveToCameraRoll,
                completed: completed,
                hasError: error != nil
            )

            DispatchQueue.main.async {
                onCompletion(result)
            }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
