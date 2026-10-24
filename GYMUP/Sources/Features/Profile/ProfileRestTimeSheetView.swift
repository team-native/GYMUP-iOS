import SwiftUI

struct ProfileRestTimeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var selection: Int
    @State private var draftSelection: Int

    private let presets = [60, 90, 120, 180]
    private let wheelValues = Array(stride(from: 30, through: 300, by: 30))

    init(selection: Binding<Int>) {
        _selection = selection
        _draftSelection = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        VStack(spacing: GymupSpacing.medium) {
            HStack {
                Text("기본 휴식 시간")
                    .font(GymupTypography.sectionTitle)
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GymupColors.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("닫기")
            }

            Text("운동별 휴식 시간이 설정되지 않았을 때 적용돼요.")
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: GymupSpacing.small) {
                ForEach(presets, id: \.self) { value in
                    presetButton(value)
                }
            }

            Picker("휴식 시간", selection: $draftSelection) {
                ForEach(wheelValues, id: \.self) { value in
                    Text(timeLabel(value))
                        .font(GymupTypography.uiStrong)
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 112)
            .clipped()
            .accessibilityLabel("기본 휴식 시간 선택")

            Button {
                selection = draftSelection
                dismiss()
            } label: {
                Text("적용")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(GymupColors.accent, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            }
            .buttonStyle(.plain)
            .accessibilityHint("선택한 휴식 시간을 기본값으로 설정합니다")
        }
        .padding(.horizontal, GymupSpacing.large)
        .padding(.top, GymupSpacing.large)
        .padding(.bottom, GymupSpacing.medium)
        .background(GymupColors.canvas)
    }

    private func presetButton(_ value: Int) -> some View {
        let isSelected = draftSelection == value
        return Button {
            draftSelection = value
        } label: {
            Text(timeLabel(value))
                .font(GymupTypography.uiStrong)
                .foregroundStyle(isSelected ? GymupColors.primaryText : GymupColors.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(GymupColors.surface, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(isSelected ? GymupColors.accent : GymupColors.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("휴식 시간 \(timeLabel(value))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func timeLabel(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    ProfileRestTimeSheetView(selection: .constant(90))
        .preferredColorScheme(.dark)
}
