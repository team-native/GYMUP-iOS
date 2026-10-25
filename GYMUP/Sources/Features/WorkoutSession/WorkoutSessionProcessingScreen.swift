import SwiftUI

struct WorkoutSessionProcessingScreen: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                Image("H1Equipment")
                    .resizable()
                    .frame(width: 300, height: 150)
                    .accessibilityHidden(true)

                Text("기록을 정리하는 중")
                    .font(GymupTypography.homeTitle)
                    .tracking(-0.43)
                    .foregroundStyle(GymupColors.primaryText)

                Text("볼륨 · PR · Growth를 계산하고 있어요")
                    .font(GymupTypography.uiMedium)
                    .tracking(-0.09)
                    .foregroundStyle(GymupColors.secondaryText)

                GeometryReader { progressGeometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(GymupColors.overlay)
                        Capsule()
                            .fill(GymupColors.accent)
                            .frame(width: progressGeometry.size.width * progress)
                    }
                }
                .frame(width: 200, height: 4)
                .accessibilityLabel("운동 기록 정리 진행")
                .accessibilityValue("\(Int(progress * 100))퍼센트")
                .accessibilityIdentifier("workout.processing.progress")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, max(0, 280 - geometry.safeAreaInsets.top))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(GymupColors.canvas.ignoresSafeArea())
        }
        .onAppear {
            withAnimation(.linear(duration: 1.8)) {
                progress = 1
            }
        }
        .accessibilityIdentifier("workout.processing")
    }
}
