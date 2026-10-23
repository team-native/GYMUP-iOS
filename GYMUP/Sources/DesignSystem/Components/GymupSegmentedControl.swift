import SwiftUI
import UIKit

struct GymupSegmentedControl<Selection>: UIViewRepresentable
where Selection: CaseIterable & Hashable & RawRepresentable, Selection.RawValue == String {
    @Binding var selection: Selection
    private var options: [Selection] { Array(Selection.allCases) }

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: options.map(\.rawValue))
        control.backgroundColor = UIColor(GymupColors.elevatedSurface)
        control.selectedSegmentTintColor = UIColor(GymupColors.overlay)
        control.setBackgroundImage(
            background(color: UIColor(GymupColors.elevatedSurface), inset: 0, radius: 9), for: .normal, barMetrics: .default
        )
        control.setBackgroundImage(
            background(color: UIColor(GymupColors.overlay), inset: 2, radius: 7), for: .selected, barMetrics: .default
        )
        control.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        control.layer.cornerRadius = 9
        control.clipsToBounds = true
        control.setTitleTextAttributes([
            .font: UIFont(name: "GothicA1-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor(GymupColors.secondaryText)
        ], for: .normal)
        control.setTitleTextAttributes([
            .font: UIFont(name: "GothicA1-SemiBold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor(GymupColors.primaryText)
        ], for: .selected)
        control.addTarget(context.coordinator, action: #selector(Coordinator.selectionChanged(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ control: UISegmentedControl, context: Context) {
        context.coordinator.parent = self
        control.selectedSegmentIndex = options.firstIndex(of: selection) ?? 0
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    private func background(color: UIColor, inset: CGFloat, radius: CGFloat) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset), cornerRadius: radius).fill()
        }
        return image.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }

    final class Coordinator: NSObject {
        var parent: GymupSegmentedControl<Selection>

        init(parent: GymupSegmentedControl<Selection>) { self.parent = parent }

        @objc func selectionChanged(_ control: UISegmentedControl) {
            guard parent.options.indices.contains(control.selectedSegmentIndex) else { return }
            parent.selection = parent.options[control.selectedSegmentIndex]
        }
    }
}
