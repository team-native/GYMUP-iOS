import SwiftUI

struct WorkoutExitConfirmationDialog: View {
    let completedExerciseCount: Int
    let completedSetCount: Int
    let onFinish: () -> Void
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backdrop

                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                dialog
                    .frame(width: min(270, geometry.size.width - 48))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .accessibilityIdentifier("workout.exit-dialog")
    }

    private var backdrop: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Image("H1RoutinePhoto")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: 280)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [.clear, GymupColors.canvas],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 160)
                    }

                GymupColors.canvas
            }
            .ignoresSafeArea()
        }
    }

    private var dialog: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("운동을 종료할까요?")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(GymupColors.primaryText)

                Text(summaryText)
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)

            dialogButton("종료하고 저장", style: .finish, action: onFinish)
            dialogButton("계속하기", style: .continue, action: onContinue)
        }
        .background(GymupColors.overlay, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var summaryText: String {
        "지금까지 기록한 \(completedExerciseCount)개 운동 · \(completedSetCount)세트가 저장되고 결과 화면으로 이동해요."
    }

    private func dialogButton(_ title: String, style: ButtonStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(style == .finish ? GymupTypography.uiBold : GymupTypography.uiMedium)
                .foregroundStyle(style == .finish ? GymupColors.brandText : GymupColors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .overlay(alignment: .top) {
                    Rectangle().fill(GymupColors.strongBorder).frame(height: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(style == .finish ? "workout.exit-dialog.finish" : "workout.exit-dialog.continue")
    }

    private enum ButtonStyle {
        case finish
        case `continue`
    }
}
