import SwiftUI

struct OnboardingPurposeView: View {
    @Binding var selection: Set<String>
    let onBack: () -> Void
    let onNext: () -> Void
    private let rows = [["근비대", "근력 향상", "체지방 감량", "체력 · 건강"], ["자세 교정", "바디프로필", "스트레스 해소"]]

    var body: some View {
        OnboardingStepLayout(step: 2, title: "무엇을 위해\n운동하나요?", onBack: onBack, onNext: onNext, disabled: selection.isEmpty) {
            Text("최대 2개까지 고를 수 있어요").font(GymupTypography.uiMedium).foregroundStyle(GymupColors.secondaryText)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { item in
                            Button {
                                if selection.contains(item) {
                                    selection.remove(item)
                                } else if selection.count < 2 {
                                    selection.insert(item)
                                }
                            } label: {
                                Text(item).font(GymupTypography.uiMedium).foregroundStyle(GymupColors.primaryText)
                                    .padding(.horizontal, 11).padding(.vertical, 7)
                                    .background(selection.contains(item) ? GymupColors.accent : .clear, in: Capsule())
                                    .overlay(Capsule().stroke(selection.contains(item) ? .clear : GymupColors.strongBorder))
                            }.buttonStyle(.plain).accessibilityAddTraits(selection.contains(item) ? .isSelected : [])
                        }
                    }
                }
            }
        }
    }
}
