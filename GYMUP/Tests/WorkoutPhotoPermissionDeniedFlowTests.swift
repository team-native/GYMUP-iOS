import XCTest
@testable import GYMUP

final class WorkoutPhotoPermissionDeniedFlowTests: XCTestCase {
    func testDeniedPermissionShowsP3Screen() {
        XCTAssertEqual(WorkoutPhotoCameraFlow.permissionStep(isAuthorized: false), .permissionDenied)
    }

    func testPermissionGrantedAfterReturningFromSettingsResumesCamera() {
        XCTAssertEqual(WorkoutPhotoCameraFlow.stepAfterSettingsReturn(isAuthorized: true), .camera)
    }

    func testStillDeniedAfterReturningFromSettingsRemainsOnP3Screen() {
        XCTAssertEqual(WorkoutPhotoCameraFlow.stepAfterSettingsReturn(isAuthorized: false), .permissionDenied)
    }
}
