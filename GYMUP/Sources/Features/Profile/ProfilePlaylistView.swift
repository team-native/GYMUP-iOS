import SwiftUI

struct ProfilePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var store: RoutineStore
    @State private var routineViewModel: RoutineViewModel
    @State private var selectedProvider: PlaylistProvider = .appleMusic
    @State private var selectionPresentation: PlaylistTrackSelectionPresentation?
    @State private var saveErrorMessage: String?

    private let routineService: RoutineAPIService?

    @MainActor
    init(store: RoutineStore, routineService: RoutineAPIService?) {
        self.store = store
        _routineViewModel = State(initialValue: RoutineViewModel(store: store, routineCreator: routineService))
        self.routineService = routineService
    }

    private var routines: [RoutinePlan] { store.routines.filter { !$0.isEmpty } }

    var body: some View {
        VStack(spacing: 0) {
            GymupDetailNavigationBar(title: "플레이리스트", onBack: dismiss.callAsFunction)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GymupSpacing.large) {
                    providerPicker

                    if let saveErrorMessage {
                        Text(saveErrorMessage)
                            .font(GymupTypography.caption)
                            .foregroundStyle(GymupColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if routines.isEmpty {
                        GymupEmptyState(
                            symbol: "music.note.list",
                            title: "연결할 루틴이 없어요",
                            message: "운동 루틴을 만든 뒤 플레이리스트를 연결할 수 있어요."
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(routines) { routine in
                                let reference = store.playlistReference(for: routine.id, provider: selectedProvider)
                                RoutinePlaylistRow(
                                    routine: routine,
                                    reference: reference,
                                    isPreparing: routineViewModel.preparingServerRoutineID == routine.id,
                                    isDisabled: routineViewModel.isPreparingServerRoutineID
                                ) {
                                    saveErrorMessage = nil
                                    selectionPresentation = PlaylistTrackSelectionPresentation(
                                        routineID: routine.id,
                                        routineTitle: routine.title,
                                        provider: selectedProvider,
                                        currentPlaylist: reference
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, GymupSpacing.large)
                .padding(.top, GymupSpacing.small)
                .padding(.bottom, GymupSpacing.xxLarge)
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectionPresentation) { presentation in
            ProfilePlaylistTrackSelectionView(presentation: presentation) { item in
                try await savePlaylist(item, for: presentation.routineID)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(GymupColors.canvas)
        }
    }

    private var providerPicker: some View {
        HStack(spacing: GymupSpacing.xSmall) {
            ForEach(PlaylistProvider.allCases) { provider in
                Button {
                    selectedProvider = provider
                    saveErrorMessage = nil
                } label: {
                    Text(provider.displayName)
                        .font(ProfileTypography.caption)
                        .foregroundStyle(
                            selectedProvider == provider ? GymupColors.primaryText : GymupColors.secondaryText
                        )
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background {
                            if selectedProvider == provider {
                                RoundedRectangle(cornerRadius: GymupRadius.small)
                                    .fill(GymupColors.elevatedSurface)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(provider.displayName) 선택")
                .accessibilityValue(selectedProvider == provider ? "선택됨" : "선택 안 됨")
                .accessibilityAddTraits(selectedProvider == provider ? .isSelected : [])
                .accessibilityIdentifier("playlist.provider.\(provider == .appleMusic ? "appleMusic" : "spotify")")
            }
        }
        .padding(GymupSpacing.xSmall)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
    }

    @MainActor
    private func savePlaylist(_ item: PlaylistCatalogItem, for localRoutineID: String) async throws {
        guard let routineService else {
            throw PlaylistProviderError.notConfigured("플레이리스트 저장 API를 사용할 수 없어요.")
        }
        guard let routine = store.routine(id: localRoutineID), !routine.isEmpty else {
            throw PlaylistProviderError.playlistLoadFailed("루틴을 찾을 수 없어요. 다시 선택해 주세요.")
        }

        if routine.serverRoutineId == nil {
            switch await routineViewModel.prepareServerRoutineID(for: localRoutineID) {
            case .ready:
                break
            case let .failed(message):
                throw PlaylistProviderError.playlistLoadFailed(message)
            }
        }

        guard let serverRoutineID = store.routine(id: localRoutineID)?.serverRoutineId,
              !serverRoutineID.isEmpty else {
            throw PlaylistProviderError.notConfigured("서버에 루틴을 먼저 저장해야 플레이리스트를 연결할 수 있어요.")
        }

        let response = try await routineService.updatePlaylist(
            routineId: serverRoutineID,
            request: UpdateRoutinePlaylistRequest(
                provider: item.provider.rawValue,
                playlistId: item.playlistId,
                playlistName: item.name,
                externalUrl: item.externalUrl
            )
        )
        guard response.routineId == serverRoutineID,
              response.playlist.provider == item.provider.rawValue,
              response.playlist.playlistId == item.playlistId,
              !response.playlist.playlistName.isEmpty,
              URL(string: response.playlist.externalUrl)?.scheme == "https" else {
            throw APIClientError.invalidResponse
        }

        let reference = RoutinePlaylistReference(
            provider: item.provider,
            playlistId: response.playlist.playlistId,
            playlistName: response.playlist.playlistName,
            externalUrl: response.playlist.externalUrl
        )
        guard store.storePlaylistReference(reference, for: localRoutineID) else {
            throw APIClientError.invalidResponse
        }
    }

    private struct RoutinePlaylistRow: View {
        let routine: RoutinePlan
        let reference: RoutinePlaylistReference?
        let isPreparing: Bool
        let isDisabled: Bool
        let action: () -> Void
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        var body: some View {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: GymupSpacing.small) {
                        HStack(spacing: GymupSpacing.medium) {
                            icon
                            details
                        }
                        actionButton.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                } else {
                    HStack(spacing: GymupSpacing.medium) {
                        icon
                        details
                        actionButton
                    }
                }
            }
            .padding(.vertical, GymupSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle().fill(GymupColors.separator).frame(height: 1)
            }
        }

        private var icon: some View {
            Image(systemName: "music.note")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(reference == nil ? GymupColors.secondaryText : GymupColors.brandText)
                .frame(width: 40, height: 40)
                .background(
                    reference == nil ? GymupColors.surface : GymupColors.accent.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: GymupRadius.small)
                )
                .accessibilityHidden(true)
        }

        private var details: some View {
            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text(routine.title)
                    .font(ProfileTypography.rowTitle)
                    .foregroundStyle(GymupColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(reference?.playlistName ?? "연결 안 됨")
                    .font(ProfileTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }

        private var actionButton: some View {
            Button(action: action) {
                HStack(spacing: GymupSpacing.xSmall) {
                    if isPreparing { ProgressView().controlSize(.small) }
                    Text(isPreparing ? "준비 중" : (reference == nil ? "연결" : "변경"))
                        .font(ProfileTypography.caption)
                }
                .foregroundStyle(GymupColors.primaryText)
                .padding(.horizontal, GymupSpacing.large)
                .frame(minWidth: 56, minHeight: 44)
                .overlay { Capsule().strokeBorder(GymupColors.border, lineWidth: 1) }
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .accessibilityLabel("\(routine.title) 플레이리스트 \(reference == nil ? "연결" : "변경")")
            .accessibilityHint("선택한 음악 서비스의 플레이리스트를 연결합니다")
            .accessibilityIdentifier("playlist.routine.\(routine.id).edit")
        }
    }
}

#Preview {
    NavigationStack {
        ProfilePlaylistView(store: RoutineStore(), routineService: nil)
    }
    .preferredColorScheme(.dark)
}
