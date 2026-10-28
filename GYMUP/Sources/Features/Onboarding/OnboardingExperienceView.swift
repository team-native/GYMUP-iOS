import SwiftUI

struct OnboardingStepLayout<Content: View>: View {
    let step: Int
    let title: String
    let onBack: () -> Void
    let onNext: () -> Void
    var nextTitle = "다음"
    var disabled = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onBack) {
                Image("OBack").resizable().frame(width: 24, height: 24).frame(width: 44, height: 44)
            }.accessibilityLabel("뒤로")
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Capsule().fill(index < step ? GymupColors.accent : GymupColors.overlay).frame(height: 3)
                }
            }.padding(.top, 4)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("STEP \(step) / 4").font(GymupTypography.label).foregroundStyle(GymupColors.brandText)
                    Text(title).font(GymupTypography.homeTitle).foregroundStyle(GymupColors.primaryText)
                    content
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)
            }
            OnboardingActionButton(title: nextTitle, disabled: disabled, action: onNext)
                .padding(.horizontal, 16).padding(.bottom, 16)
        }.padding(.horizontal, 20).background(GymupColors.canvas.ignoresSafeArea())
    }
}

struct OnboardingExperienceView: View {
    @Binding var selection: Int?
    let onBack: () -> Void
    let onNext: () -> Void
    private let options = [
        ("처음이에요", "헬스장 기구가 아직 낯설어요"), ("입문", "6개월 미만 · 기본 동작은 알아요"),
        ("중급", "6개월 ~ 2년 · 분할 루틴 경험"), ("숙련", "2년 이상 · 스스로 프로그램 구성")
    ]

    var body: some View {
        OnboardingStepLayout(step: 1, title: "운동 경험이\n어느 정도인가요?", onBack: onBack, onNext: onNext, disabled: selection == nil) {
            VStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { index in
                    Button { selection = index } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(options[index].0).font(GymupTypography.uiStrong).foregroundStyle(GymupColors.primaryText)
                                Text(options[index].1).font(GymupTypography.uiCaption).foregroundStyle(GymupColors.secondaryText)
                            }
                            Spacer()
                            if selection == index {
                                Image("OCheck").resizable().frame(width: 14, height: 14).frame(width: 24, height: 24)
                                    .background(GymupColors.accent, in: Circle())
                            } else {
                                Circle().stroke(GymupColors.strongBorder, lineWidth: 1.5).frame(width: 24, height: 24)
                            }
                        }.padding(.horizontal, 16).padding(.vertical, 18)
                            .background(selection == index ? GymupColors.canvas : GymupColors.surface,
                                        in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(selection == index ? GymupColors.accent : .clear, lineWidth: 1.5))
                    }.buttonStyle(.plain).accessibilityAddTraits(selection == index ? .isSelected : [])
                }
            }.padding(.top, 12)
        }
    }
}
