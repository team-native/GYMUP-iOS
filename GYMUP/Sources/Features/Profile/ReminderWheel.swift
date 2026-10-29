import SwiftUI

struct ReminderWheel<Value: Hashable>: View {
    let title: String
    let values: [Value]
    @Binding var selection: Value
    let text: (Value) -> String
    var isPeriod = false
    let identifier: String

    private var selectedIndex: Int { values.firstIndex(of: selection) ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(-2...2, id: \.self) { offset in
                if let value = value(at: selectedIndex + offset) {
                    Button {
                        selection = value
                    } label: {
                        Text(text(value))
                            .font(.custom(isPeriod ? "GothicA1-Bold" : "BarlowCondensed-ExtraBold",
                                          size: offset == 0 ? 28 : 18))
                            .foregroundStyle(offset == 0 ? GymupColors.brandText : GymupColors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(text(value))")
                    .accessibilityIdentifier("\(identifier).\(text(value))")
                } else {
                    Color.clear.frame(height: 24).accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 143)
        .contentShape(Rectangle())
        .highPriorityGesture(DragGesture(minimumDistance: 10).onEnded { gesture in
            let steps = Int((-gesture.translation.height / 24).rounded())
            if let value = value(at: selectedIndex + steps) { selection = value }
        })
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .accessibilityValue(text(selection))
        .accessibilityIdentifier(identifier)
        .accessibilityAdjustableAction { direction in
            let step = direction == .increment ? 1 : -1
            if let value = value(at: selectedIndex + step) { selection = value }
        }
    }

    private func value(at index: Int) -> Value? {
        guard !values.isEmpty else { return nil }
        if isPeriod { return values.indices.contains(index) ? values[index] : nil }
        let wrapped = (index % values.count + values.count) % values.count
        return values[wrapped]
    }
}
