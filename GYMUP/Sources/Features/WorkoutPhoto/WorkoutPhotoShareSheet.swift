import SwiftUI
import UIKit

struct WorkoutPhotoSharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct WorkoutPhotoShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let onCompletion: (Bool, Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        controller.completionWithItemsHandler = { activityType, completed, _, error in
            let didSaveToPhotos = completed && activityType == .saveToCameraRoll
            let didFail = error != nil

            DispatchQueue.main.async {
                onCompletion(didSaveToPhotos, didFail)
            }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
