import SwiftUI

struct GymupDetailNavigationBar: View {
    let title: String
    let onBack: () -> Void
    var actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        Text(title)
            .font(GymupTypography.uiStrong)
            .foregroundStyle(GymupColors.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay {
                HStack {
                    Button(action: onBack) {
                        Image("GymupIconChevronLeft")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("뒤로")
                    Spacer()
                    if let actionTitle {
                        Button {
                            onAction?()
                        } label: {
                            Text(actionTitle)
                                .font(GymupTypography.uiStrong)
                                .foregroundStyle(GymupColors.brandText)
                                .frame(width: 64, height: 40)
                        }
                        .disabled(onAction == nil)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
    }
}
