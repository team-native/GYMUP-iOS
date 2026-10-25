import SwiftUI

struct RoutineMoreActionsSheet: View {
    let routineTitle: String
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                Text(routineTitle)
                    .font(GymupTypography.uiSemibold)
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(alignment: .bottom) { divider }

                actionButton("편집", identifier: "routine.more.edit", color: GymupColors.brandText,
                             showsDivider: true, action: onEdit)
                actionButton("복제", identifier: "routine.more.duplicate", color: GymupColors.brandText,
                             showsDivider: true, action: onDuplicate)
                actionButton("삭제", identifier: "routine.more.delete", color: GymupColors.critical,
                             showsDivider: false, action: onDelete)
            }
            .background(GymupColors.overlay, in: RoundedRectangle(cornerRadius: 14))

            Button(action: onCancel) {
                Text("취소")
                    .font(.custom("GothicA1-Bold", size: 18))
                    .foregroundStyle(GymupColors.brandText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(GymupColors.overlay, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("routine.more.cancel")
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(GymupColors.strongBorder)
            .frame(height: 1)
    }

    private func actionButton(
        _ title: String,
        identifier: String,
        color: Color,
        showsDivider: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("GothicA1-Regular", size: 18))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .overlay(alignment: .bottom) {
                    if showsDivider { divider }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
