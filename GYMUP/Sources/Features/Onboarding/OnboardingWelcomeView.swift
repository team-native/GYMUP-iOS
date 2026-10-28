import SwiftUI

struct OnboardingWelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image("O2Hero").resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                LinearGradient(colors: [.black.opacity(0.2), GymupColors.canvas.opacity(0.96)],
                               startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 0) {
                    Text("GYMUP").font(.custom("BarlowCondensed-ExtraBold", size: 18))
                    Spacer()
                    Text("TRAIN TO GROW").font(GymupTypography.label).padding(.horizontal, 12)
                        .padding(.vertical, 6).background(GymupColors.accent, in: Capsule())
                    Text("운동할수록\n기록이 무거워진다")
                        .font(GymupTypography.homeTitle).padding(.top, 19)
                    Text("운동을 마칠 때마다 Growth가 쌓이고,\n빈 바벨에 원판이 하나씩 올라가요.")
                        .font(GymupTypography.uiStrong).foregroundStyle(GymupColors.secondaryText)
                        .padding(.top, 19)
                    Spacer().frame(height: max(30, geometry.size.height * 0.17))
                    OnboardingActionButton(title: "시작하기", action: onNext).padding(.horizontal, 16)
                }
                .foregroundStyle(GymupColors.primaryText).padding(.horizontal, 20).padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
    }
}

struct OnboardingActionButton: View {
    let title: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(GymupTypography.sectionTitle).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(GymupColors.accent, in: Capsule())
        }
        .disabled(disabled).opacity(disabled ? 0.45 : 1)
    }
}
