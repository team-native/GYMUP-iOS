import UIKit

enum WorkoutPhotoShareConfiguration {
    static let fileName = "GYMUP.jpg"

    @MainActor
    static func make(for image: UIImage) -> UIActivityItemsConfiguration {
        let posterProvider = NSItemProvider(object: image)
        posterProvider.suggestedName = fileName

        let configuration = UIActivityItemsConfiguration(itemProviders: [posterProvider])
        configuration.metadataProvider = { key in
            key == .title ? fileName : nil
        }
        return configuration
    }
}
