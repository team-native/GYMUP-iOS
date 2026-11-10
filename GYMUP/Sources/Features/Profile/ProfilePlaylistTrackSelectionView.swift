import SwiftUI

struct ProfilePlaylistTrackSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PlaylistCatalogViewModel()
    @State private var selectedPlaylist: PlaylistCatalogItem?
    @State private var isSaving = false
    @State private var saveErrorMessage: String?

    private let presentation: PlaylistTrackSelectionPresentation
    private let onSave: (PlaylistCatalogItem) async throws -> Void

    init(
        presentation: PlaylistTrackSelectionPresentation,
        onSave: @escaping (PlaylistCatalogItem) async throws -> Void
    ) {
        self.presentation = presentation
        self.onSave = onSave
        if let current = presentation.currentPlaylist {
            _selectedPlaylist = State(initialValue: PlaylistCatalogItem(
                provider: current.provider,
                playlistId: current.playlistId,
                name: current.playlistName,
                externalUrl: current.externalUrl
            ))
        } else {
            _selectedPlaylist = State(initialValue: nil)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ProfilePlaylistNavigationBar(title: presentation.routineTitle, onBack: dismiss.callAsFunction)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GymupSpacing.large) {
                    providerHeader
                    catalogContent
                }
                .padding(.horizontal, GymupSpacing.large)
                .padding(.top, GymupSpacing.small)
                .padding(.bottom, GymupSpacing.large)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .task { await viewModel.load(provider: presentation.provider) }
    }

    private var providerHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: GymupSpacing.small) {
            Text(presentation.provider.displayName)
                .font(GymupTypography.headline)
                .foregroundStyle(GymupColors.primaryText)
            Text("플레이리스트 선택")
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
            Spacer(minLength: 0)
            if presentation.provider == .spotify, viewModel.isSpotifyConnected {
                Button("연결 해제") {
                    Task { await viewModel.disconnectSpotify() }
                }
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .disabled(isSaving || viewModel.isLoading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var catalogContent: some View {
        if viewModel.needsSpotifyConnection {
            VStack(alignment: .leading, spacing: GymupSpacing.medium) {
                Text("Spotify 계정을 연결하면 플레이리스트를 읽어와요.")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await viewModel.connectSpotify() }
                } label: {
                    HStack(spacing: GymupSpacing.small) {
                        if viewModel.isLoading { ProgressView().controlSize(.small).tint(.white) }
                        Text(viewModel.isLoading ? "Spotify 연결 중" : "Spotify 연결")
                            .font(ProfileTypography.action)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(GymupColors.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("playlist.spotify.connect")
                if let errorMessage = viewModel.errorMessage {
                    errorMessageView(errorMessage)
                }
            }
        } else if viewModel.isLoading {
            HStack(spacing: GymupSpacing.small) {
                ProgressView().controlSize(.small).tint(GymupColors.accent)
                Text("플레이리스트를 불러오고 있어요.")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        } else if let errorMessage = viewModel.errorMessage {
            VStack(alignment: .leading, spacing: GymupSpacing.small) {
                errorMessageView(errorMessage)
                Button("다시 시도") {
                    Task { await viewModel.retry(provider: presentation.provider) }
                }
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.accent)
                .disabled(viewModel.isLoading)
            }
        } else if viewModel.items.isEmpty {
            VStack(alignment: .leading, spacing: GymupSpacing.medium) {
                GymupEmptyState(
                    symbol: "music.note.list",
                    title: "플레이리스트가 없어요",
                    message: "선택한 음악 서비스에서 읽을 수 있는 플레이리스트가 없어요."
                )
                Button("새로고침") {
                    Task { await viewModel.retry(provider: presentation.provider) }
                }
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.accent)
                .disabled(viewModel.isLoading)
            }
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.items) { item in
                    playlistRow(item)
                }
            }
        }
    }

    private func playlistRow(_ item: PlaylistCatalogItem) -> some View {
        let isSelected = selectedPlaylist?.id == item.id
        return Button {
            selectedPlaylist = item
            saveErrorMessage = nil
        } label: {
            HStack(spacing: GymupSpacing.medium) {
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text(item.name)
                        .font(GymupTypography.callout)
                        .foregroundStyle(GymupColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(presentation.provider.displayName)
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? GymupColors.brandText : GymupColors.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, GymupSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(GymupColors.separator).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityHint("탭하여 이 플레이리스트를 선택합니다")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("playlist.catalog.\(item.id)")
    }

    private var footer: some View {
        VStack(spacing: GymupSpacing.small) {
            if let saveErrorMessage {
                errorMessageView(saveErrorMessage)
            }
            Text(selectedPlaylist.map { "선택됨 · \($0.name)" } ?? "플레이리스트를 선택해 주세요")
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .lineLimit(2)
                .accessibilityIdentifier("playlist.selected")
            Button(action: save) {
                HStack(spacing: GymupSpacing.small) {
                    if isSaving { ProgressView().controlSize(.small).tint(.white) }
                    Text(isSaving ? "서버에 저장 중" : "루틴에 연결")
                        .font(ProfileTypography.action)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(GymupColors.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selectedPlaylist == nil || isSaving)
            .opacity(selectedPlaylist == nil ? 0.48 : 1)
            .accessibilityIdentifier("playlist.save")
        }
        .padding(.horizontal, GymupSpacing.large)
        .padding(.top, GymupSpacing.medium)
        .padding(.bottom, GymupSpacing.medium)
        .background(GymupColors.canvas)
    }

    private func errorMessageView(_ message: String) -> some View {
        Text(message)
            .font(GymupTypography.caption)
            .foregroundStyle(GymupColors.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        guard let selectedPlaylist, !isSaving else { return }
        isSaving = true
        saveErrorMessage = nil
        Task {
            defer { isSaving = false }
            do {
                try await onSave(selectedPlaylist)
                dismiss()
            } catch {
                saveErrorMessage = (error as? LocalizedError)?.errorDescription ??
                    "플레이리스트를 루틴에 연결하지 못했어요. 다시 시도해 주세요."
            }
        }
    }
}
