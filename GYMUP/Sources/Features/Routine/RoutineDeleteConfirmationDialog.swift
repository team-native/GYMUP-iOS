import SwiftUI

struct RoutineDeleteConfirmationDialog: View {
    let routineTitle: String
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(routineTitle)를 삭제할까요?")
                    .font(.custom("GothicA1-Bold", size: 17))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(maxWidth: .infinity)
                Text("루틴만 삭제되고 지난 운동 기록은 그대로 남아요.")
                    .font(.custom("GothicA1-Regular", size: 13))
                    .foregroundStyle(GymupColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 18)

            HStack(spacing: 0) {
                Button(action: onCancel) {
                    Text("취소")
                        .font(.custom("GothicA1-Regular", size: 17))
                        .foregroundStyle(GymupColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("routine.delete.cancel")

                Rectangle()
                    .fill(GymupColors.strongBorder)
                    .frame(width: 1, height: 44)

                Button(action: onDelete) {
                    Text("삭제")
                        .font(.custom("GothicA1-Bold", size: 17))
                        .foregroundStyle(GymupColors.critical)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("routine.delete.confirm")
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(GymupColors.strongBorder)
                    .frame(height: 1)
            }
        }
        .background(GymupColors.overlay, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
