import Foundation
import XCTest
@testable import GYMUP

final class RoutineAPIServiceTests: NetworkingTestCase {
    func testRoutineExercisePatchAndAbsoluteOrderUseDocumentedContracts() async throws {
        var capturedRequests: [URLRequest] = []
        installJSONResponses(
            [
                "/api/v1/routines/server-1/exercises": (200, patchResponse()),
                "/api/v1/routines/server-1/exercises/order": (200, orderResponse())
            ],
            recordRequest: { capturedRequests.append($0) }
        )
        let service = RoutineAPIService(client: try makeClient(token: "test-token"))
        let patchRequest = makePatchRequest()
        let patchResponse = try await service.updateExercises(routineId: "server-1", request: patchRequest)
        let orderRequest = UpdateRoutineExerciseOrderRequest(exerciseIds: ["bench"])
        let orderResponse = try await service.updateExerciseOrder(routineId: "server-1", request: orderRequest)

        XCTAssertEqual(capturedRequests.map(\.httpMethod), ["PATCH", "PUT"])
        XCTAssertEqual(capturedRequests.map { $0.url?.path }, [
            "/api/v1/routines/server-1/exercises",
            "/api/v1/routines/server-1/exercises/order"
        ])
        let decodedPatchRequest = try JSONDecoder().decode(
            UpdateRoutineExercisesRequest.self,
            from: XCTUnwrap(capturedRequests[0].httpBody)
        )
        let decodedOrderRequest = try JSONDecoder().decode(
            UpdateRoutineExerciseOrderRequest.self,
            from: XCTUnwrap(capturedRequests[1].httpBody)
        )
        XCTAssertEqual(decodedPatchRequest, patchRequest)
        XCTAssertEqual(decodedOrderRequest, orderRequest)
        XCTAssertEqual(patchResponse.routineId, "server-1")
        XCTAssertEqual(patchResponse.exercises.first?.weight, 62.5)
        XCTAssertEqual(orderResponse.orderedExercises.map(\.exerciseId), ["bench"])
    }

    private func patchResponse() -> [String: Any] {
        [
            "routineId": "server-1",
            "exercises": [responseExercise(order: 0)],
            "updatedAt": "2026-11-09T00:00:00Z"
        ]
    }

    private func orderResponse() -> [String: Any] {
        [
            "routineId": "server-1",
            "orderedExercises": [responseExercise(order: 0)],
            "updatedAt": "2026-11-09T00:00:01Z"
        ]
    }

    private func responseExercise(order: Int) -> [String: Any] {
        [
            "exerciseId": "bench",
            "sets": 4,
            "reps": 8,
            "weight": 62.5,
            "restSeconds": 90,
            "order": order
        ]
    }

    private func makePatchRequest() -> UpdateRoutineExercisesRequest {
        UpdateRoutineExercisesRequest(
            add: [CreateRoutineExerciseRequest(
                exerciseId: "bench", sets: 4, reps: 8, weight: 62.5, restSeconds: 90, order: 0
            )],
            update: [UpdateRoutineExerciseRequest(
                exerciseId: "squat", sets: 3, reps: 6, weight: 100, restSeconds: 120
            )],
            removeExerciseIds: ["curl"]
        )
    }
}
