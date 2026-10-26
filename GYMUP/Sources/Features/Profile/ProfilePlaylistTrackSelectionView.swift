import SwiftUI

struct ProfilePlaylistTrackSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var assignment: RoutinePlaylistAssignment

    private let routine: RoutinePlaylist
    private let provider: PlaylistProvider
    private let onSave: (RoutinePlaylist) -> Void

    init(
        presentation: PlaylistTrackSelectionPresentation,
        onSave: @escaping (RoutinePlaylist) -> Void
    ) {
        routine = presentation.routine
        provider = presentation.provider
        self.onSave = onSave
        _assignment = State(initialValue: presentation.routine.assignment(for: presentation.provider))
    }

    var body: some View {
        VStack(spacing: 0) {
            ProfilePlaylistNavigationBar(title: routine.title, onBack: dismiss.callAsFunction)

            if assignment.tracks.isEmpty {
                GymupEmptyState(
                    symbol: "music.note.list",
                    title: "선택할 곡이 없어요",
                    message: "샘플 곡 목록이 비어 있어요. 루틴별 플레이리스트 상태를 다시 확인해 주세요."
                )
                .padding(.horizontal, GymupSpacing.large)
                Spacer(minLength: 0)
            } else {
                trackList
            }
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
    }

    private var trackList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.large) {
                HStack(alignment: .firstTextBaseline, spacing: GymupSpacing.small) {
                    Text(provider.rawValue)
                        .font(GymupTypography.headline)
                        .foregroundStyle(GymupColors.primaryText)
                    Text("샘플 곡 목록")
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                }
                .accessibilityElement(children: .combine)

                if assignment.selectedTrackCount == 0 {
                    emptySelectionNotice
                }

                LazyVStack(spacing: 0) {
                    ForEach(assignment.tracks) { track in
                        ProfilePlaylistTrackRow(track: track) {
                            assignment.toggleTrack(withID: track.id)
                        }
                    }
                }
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.small)
            .padding(.bottom, GymupSpacing.large)
        }
    }

    private var emptySelectionNotice: some View {
        HStack(alignment: .top, spacing: GymupSpacing.small) {
            Image(systemName: "info.circle")
                .foregroundStyle(GymupColors.brandText)
                .accessibilityHidden(true)
            Text("선택된 곡이 없어요. 한 곡 이상 선택해 주세요.")
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GymupSpacing.medium)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        VStack(spacing: GymupSpacing.small) {
            Text("\(assignment.selectedTrackCount)곡 선택됨")
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .accessibilityLabel("선택한 곡 \(assignment.selectedTrackCount)개")

            Button(action: save) {
                Text(assignment.isConnected ? "변경 사항 저장" : "플레이리스트 연결")
                    .font(ProfileTypography.action)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(GymupColors.accent, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(assignment.selectedTrackCount == 0 && !assignment.isConnected)
            .opacity(assignment.selectedTrackCount == 0 && !assignment.isConnected ? 0.48 : 1)
            .accessibilityLabel(
                assignment.isConnected ? "플레이리스트 변경 사항 저장" : "선택한 곡으로 플레이리스트 연결"
            )
            .accessibilityHint(
                assignment.selectedTrackCount == 0
                    ? "곡을 하나 이상 선택해야 합니다"
                    : "선택한 곡을 루틴에 저장합니다"
            )
        }
        .padding(.horizontal, GymupSpacing.large)
        .padding(.top, GymupSpacing.medium)
        .padding(.bottom, GymupSpacing.medium)
        .background(GymupColors.canvas)
    }

    private func save() {
        var updatedRoutine = routine
        var updatedAssignment = assignment
        updatedAssignment.applySelection(for: routine.title)
        updatedRoutine.setAssignment(updatedAssignment, for: provider)
        onSave(updatedRoutine)
        dismiss()
    }
}

private struct ProfilePlaylistTrackRow: View {
    let track: PlaylistTrack
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: GymupSpacing.medium) {
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text(track.title)
                        .font(GymupTypography.callout)
                        .foregroundStyle(GymupColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(track.artist) · \(track.duration)")
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: track.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(track.isSelected ? GymupColors.brandText : GymupColors.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, GymupSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(GymupColors.separator)
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(track.title), \(track.artist), \(track.duration)")
        .accessibilityValue(track.isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityHint("탭하여 곡을 선택하거나 해제합니다")
        .accessibilityAddTraits(track.isSelected ? .isSelected : [])
        .accessibilityIdentifier("playlist.track.\(track.id)")
    }
}

#Preview {
    ProfilePlaylistTrackSelectionView(
        presentation: PlaylistTrackSelectionPresentation(
            routine: RoutinePlaylistSampleData.routines[0],
            provider: .appleMusic
        ),
        onSave: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("빈 곡 목록") {
    let routine = RoutinePlaylist(
        id: "empty-routine",
        title: "빈 루틴",
        assignments: [.appleMusic: RoutinePlaylistAssignment(playlistTitle: nil, tracks: [])]
    )
    return ProfilePlaylistTrackSelectionView(
        presentation: PlaylistTrackSelectionPresentation(routine: routine, provider: .appleMusic),
        onSave: { _ in }
    )
    .preferredColorScheme(.dark)
}
