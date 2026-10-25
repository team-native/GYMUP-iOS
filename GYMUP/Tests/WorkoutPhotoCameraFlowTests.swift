import XCTest
@testable import GYMUP

final class WorkoutPhotoCameraFlowTests: XCTestCase {
    func testGrantedCameraPermissionOpensCameraScreen() {
        XCTAssertEqual(WorkoutPhotoCameraFlow.cameraStep(afterPermissionGranted: true), .camera)
    }

    func testDeniedCameraPermissionDoesNotOpenCameraScreen() {
        XCTAssertNil(WorkoutPhotoCameraFlow.cameraStep(afterPermissionGranted: false))
    }

    func testSuccessfulCameraCaptureContinuesToPhotoFilters() {
        XCTAssertEqual(WorkoutPhotoCameraFlow.editorStep(afterCaptureSucceeded: true), .filters)
    }

    func testFailedCameraCaptureStaysOnCameraScreen() {
        XCTAssertNil(WorkoutPhotoCameraFlow.editorStep(afterCaptureSucceeded: false))
    }
}
