import AVFoundation
import XCTest
@testable import GYMUP

final class WorkoutCameraPermissionRequesterTests: XCTestCase {
    func testAuthorizedCameraContinuesWithoutRequestingPermissionAgain() async {
        var requestCount = 0
        let requester = WorkoutCameraPermissionRequester(
            authorizationStatus: { .authorized },
            requestAccess: {
                requestCount += 1
                return false
            }
        )

        let isAuthorized = await requester.requestCameraAccess()

        XCTAssertTrue(isAuthorized)
        XCTAssertEqual(requestCount, 0)
    }

    func testUndeterminedCameraRequestsSystemPermissionAfterUserContinues() async {
        var requestCount = 0
        let requester = WorkoutCameraPermissionRequester(
            authorizationStatus: { .notDetermined },
            requestAccess: {
                requestCount += 1
                return true
            }
        )

        let isAuthorized = await requester.requestCameraAccess()

        XCTAssertTrue(isAuthorized)
        XCTAssertEqual(requestCount, 1)
    }

    func testDeniedSystemPermissionDoesNotContinueToCamera() async {
        var requestCount = 0
        let requester = WorkoutCameraPermissionRequester(
            authorizationStatus: { .notDetermined },
            requestAccess: {
                requestCount += 1
                return false
            }
        )

        let isAuthorized = await requester.requestCameraAccess()

        XCTAssertFalse(isAuthorized)
        XCTAssertEqual(requestCount, 1)
    }

    func testDeniedCameraDoesNotRequestAgain() async {
        var requestCount = 0
        let requester = WorkoutCameraPermissionRequester(
            authorizationStatus: { .denied },
            requestAccess: {
                requestCount += 1
                return true
            }
        )

        let isAuthorized = await requester.requestCameraAccess()

        XCTAssertFalse(isAuthorized)
        XCTAssertEqual(requestCount, 0)
    }
}
