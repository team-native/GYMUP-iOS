import SwiftUI

struct WorkoutSessionWeightInputSheet: View {
    let setNumber: Int
    let initialWeight: Double
    let onConfirm: (Double) -> Void

    @State private var inputValue: String
    @State private var hasEdited = false

    init(setNumber: Int, initialWeight: Double, onConfirm: @escaping (Double) -> Void) {
        self.setNumber = setNumber
        self.initialWeight = initialWeight
        self.onConfirm = onConfirm
        _inputValue = State(initialValue: Self.formatted(initialWeight))
    }

    private let quickAdjustments: [Double] = [-2.5, 2.5, 5, 10]
    private let keypadRows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [".", "0", "delete"]]

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(GymupColors.overlay)
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            valueHeading
                .padding(.top, 19)

            quickAdjustmentRow
                .padding(.top, 15)

            keypad
                .padding(.top, 14)

            confirmButton
                .padding(.top, 12)

            Spacer(minLength: 96)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(GymupColors.surface)
        .accessibilityIdentifier("workout.weight-input.sheet")
    }

    private var valueHeading: some View {
        HStack(alignment: .lastTextBaseline) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(inputValue.isEmpty ? "0" : inputValue)
                    .font(.custom("BarlowCondensed-Black", size: 40))
                    .tracking(-0.28)
                    .foregroundStyle(GymupColors.primaryText)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("workout.weight-input.value")
                Text("KG")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            Spacer()
            Text("SET \(setNumber) · 무게")
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
        }
    }

    private var quickAdjustmentRow: some View {
        HStack(spacing: 8) {
            ForEach(quickAdjustments, id: \.self) { adjustment in
                Button {
                    applyQuickAdjustment(adjustment)
                } label: {
                    Text(adjustment.formatted(.number.sign(strategy: .always()).precision(.fractionLength(0...1))))
                        .font(GymupTypography.uiMedium)
                        .foregroundStyle(GymupColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .overlay(Capsule().strokeBorder(GymupColors.strongBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workout.weight-input.quick.\(adjustment)")
            }
        }
    }

    private var keypad: some View {
        VStack(spacing: 8) {
            ForEach(Array(keypadRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(key)
                    }
                }
            }
        }
    }

    private var confirmButton: some View {
        Button {
            guard let weight = Double(inputValue), weight <= 999 else { return }
            onConfirm(weight)
        } label: {
            Text("확인")
                .font(GymupTypography.uiBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(GymupColors.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(Double(inputValue) == nil || (Double(inputValue) ?? 1_000) > 999)
        .opacity(Double(inputValue) == nil || (Double(inputValue) ?? 1_000) > 999 ? 0.55 : 1)
        .accessibilityIdentifier("workout.weight-input.confirm")
    }

    private func keypadButton(_ key: String) -> some View {
        Button {
            if key == "delete" {
                deleteLastCharacter()
            } else {
                append(key)
            }
        } label: {
            Group {
                if key == "delete" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 16, weight: .medium))
                } else {
                    Text(key)
                        .font(.custom("BarlowCondensed-ExtraBold", size: 18))
                }
            }
            .foregroundStyle(GymupColors.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(key == "delete" ? "마지막 숫자 지우기" : key)
        .accessibilityIdentifier("workout.weight-input.key.\(key)")
    }

    private func append(_ character: String) {
        if !hasEdited {
            inputValue = character == "." ? "0." : character
            hasEdited = true
            return
        }
        guard inputValue.count < 6 else { return }
        if character == "." {
            guard !inputValue.contains(".") else { return }
            inputValue = inputValue.isEmpty ? "0." : inputValue + character
            return
        }
        if let decimalPart = inputValue.split(separator: ".", omittingEmptySubsequences: false).dropFirst().first,
           decimalPart.count >= 1 {
            return
        }
        inputValue += character
    }

    private func deleteLastCharacter() {
        hasEdited = true
        guard !inputValue.isEmpty else { return }
        inputValue.removeLast()
    }

    private func applyQuickAdjustment(_ adjustment: Double) {
        let currentValue = Double(inputValue) ?? initialWeight
        inputValue = Self.formatted(min(max(currentValue + adjustment, 0), 999))
        hasEdited = true
    }

    private static func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
