import SwiftUI

struct OnboardingFrequencyView: View {
    @Binding var draft: OnboardingDraft
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        OnboardingStepLayout(step: 3, title: "일주일에 몇 번\n운동할 계획인가요?", onBack: onBack, onNext: onNext) {
            HStack {
                control("minus", label: "횟수 줄이기", disabled: draft.frequency <= 1) { draft.adjustFrequency(by: -1) }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(draft.frequency)").font(GymupTypography.score).foregroundStyle(GymupColors.primaryText)
                    Text("회 / 주").font(GymupTypography.uiStrong).foregroundStyle(GymupColors.secondaryText)
                }.accessibilityElement(children: .combine)
                Spacer()
                control("plus", label: "횟수 늘리기", disabled: draft.frequency >= 7) { draft.adjustFrequency(by: 1) }
            }.padding(.top, 36)
            HStack(spacing: 4) {
                ForEach(0..<7) { index in
                    Capsule().fill(index < draft.frequency ? GymupColors.accent : GymupColors.overlay).frame(height: 4)
                }
            }
            Text("입문자는 주 3회를 추천해요. 쉬는 날은 Streak 실패가 아니에요.")
                .font(GymupTypography.uiMedium).foregroundStyle(GymupColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func control(_ symbol: String, label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).foregroundStyle(GymupColors.primaryText).frame(width: 46, height: 46)
                .background(GymupColors.elevatedSurface, in: Circle())
        }.disabled(disabled).accessibilityLabel(label)
    }
}
