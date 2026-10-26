import Foundation

enum PlaylistProvider: String, CaseIterable, Hashable, Identifiable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"

    var id: Self { self }
}

struct PlaylistTrack: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let duration: String
    var isSelected: Bool
}

struct RoutinePlaylistAssignment: Equatable {
    var playlistTitle: String?
    var tracks: [PlaylistTrack]

    var isConnected: Bool { playlistTitle != nil }
    var selectedTrackCount: Int { tracks.filter(\.isSelected).count }

    mutating func toggleTrack(withID id: PlaylistTrack.ID) {
        guard let index = tracks.firstIndex(where: { $0.id == id }) else { return }
        tracks[index].isSelected.toggle()
    }

    mutating func applySelection(for routineTitle: String) {
        guard selectedTrackCount > 0 else {
            playlistTitle = nil
            return
        }
        if playlistTitle == nil {
            playlistTitle = "\(routineTitle) 믹스"
        }
    }
}

struct RoutinePlaylist: Identifiable, Equatable {
    let id: String
    let title: String
    var assignments: [PlaylistProvider: RoutinePlaylistAssignment]

    func assignment(for provider: PlaylistProvider) -> RoutinePlaylistAssignment {
        assignments[provider] ?? RoutinePlaylistAssignment(playlistTitle: nil, tracks: [])
    }

    mutating func setAssignment(_ assignment: RoutinePlaylistAssignment, for provider: PlaylistProvider) {
        assignments[provider] = assignment
    }
}

struct PlaylistTrackSelectionPresentation: Identifiable {
    let routine: RoutinePlaylist
    let provider: PlaylistProvider

    var id: String { "\(routine.id)-\(provider.id)" }
}

enum RoutinePlaylistSampleData {
    static let routines = [
        RoutinePlaylist(
            id: "upper-a",
            title: "상체 A",
            assignments: [
                .appleMusic: assignment(
                    title: "Heavy Lifting Mix",
                    routineID: "upper-a-apple",
                    count: 42,
                    selected: true
                ),
                .spotify: assignment(
                    title: "Strength Mode",
                    routineID: "upper-a-spotify",
                    count: 24,
                    selected: true
                )
            ]
        ),
        RoutinePlaylist(
            id: "lower-b",
            title: "하체 B",
            assignments: [
                .appleMusic: assignment(title: nil, routineID: "lower-b-apple", count: 6, selected: false),
                .spotify: assignment(title: nil, routineID: "lower-b-spotify", count: 6, selected: false)
            ]
        ),
        RoutinePlaylist(
            id: "back-c",
            title: "등 · 이두 C",
            assignments: [
                .appleMusic: assignment(
                    title: "Pump Up",
                    routineID: "back-c-apple",
                    count: 30,
                    selected: true
                ),
                .spotify: assignment(
                    title: "Pull Day",
                    routineID: "back-c-spotify",
                    count: 18,
                    selected: true
                )
            ]
        )
    ]

    private static let trackTitles = [
        "오늘은 어제보다 강해지는 긴 웨이트 트레이닝 믹스",
        "Power Within",
        "Push Through",
        "All the Way Up",
        "Iron Mind",
        "No Turning Back"
    ]

    private static func assignment(
        title: String?,
        routineID: String,
        count: Int,
        selected: Bool
    ) -> RoutinePlaylistAssignment {
        let tracks = (0..<count).map { index in
            let baseTitle = trackTitles[index % trackTitles.count]
            let suffix = index < trackTitles.count ? "" : " \(index + 1)"
            return PlaylistTrack(
                id: "\(routineID)-\(index)",
                title: baseTitle + suffix,
                artist: "GYMUP Mix",
                duration: index.isMultiple(of: 2) ? "3:24" : "2:58",
                isSelected: selected
            )
        }
        return RoutinePlaylistAssignment(playlistTitle: title, tracks: tracks)
    }
}
