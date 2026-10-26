import SwiftUI

struct ProfileRestTimeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding private var selection: Int
    @State private var draftSelection: Int

    private let presets = [60, 90, 120, 180]
    private let wheelValues = Array(stride(from: 15, through: 300, by: 15))

    init(selection: Binding<Int>) {
        _selection = selection
        _draftSelection = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.medium) {
                titleRow
                helperText
                restTimePicker
                presetOptions
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.large)
            .padding(.bottom, GymupSpacing.medium)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveButton
                .padding(.horizontal, GymupSpacing.large)
                .padding(.top, GymupSpacing.small)
                .padding(.bottom, GymupSpacing.medium)
                .background(GymupColors.canvas)
        }
        .background(GymupColors.canvas)
        .onAppear { draftSelection = selection }
    }

    private var titleRow: some View {
        HStack {
            Text("기본 휴식 시간")
                .font(ProfileTypography.rowTitle)
                .foregroundStyle(GymupColors.primaryText)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: cancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("취소")
            .accessibilityHint("선택한 휴식 시간을 저장하지 않고 닫습니다")
        }
    }

    private var helperText: some View {
        Text("운동별 휴식 시간이 없을 때 자동 적용돼요.")
            .font(ProfileTypography.caption)
            .foregroundStyle(GymupColors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var restTimePicker: some View {
        Picker("휴식 시간", selection: $draftSelection) {
            ForEach(wheelValues, id: \.self) { value in
                Text(timeLabel(value))
                    .font(ProfileTypography.rowTitle)
                    .accessibilityLabel(spokenLabel(for: value))
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: dynamicTypeSize.isAccessibilitySize ? 160 : 112)
        .clipped()
        .accessibilityLabel("기본 휴식 시간 선택")
        .accessibilityValue(spokenLabel(for: draftSelection))
    }

    @ViewBuilder
    private var presetOptions: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: GymupSpacing.small) {
                ForEach(presets, id: \.self) { value in
                    presetButton(value)
                }
            }
        } else {
            HStack(spacing: GymupSpacing.small) {
                ForEach(presets, id: \.self) { value in
                    presetButton(value)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            selection = draftSelection
            dismiss()
        } label: {
            Text("저장")
                .font(ProfileTypography.action)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(GymupColors.accent, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
                .contentShape(RoundedRectangle(cornerRadius: GymupRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("휴식 시간 저장")
        .accessibilityHint("선택한 휴식 시간을 저장하고 닫습니다")
    }

    private func presetButton(_ value: Int) -> some View {
        let isSelected = draftSelection == value
        return Button {
            draftSelection = value
        } label: {
            Text(timeLabel(value))
                .font(ProfileTypography.action)
                .foregroundStyle(isSelected ? .white : GymupColors.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isSelected ? GymupColors.accent : GymupColors.surface, in: Capsule())
                .overlay {
                    if !isSelected {
                        Capsule().strokeBorder(GymupColors.border, lineWidth: 1)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("휴식 시간 \(spokenLabel(for: value))")
        .accessibilityHint("선택하면 휠의 휴식 시간도 바뀝니다")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func cancel() {
        draftSelection = selection
        dismiss()
    }

    private func timeLabel(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func spokenLabel(for seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        guard minutes > 0 else { return "\(remainingSeconds)초" }
        guard remainingSeconds > 0 else { return "\(minutes)분" }
        return "\(minutes)분 \(remainingSeconds)초"
    }
}

#Preview {
    ProfileRestTimeSheetView(selection: .constant(90))
        .preferredColorScheme(.dark)
}
