import SwiftUI

struct GymupTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            Text(title)
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.secondaryText)

            TextField(placeholder, text: $text)
                .font(GymupTypography.body)
                .padding(GymupSpacing.large)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: GymupRadius.medium)
                        .strokeBorder(GymupColors.separator, lineWidth: 1)
                }
                .accessibilityLabel(title)
        }
    }
}

#Preview {
    @Previewable @State var text = ""

    GymupTextField(title: "이름", placeholder: "이름을 입력하세요", text: $text)
        .padding()
}
