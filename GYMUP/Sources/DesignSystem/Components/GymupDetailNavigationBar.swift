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
                                .fixedSize(horizontal: true, vertical: false)
                                .frame(minWidth: 64, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .disabled(onAction == nil)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
    }
}
