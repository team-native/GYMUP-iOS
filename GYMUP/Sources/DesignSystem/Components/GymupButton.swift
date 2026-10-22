import SwiftUI

struct GymupButton: View {
    enum Variant {
        case primary
        case secondary
    }

    let title: String
    var variant: Variant = .primary
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GymupTypography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GymupSpacing.medium)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
                .overlay {
                    if variant == .secondary {
                        RoundedRectangle(cornerRadius: GymupRadius.medium)
                            .strokeBorder(GymupColors.separator, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private var foregroundColor: Color {
        variant == .primary ? .white : GymupColors.primaryText
    }

    private var backgroundColor: Color {
        variant == .primary ? GymupColors.accent : GymupColors.surface
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
