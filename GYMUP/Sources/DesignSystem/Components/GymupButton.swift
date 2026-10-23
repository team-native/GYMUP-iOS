import SwiftUI

struct GymupButton: View {
    enum Variant {
        case primary
        case secondary
        case ghost
    }

    let title: String
    var variant: Variant = .primary
    var isEnabled = true
    var font = GymupTypography.headline
    var height: CGFloat?
    var cornerRadius = GymupRadius.medium
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .padding(.vertical, height == nil ? GymupSpacing.medium : 0)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay {
                    if variant == .secondary {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(GymupColors.separator, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: .white
        case .secondary: GymupColors.primaryText
        case .ghost: GymupColors.secondaryText
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: GymupColors.accent
        case .secondary: GymupColors.surface
        case .ghost: .clear
        }
    }
}

extension GymupButton.Variant: Equatable {}

#Preview {
    VStack(spacing: GymupSpacing.medium) {
        GymupButton(title: "주요 버튼") {}
        GymupButton(title: "보조 버튼", variant: .secondary) {}
        GymupButton(title: "비활성 버튼", isEnabled: false) {}
    }
    .padding()
}
