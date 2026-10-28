import SwiftUI

struct OnboardingGoalCreatedView: View {
    let frequency: Int
    let weeks: Int
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("GOAL CREATED").font(GymupTypography.label).foregroundStyle(GymupColors.brandText)
            Text("빈 바벨에서\n시작해요").font(GymupTypography.homeTitle).multilineTextAlignment(.center)
            Spacer(minLength: 20)
            Image("O7Equipment").resizable().scaledToFit().frame(maxWidth: 320).frame(height: 160).accessibilityHidden(true)
            Text("EMPTY BAR · 20 KG").font(GymupTypography.label).foregroundStyle(GymupColors.secondaryText)
            Spacer(minLength: 20)
            HStack {
                metric("0/100", "GROWTH")
                metric("0/\(frequency)", "이번 주")
                metric("\(weeks)주", "목표 기간")
            }
            Text("운동을 마칠 때마다 원판이 하나씩 올라가요.")
                .font(GymupTypography.uiMedium).foregroundStyle(GymupColors.secondaryText).padding(.top, 20)
            Spacer(minLength: 20)
            OnboardingActionButton(title: "다음", action: onNext).padding(.horizontal, 16).padding(.bottom, 16)
        }.foregroundStyle(GymupColors.primaryText).padding(.horizontal, 20).padding(.top, 80)
            .frame(maxWidth: .infinity).background(GymupColors.canvas.ignoresSafeArea())
    }

    private func metric(_ value: String, _ title: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(GymupTypography.metric)
            Text(title).font(GymupTypography.uiCaption).foregroundStyle(GymupColors.secondaryText)
        }.frame(maxWidth: .infinity)
    }
}
