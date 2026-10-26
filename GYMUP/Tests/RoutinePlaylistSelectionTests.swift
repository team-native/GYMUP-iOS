import XCTest
@testable import GYMUP

final class RoutinePlaylistSelectionTests: XCTestCase {
    func testSampleAssignmentsMatchS4RoutineRows() throws {
        let upper = try XCTUnwrap(RoutinePlaylistSampleData.routines.first { $0.id == "upper-a" })
        let lower = try XCTUnwrap(RoutinePlaylistSampleData.routines.first { $0.id == "lower-b" })
        let back = try XCTUnwrap(RoutinePlaylistSampleData.routines.first { $0.id == "back-c" })

        XCTAssertEqual(upper.assignment(for: .appleMusic).playlistTitle, "Heavy Lifting Mix")
        XCTAssertEqual(upper.assignment(for: .appleMusic).selectedTrackCount, 42)
        XCTAssertFalse(lower.assignment(for: .appleMusic).isConnected)
        XCTAssertEqual(back.assignment(for: .appleMusic).playlistTitle, "Pump Up")
        XCTAssertEqual(back.assignment(for: .appleMusic).selectedTrackCount, 30)
    }

    func testTrackSelectionCanBeToggledOnAndOff() throws {
        let routine = try XCTUnwrap(RoutinePlaylistSampleData.routines.first { $0.id == "lower-b" })
        var assignment = routine.assignment(for: .appleMusic)
        let firstTrack = try XCTUnwrap(assignment.tracks.first)

        assignment.toggleTrack(withID: firstTrack.id)

        XCTAssertEqual(assignment.selectedTrackCount, 1)
        XCTAssertTrue(assignment.tracks[0].isSelected)

        assignment.toggleTrack(withID: firstTrack.id)

        XCTAssertEqual(assignment.selectedTrackCount, 0)
        XCTAssertFalse(assignment.tracks[0].isSelected)
    }

    func testApplyingSelectedTracksConnectsAnUnassignedRoutine() throws {
        let routine = try XCTUnwrap(RoutinePlaylistSampleData.routines.first { $0.id == "lower-b" })
        var assignment = routine.assignment(for: .appleMusic)
        let firstTrack = try XCTUnwrap(assignment.tracks.first)
        assignment.toggleTrack(withID: firstTrack.id)

        assignment.applySelection(for: routine.title)

        XCTAssertEqual(assignment.playlistTitle, "하체 B 믹스")
        XCTAssertTrue(assignment.isConnected)
        XCTAssertEqual(assignment.selectedTrackCount, 1)
    }

    func testApplyingAnEmptySelectionClearsThePlaylist() throws {
        let routine = try XCTUnwrap(RoutinePlaylistSampleData.routines.first { $0.id == "upper-a" })
        var assignment = routine.assignment(for: .appleMusic)
        let selectedTrackIDs = assignment.tracks.filter(\.isSelected).map(\.id)
        for trackID in selectedTrackIDs {
            assignment.toggleTrack(withID: trackID)
        }

        assignment.applySelection(for: routine.title)

        XCTAssertNil(assignment.playlistTitle)
        XCTAssertFalse(assignment.isConnected)
        XCTAssertEqual(assignment.selectedTrackCount, 0)
    }

    func testLongTrackTitleIsProvidedForWrapping() throws {
        let routine = try XCTUnwrap(RoutinePlaylistSampleData.routines.first { $0.id == "upper-a" })
        let firstTrack = try XCTUnwrap(routine.assignment(for: .appleMusic).tracks.first)

        XCTAssertGreaterThan(firstTrack.title.count, 20)
    }

    func testEmptyTrackListKeepsAnUnassignedRoutineDisconnected() {
        var assignment = RoutinePlaylistAssignment(playlistTitle: nil, tracks: [])

        assignment.applySelection(for: "빈 루틴")

        XCTAssertTrue(assignment.tracks.isEmpty)
        XCTAssertEqual(assignment.selectedTrackCount, 0)
        XCTAssertFalse(assignment.isConnected)
    }
}
