import SwiftUI

struct OnboardingGoalView: View {
    @Binding var goal: Int
    @Binding var weeks: Int
    let frequency: Int
    let onBack: () -> Void
    let onNext: () -> Void
    private let choices = [("체형", "PHYSIQUE", "O6Physique"), ("근력", "STRENGTH", "O6Strength"), ("꾸준함", "HABIT", "O6Habit")]

    var body: some View {
        OnboardingStepLayout(step: 4, title: "어떤 목표로\n바벨을 채울까요?", onBack: onBack, onNext: onNext, nextTitle: "목표 시작하기") {
            HStack(alignment: .top, spacing: 8) {
                ForEach(choices.indices, id: \.self) { index in
                    Button { goal = index } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Image(choices[index].2).resizable().scaledToFill().frame(maxWidth: .infinity)
                                .frame(height: 128).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(goal == index ? GymupColors.accent : .clear, lineWidth: 2))
                                .overlay(alignment: .topTrailing) {
                                    if goal == index {
                                        Image("OCheck").resizable().frame(width: 14, height: 14).padding(5)
                                            .background(GymupColors.accent, in: Circle()).padding(5)
                                    }
                                }
                            Text(choices[index].0).font(GymupTypography.uiStrong).foregroundStyle(GymupColors.primaryText)
                            Text(choices[index].1).font(GymupTypography.label).foregroundStyle(GymupColors.secondaryText)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain).accessibilityAddTraits(goal == index ? .isSelected : [])
                }
            }
            Text("목표 기간").font(GymupTypography.uiStrong).foregroundStyle(GymupColors.primaryText).padding(.top, 4)
            HStack(spacing: 0) {
                ForEach([4, 8, 12, 16], id: \.self) { value in
                    Button { weeks = value } label: {
                        Text("\(value)주").font(GymupTypography.uiMedium)
                            .foregroundStyle(value == weeks ? GymupColors.primaryText : GymupColors.secondaryText)
                            .frame(maxWidth: .infinity).frame(height: 34)
                            .background(value == weeks ? GymupColors.overlay : .clear, in: RoundedRectangle(cornerRadius: 8))
                    }.accessibilityAddTraits(value == weeks ? .isSelected : [])
                }
            }.background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 9))
            HStack(spacing: 12) {
                Image("OTarget").resizable().frame(width: 18, height: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(weeks)주 · 주 \(frequency)회 · 총 \(weeks * frequency)회")
                        .font(GymupTypography.uiStrong).foregroundStyle(GymupColors.primaryText)
                    Text("Growth 0 / 100에서 시작해요").font(GymupTypography.uiCaption).foregroundStyle(GymupColors.secondaryText)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
