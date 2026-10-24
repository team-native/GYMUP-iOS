import SwiftUI

struct ProfilePlaylistSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProvider: String?

    private let providers = ["Apple Music", "Spotify"]

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.large) {
            HStack {
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text("루틴별 플레이리스트")
                        .font(GymupTypography.sectionTitle)
                        .foregroundStyle(GymupColors.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text("V2에서 연결할 음악 서비스를 미리 확인해요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

            ForEach(providers, id: \.self) { provider in
                providerButton(provider)
            }

            Text(selectionMessage)
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, GymupSpacing.large)
        .padding(.top, GymupSpacing.large)
        .padding(.bottom, GymupSpacing.xxLarge)
        .background(GymupColors.canvas)
    }

    private var selectionMessage: String {
        guard let selectedProvider else {
            return "서비스를 선택하면 이 화면에서 선택 상태만 표시됩니다."
        }
        return "\(selectedProvider)이(가) 미리보기에서 선택되었습니다. 계정 연결은 아직 제공하지 않습니다."
    }

    private func providerButton(_ provider: String) -> some View {
        let isSelected = selectedProvider == provider
        return Button {
            selectedProvider = provider
        } label: {
            HStack(spacing: GymupSpacing.medium) {
                Image(systemName: provider == "Apple Music" ? "apple.logo" : "music.note")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
                    .accessibilityHidden(true)
                Text(provider)
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(isSelected ? "선택됨" : "선택")
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(isSelected ? GymupColors.brandText : GymupColors.secondaryText)
            }
            .padding(GymupSpacing.medium)
            .frame(minHeight: 64)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: GymupRadius.medium)
                    .strokeBorder(isSelected ? GymupColors.accent : GymupColors.border, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(provider) 미리보기 선택")
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ProfilePlaylistSheetView()
        .preferredColorScheme(.dark)
}
