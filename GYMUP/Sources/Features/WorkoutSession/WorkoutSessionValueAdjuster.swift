import SwiftUI

struct WorkoutSessionValueAdjuster: View {
    let title: String
    let value: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    var onValueTap: (() -> Void)?

    init(
        title: String,
        value: String,
        onDecrease: @escaping () -> Void,
        onIncrease: @escaping () -> Void,
        onValueTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.onDecrease = onDecrease
        self.onIncrease = onIncrease
        self.onValueTap = onValueTap
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(GymupTypography.label)
                .tracking(0.16)
                .foregroundStyle(GymupColors.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(spacing: 10) {
                adjustmentButton(symbol: "minus", action: onDecrease)
                if let onValueTap {
                    Button(action: onValueTap) { valueLabel }
                        .buttonStyle(.plain)
                        .accessibilityLabel("값 직접 입력, \(value)")
                        .accessibilityIdentifier("workout.value-adjuster.input")
                } else {
                    valueLabel
                }
                adjustmentButton(symbol: "plus", action: onIncrease)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var valueLabel: some View {
        Text(value)
            .font(.custom("BarlowCondensed-ExtraBold", size: 26))
            .foregroundStyle(GymupColors.primaryText)
            .contentTransition(.numericText())
            .frame(minWidth: 34)
    }

    private func adjustmentButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GymupColors.primaryText)
                .frame(width: 34, height: 34)
                .background(GymupColors.elevatedSurface, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "plus" ? "증가" : "감소")
    }
}
