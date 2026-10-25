import SwiftUI

struct RoutineEmptyStartAlert: View {
    let onClose: () -> Void
    let onAddExercise: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            dialog
                .frame(width: 270)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .accessibilityIdentifier("routine.empty-start.alert")
    }

    private var dialog: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("운동이 없는 루틴이에요")
                    .font(.custom("GothicA1-Bold", size: 17))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(maxWidth: .infinity)
                Text("운동을 1개 이상 추가해야 시작할 수 있어요.")
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
                Button(action: onClose) {
                    Text("닫기")
                        .font(.custom("GothicA1-Regular", size: 17))
                        .foregroundStyle(GymupColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("routine.empty-start.close")

                Rectangle()
                    .fill(GymupColors.strongBorder)
                    .frame(width: 1, height: 44)

                Button(action: onAddExercise) {
                    Text("운동 추가")
                        .font(.custom("GothicA1-Bold", size: 17))
                        .foregroundStyle(GymupColors.brandText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("routine.empty-start.add-exercise")
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
