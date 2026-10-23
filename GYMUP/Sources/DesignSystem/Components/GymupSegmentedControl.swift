import SwiftUI

struct GymupSegmentedControl<Selection>: View
where Selection: CaseIterable & Hashable & RawRepresentable, Selection.RawValue == String {
    @Binding var selection: Selection
    @Namespace private var selectionAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Selection.allCases), id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = option }
                } label: {
                    Text(option.rawValue)
                        .font(selection == option ? GymupTypography.uiSemibold : GymupTypography.uiMedium)
                        .foregroundStyle(selection == option ? GymupColors.primaryText : GymupColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(GymupColors.overlay)
                                    .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                                    .matchedGeometryEffect(id: "selection", in: selectionAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option ? .isSelected : [])
            }
        }
        .padding(2)
        .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 9))
    }
}
