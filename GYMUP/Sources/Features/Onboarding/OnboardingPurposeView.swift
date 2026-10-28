import SwiftUI

struct OnboardingPurposeView: View {
    @Binding var selection: Set<String>
    let onBack: () -> Void
    let onNext: () -> Void
    private let options = ["근비대", "근력 향상", "체지방 감량", "체력 · 건강", "자세 교정", "바디프로필", "스트레스 해소"]

    var body: some View {
        OnboardingStepLayout(step: 2, title: "무엇을 위해\n운동하나요?", onBack: onBack, onNext: onNext, disabled: selection.isEmpty) {
            Text("최대 2개까지 고를 수 있어요").font(GymupTypography.uiMedium).foregroundStyle(GymupColors.secondaryText)
            OnboardingChipLayout {
                ForEach(options, id: \.self) { item in
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

private struct OnboardingChipLayout: Layout {
    private let horizontalSpacing: CGFloat = 8
    private let verticalSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 353
        let positions = layout(subviews: subviews, width: width)
        return CGSize(width: width, height: positions.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let positions = layout(subviews: subviews, width: bounds.width)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + positions.points[index].x,
                                      y: bounds.minY + positions.points[index].y), proposal: .unspecified)
        }
    }

    private func layout(subviews: Subviews, width: CGFloat) -> (points: [CGPoint], height: CGFloat) {
        var points: [CGPoint] = []
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if offsetX > 0 && offsetX + size.width > width {
                offsetX = 0
                offsetY += rowHeight + verticalSpacing
                rowHeight = 0
            }
            points.append(CGPoint(x: offsetX, y: offsetY))
            offsetX += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        return (points, offsetY + rowHeight)
    }
}
