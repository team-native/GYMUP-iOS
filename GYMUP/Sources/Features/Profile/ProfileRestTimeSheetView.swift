import SwiftUI
import Observation

struct ProfileRestTimeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding private var selection: Int
    @State private var viewModel: ProfileRestTimeViewModel
    @State private var draftSelection: Int

    private let presets = [60, 90, 120, 180]
    private let wheelValues = Array(stride(from: 15, through: 300, by: 15))

    init(selection: Binding<Int>, viewModel: ProfileRestTimeViewModel) {
        _selection = selection
        _viewModel = State(initialValue: viewModel)
        _draftSelection = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                titleRow
                    .padding(.top, 30)
                helperText
                    .padding(.top, 26)
                restTimePicker
                    .padding(.top, 24)
                presetOptions
                    .padding(.top, 32)
                saveButton
                    .padding(.top, 17)
                saveFeedback
                    .padding(.top, viewModel.errorMessage == nil ? 0 : 12)
                    .padding(.bottom, 31)
            }
            .padding(.horizontal, GymupSpacing.large)
        }
        .background(ProfileRestTimeSheetStyle.surface.ignoresSafeArea())
        .interactiveDismissDisabled(viewModel.isSaving)
        .onAppear { draftSelection = selection }
    }

    private var titleRow: some View {
        Text("기본 휴식 시간")
            .font(.custom("GothicA1-Bold", size: 18, relativeTo: .headline))
            .foregroundStyle(GymupColors.primaryText)
            .accessibilityAddTraits(.isHeader)
    }

    private var helperText: some View {
        Text("운동별 휴식 시간이 없을 때 자동 적용돼요.")
            .font(.custom("NotoSansKR-Regular", size: 14, relativeTo: .callout))
            .foregroundStyle(ProfileOverviewColors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var restTimePicker: some View {
        ZStack {
            RoundedRectangle(cornerRadius: GymupRadius.medium)
                .fill(ProfileOverviewColors.canvas)

            RoundedRectangle(cornerRadius: GymupRadius.small)
                .fill(ProfileRestTimeSheetStyle.surface)
                .frame(height: 52)
                .padding(.horizontal, GymupSpacing.small)

            Picker("휴식 시간", selection: $draftSelection) {
                ForEach(wheelValues, id: \.self) { value in
                    Text(timeLabel(value))
                        .font(value == draftSelection ? ProfileRestTimeSheetStyle.selectedWheelFont : GymupTypography.number)
                        .foregroundStyle(value == draftSelection ? GymupColors.brandText : GymupColors.primaryText)
                        .accessibilityLabel(spokenLabel(for: value))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .tint(GymupColors.brandText)
            .disabled(viewModel.isSaving)
        }
        .frame(height: dynamicTypeSize.isAccessibilitySize ? 160 : 147)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: GymupRadius.medium))
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
            Task {
                let didSave = await viewModel.save(seconds: draftSelection) { seconds in
                    selection = seconds
                }
                if didSave {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                        .accessibilityHidden(true)
                }
                Text(viewModel.isSaving ? "저장 중..." : "저장")
                    .font(GymupTypography.uiBold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(ProfileOverviewColors.brandPrimary, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .accessibilityLabel("휴식 시간 저장")
        .accessibilityHint("선택한 휴식 시간을 저장합니다. 서버 저장이 실패하면 다시 시도할 수 있습니다")
    }

    @ViewBuilder
    private var saveFeedback: some View {
        if let errorMessage = viewModel.errorMessage {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(errorMessage)
                        .font(GymupTypography.uiMedium)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .accessibilityHidden(true)
                }
                .foregroundStyle(GymupColors.accent)
                .accessibilityIdentifier("profile.restTime.saveError")

                if viewModel.canRetry, let retrySeconds = viewModel.retrySeconds {
                    Button {
                        draftSelection = retrySeconds
                        selection = retrySeconds
                        Task {
                            if await viewModel.retry() {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(GymupColors.brandText)
                                    .accessibilityHidden(true)
                            }
                            Text("다시 시도")
                                .font(GymupTypography.uiBold)
                        }
                        .foregroundStyle(GymupColors.brandText)
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSaving)
                    .accessibilityLabel("\(spokenLabel(for: retrySeconds)) 설정 다시 시도")
                    .accessibilityHint("서버에 같은 휴식 시간을 다시 저장합니다")
                    .accessibilityIdentifier("profile.restTime.retrySave")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func presetButton(_ value: Int) -> some View {
        let isSelected = draftSelection == value
        return Button {
            draftSelection = value
        } label: {
            Text(timeLabel(value))
                .font(GymupTypography.uiMedium)
                .foregroundStyle(GymupColors.primaryText)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? ProfileOverviewColors.brandPrimary : ProfileRestTimeSheetStyle.surface,
                    in: Capsule()
                )
                .overlay {
                    if !isSelected {
                        Capsule().strokeBorder(GymupColors.strongBorder, lineWidth: 1)
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .accessibilityLabel("휴식 시간 \(spokenLabel(for: value))")
        .accessibilityHint("선택하면 휠의 휴식 시간도 바뀝니다")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

private enum ProfileRestTimeSheetStyle {
    // Figma's S section uses #1F1F21. The sheet child fill is not exposed in the read-only inspector;
    // this local surface value is selected to match the visible sheet surface.
    static let surface = Color(red: 31.0 / 255, green: 31.0 / 255, blue: 33.0 / 255)
    static let selectedWheelFont = Font.custom("BarlowCondensed-ExtraBold", size: 22, relativeTo: .title3)
}

#Preview {
    ProfileRestTimeSheetView(
        selection: .constant(90),
        viewModel: ProfileRestTimeViewModel(service: nil)
    )
        .preferredColorScheme(.dark)
}

protocol ProfileRestTimeUpdating {
    func updateDefaultRestTime(seconds: Int) async throws -> UpdateDefaultRestTimeResponse
}

extension UserSettingsAPIService: ProfileRestTimeUpdating {}

@Observable
@MainActor
final class ProfileRestTimeViewModel {
    private let service: ProfileRestTimeUpdating?

    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var retrySeconds: Int?

    init(service: ProfileRestTimeUpdating?) {
        self.service = service
    }

    var canRetry: Bool { retrySeconds != nil }

    func save(seconds: Int, persistLocally: (Int) -> Void) async -> Bool {
        guard !isSaving else { return false }
        persistLocally(seconds)
        errorMessage = nil
        retrySeconds = nil

        guard let service else {
            return true
        }

        return await submit(seconds: seconds, using: service)
    }

    func retry() async -> Bool {
        guard !isSaving,
              let service,
              let retrySeconds
        else {
            return false
        }

        return await submit(seconds: retrySeconds, using: service)
    }

    private func submit(seconds: Int, using service: ProfileRestTimeUpdating) async -> Bool {
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await service.updateDefaultRestTime(seconds: seconds)
            errorMessage = nil
            retrySeconds = nil
            return true
        } catch {
            if case let APIClientError.server(_, detail) = error {
                errorMessage = detail.message
            } else {
                errorMessage = "서버 저장에 실패했어요. 로컬 설정은 저장됐어요."
            }
            retrySeconds = seconds
            return false
        }
    }
}
