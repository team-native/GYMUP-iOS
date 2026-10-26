import SwiftUI

struct ProfilePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProvider: PlaylistProvider = .appleMusic
    @State private var routines = RoutinePlaylistSampleData.routines
    @State private var selectionPresentation: PlaylistTrackSelectionPresentation?

    var body: some View {
        VStack(spacing: 0) {
            ProfilePlaylistNavigationBar(title: "플레이리스트", onBack: dismiss.callAsFunction)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GymupSpacing.large) {
                    versionBadge
                    providerPicker

                    VStack(spacing: 0) {
                        ForEach(routines) { routine in
                            RoutinePlaylistRow(
                                routine: routine,
                                assignment: routine.assignment(for: selectedProvider),
                                actionTitle: routine.assignment(for: selectedProvider).isConnected ? "변경" : "연결"
                            ) {
                                selectionPresentation = PlaylistTrackSelectionPresentation(
                                    routine: routine,
                                    provider: selectedProvider
                                )
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
            ProfilePlaylistTrackSelectionView(presentation: presentation) { updatedRoutine in
                guard let index = routines.firstIndex(where: { $0.id == updatedRoutine.id }) else { return }
                routines[index] = updatedRoutine
                selectionPresentation = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(GymupColors.canvas)
        }
    }

    private var versionBadge: some View {
        Text("V2 · MVP 제외")
            .font(GymupTypography.caption)
            .foregroundStyle(GymupColors.secondaryText)
            .padding(.horizontal, GymupSpacing.small)
            .padding(.vertical, GymupSpacing.xSmall)
            .background(GymupColors.surface, in: Capsule())
            .accessibilityLabel("버전 2, MVP 제외 예정")
    }

    private var providerPicker: some View {
        HStack(spacing: GymupSpacing.xSmall) {
            ForEach(PlaylistProvider.allCases) { provider in
                Button {
                    selectedProvider = provider
                } label: {
                    Text(provider.rawValue)
                        .font(ProfileTypography.caption)
                        .foregroundStyle(
                            selectedProvider == provider ? GymupColors.primaryText : GymupColors.secondaryText
                        )
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background {
                            if selectedProvider == provider {
                                RoundedRectangle(cornerRadius: GymupRadius.small)
                                    .fill(GymupColors.elevatedSurface)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(provider.rawValue) 선택")
                .accessibilityValue(selectedProvider == provider ? "선택됨" : "선택 안 됨")
                .accessibilityAddTraits(selectedProvider == provider ? .isSelected : [])
                .accessibilityIdentifier("playlist.provider.\(provider == .appleMusic ? "appleMusic" : "spotify")")
            }
        }
        .padding(GymupSpacing.xSmall)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
    }

    private struct RoutinePlaylistRow: View {
        let routine: RoutinePlaylist
        let assignment: RoutinePlaylistAssignment
        let actionTitle: String
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
                        actionButton
                            .frame(maxWidth: .infinity, alignment: .trailing)
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
                Rectangle()
                    .fill(GymupColors.separator)
                    .frame(height: 1)
            }
        }

        private var icon: some View {
            Image(systemName: "music.note")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(assignment.isConnected ? GymupColors.brandText : GymupColors.secondaryText)
                .frame(width: 40, height: 40)
                .background(
                    assignment.isConnected ? GymupColors.accent.opacity(0.14) : GymupColors.surface,
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

                Text(assignmentSummary)
                    .font(ProfileTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }

        private var actionButton: some View {
            Button(action: action) {
                Text(actionTitle)
                    .font(ProfileTypography.caption)
                    .foregroundStyle(GymupColors.primaryText)
                    .padding(.horizontal, GymupSpacing.large)
                    .frame(minWidth: 56, minHeight: 44)
                    .overlay {
                        Capsule()
                            .strokeBorder(GymupColors.border, lineWidth: 1)
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(routine.title) 플레이리스트 \(actionTitle)")
            .accessibilityHint(
                assignment.isConnected ? "선택한 음악 서비스의 곡을 수정합니다" : "이 루틴에 곡을 연결합니다"
            )
            .accessibilityIdentifier("playlist.routine.\(routine.id).edit")
        }

        private var assignmentSummary: String {
            guard let playlistTitle = assignment.playlistTitle else { return "연결 안 됨" }
            return "\(playlistTitle) · \(assignment.selectedTrackCount)곡"
        }
    }
}

struct ProfilePlaylistNavigationBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image("GymupIconChevronLeft")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("뒤로")

            Spacer(minLength: 0)
            Text(title)
                .font(GymupTypography.callout)
                .foregroundStyle(GymupColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)

            Color.clear
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, GymupSpacing.xSmall)
        .frame(minHeight: 48)
    }
}

#Preview {
    NavigationStack {
        ProfilePlaylistView()
    }
    .preferredColorScheme(.dark)
}
