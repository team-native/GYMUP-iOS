import SwiftUI

struct ProfilePlaylistSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = WorkoutMusicPlaybackViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.large) {
            header
            providerPicker
            playlistContent
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("workout.music.error")
            }
            playbackButton
        }
        .padding(.horizontal, GymupSpacing.large)
        .padding(.top, GymupSpacing.large)
        .padding(.bottom, GymupSpacing.xxLarge)
        .background(GymupColors.canvas)
        .task { await viewModel.load(provider: viewModel.selectedProvider) }
        .onChange(of: viewModel.selectedProvider) { _, provider in
            Task { await viewModel.load(provider: provider) }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text("루틴별 플레이리스트")
                    .font(GymupTypography.sectionTitle)
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                Text("음악 서비스를 연결하고 운동 중 재생해요.")
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
    }

    private var providerPicker: some View {
        HStack(spacing: GymupSpacing.xSmall) {
            ForEach(PlaylistProvider.allCases) { provider in
                Button {
                    viewModel.selectedProvider = provider
                } label: {
                    Text(provider.displayName)
                        .font(GymupTypography.caption)
                        .foregroundStyle(
                            viewModel.selectedProvider == provider ? GymupColors.primaryText : GymupColors.secondaryText
                        )
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if viewModel.selectedProvider == provider {
                                RoundedRectangle(cornerRadius: GymupRadius.small)
                                    .fill(GymupColors.elevatedSurface)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(provider.displayName) 선택")
                .accessibilityValue(viewModel.selectedProvider == provider ? "선택됨" : "선택 안 됨")
                .accessibilityAddTraits(viewModel.selectedProvider == provider ? .isSelected : [])
            }
        }
        .padding(GymupSpacing.xSmall)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
    }

    @ViewBuilder
    private var playlistContent: some View {
        if viewModel.needsSpotifyConnection {
            VStack(alignment: .leading, spacing: GymupSpacing.medium) {
                Text("Spotify 계정을 연결하면 플레이리스트를 불러올 수 있어요.")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await viewModel.connectSpotify() }
                } label: {
                    HStack(spacing: GymupSpacing.small) {
                        if viewModel.isLoading { ProgressView().controlSize(.small).tint(.white) }
                        Text(viewModel.isLoading ? "Spotify 연결 중" : "Spotify 연결")
                            .font(GymupTypography.caption)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(GymupColors.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("workout.music.spotify.connect")
            }
        } else if viewModel.isLoading {
            HStack(spacing: GymupSpacing.small) {
                ProgressView().controlSize(.small).tint(GymupColors.accent)
                Text("플레이리스트를 불러오고 있어요.")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        } else if viewModel.items.isEmpty {
            VStack(alignment: .leading, spacing: GymupSpacing.small) {
                Text(viewModel.selectedProvider == .appleMusic
                     ? "Apple Music에서 플레이리스트를 찾지 못했어요."
                     : "Spotify에서 플레이리스트를 찾지 못했어요.")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                Button("다시 불러오기") {
                    Task { await viewModel.retry() }
                }
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.brandText)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.items) { item in
                        playlistRow(item)
                    }
                }
            }
            .frame(maxHeight: 180)
        }
    }

    private func playlistRow(_ item: PlaylistCatalogItem) -> some View {
        let selected = viewModel.selectedPlaylistID == item.playlistId
        return Button {
            viewModel.selectedPlaylistID = item.playlistId
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text(item.name)
                        .font(GymupTypography.callout)
                        .foregroundStyle(GymupColors.primaryText)
                    Text(item.provider.displayName)
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? GymupColors.brandText : GymupColors.secondaryText)
            }
            .padding(.vertical, GymupSpacing.medium)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(GymupColors.separator).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .accessibilityValue(selected ? "선택됨" : "선택 안 됨")
    }

    private var playbackButton: some View {
        Button {
            Task { await viewModel.togglePlayback() }
        } label: {
            HStack(spacing: GymupSpacing.small) {
                if viewModel.isLoading {
                    ProgressView().controlSize(.small).tint(.white)
                } else {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                }
                Text(viewModel.isLoading ? "연결 중" : (viewModel.isPlaying ? "일시 정지" : "재생"))
                    .font(GymupTypography.uiBold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(GymupColors.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading || viewModel.needsSpotifyConnection || viewModel.items.isEmpty)
        .accessibilityIdentifier("workout.music.playback")
    }
}

#Preview {
    ProfilePlaylistSheetView()
        .preferredColorScheme(.dark)
}
