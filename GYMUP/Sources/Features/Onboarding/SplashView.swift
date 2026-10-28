import SwiftUI

struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 18) {
                Image("O1Equipment")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 110)
                    .accessibilityHidden(true)
                Text("GYMUP")
                    .font(.custom("BarlowCondensed-Black", size: 40))
                    .tracking(-0.28)
                    .foregroundStyle(GymupColors.primaryText)
                Capsule()
                    .fill(GymupColors.accent)
                    .frame(width: 32, height: 4)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.46)
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("짐업")
    }
}
