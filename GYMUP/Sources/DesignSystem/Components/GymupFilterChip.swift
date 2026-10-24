import SwiftUI

struct GymupFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.primaryText)
                .frame(minHeight: 19)
                .padding(.horizontal, isSelected ? 11 : 12)
                .padding(.vertical, isSelected ? 5 : 6)
                .background(isSelected ? GymupColors.accent : .clear, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(isSelected ? .clear : GymupColors.strongBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "선택됨" : "")
    }
}
