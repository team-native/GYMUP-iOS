import SwiftUI

struct GymupSectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(GymupTypography.headline)
                .foregroundStyle(GymupColors.primaryText)

            Spacer(minLength: GymupSpacing.medium)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(GymupTypography.callout)
                    .foregroundStyle(GymupColors.accent)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
    }
}

#Preview {
    GymupSectionHeader(title: "이번 주", actionTitle: "전체 보기") {}
        .padding()
}
