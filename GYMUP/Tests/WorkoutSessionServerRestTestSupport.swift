import Foundation
@testable import GYMUP

@MainActor
final class MockWorkoutSessionRestService: WorkoutSessionProgressing, WorkoutNextSetReading {
    struct SetRequest {
        let workoutId: String
        let request: CreateWorkoutSetRequest
        let idempotencyKey: String?
    }

    struct RestRequest {
        let workoutID: String
        let request: StartRestRequest
    }

    var setRequests: [SetRequest] = []
    var restRequests: [RestRequest] = []
    var currentRestRequests: [String] = []
    var nextSetRequests: [String] = []
    var skipRequests: [String] = []
    var extendRequests: [(String, Int)] = []
    var nextRestStartError: Error?
    var nextCurrentRestError: Error?
    var nextSkipError: Error?
    var nextExtendError: Error?
    var restStartCommitsBeforeThrow = false
    var currentRestResponse: CurrentRestResponse?
    var nextExtendResponse: ExtendCurrentRestResponse?
    var nextSetResponse: NextWorkoutSetResponse?
    var nextSetError: Error?
    private let startDate: Date

    init(startDate: Date) {
        self.startDate = startDate
        currentRestResponse = makeCurrentRest(startDate: startDate, duration: 75)
    }

    func createSet(
        workoutId: String,
        request: CreateWorkoutSetRequest,
        idempotencyKey: String?
    ) async throws -> CreateWorkoutSetResponse {
        setRequests.append(SetRequest(workoutId: workoutId, request: request, idempotencyKey: idempotencyKey))
        return CreateWorkoutSetResponse(
            setId: "set-\(setRequests.count)",
            workoutId: workoutId,
            exerciseId: request.exerciseId,
            setIndex: request.setIndex,
            isPersonalRecord: false,
            nextAction: .object([:]),
            rest: .object([:])
        )
    }

    func advanceExercise(
        workoutId: String,
        request: AdvanceWorkoutExerciseRequest
    ) async throws -> AdvanceWorkoutExerciseResponse {
        AdvanceWorkoutExerciseResponse(
            workoutId: workoutId,
            currentExercise: .object([:]),
            nextExercise: .object([:]),
            status: "IN_PROGRESS"
        )
    }

    func startRest(workoutId: String, request: StartRestRequest) async throws -> StartRestResponse {
        restRequests.append(RestRequest(workoutID: workoutId, request: request))
        let response = makeStartRest(request: request, startDate: startDate)
        if let error = nextRestStartError {
            nextRestStartError = nil
            if restStartCommitsBeforeThrow {
                currentRestResponse = makeCurrentRest(startDate: startDate, duration: request.durationSeconds)
            }
            throw error
        }
        currentRestResponse = makeCurrentRest(startDate: startDate, duration: request.durationSeconds)
        return response
    }

    func currentRest(workoutId: String) async throws -> CurrentRestResponse {
        currentRestRequests.append(workoutId)
        if let error = nextCurrentRestError {
            nextCurrentRestError = nil
            throw error
        }
        guard let currentRestResponse else { throw APIClientError.invalidResponse }
        return currentRestResponse
    }

    func nextSet(workoutId: String) async throws -> NextWorkoutSetResponse {
        nextSetRequests.append(workoutId)
        if let error = nextSetError {
            nextSetError = nil
            throw error
        }
        guard let nextSetResponse else { throw APIClientError.invalidResponse }
        return nextSetResponse
    }

    func skipCurrentRest(workoutId: String) async throws -> SkipCurrentRestResponse {
        skipRequests.append(workoutId)
        if let error = nextSkipError {
            nextSkipError = nil
            throw error
        }
        return SkipCurrentRestResponse(restId: "rest-1", status: .skipped, nextSet: .object([:]))
    }

    func extendCurrentRest(workoutId: String, by seconds: Int) async throws -> ExtendCurrentRestResponse {
        extendRequests.append((workoutId, seconds))
        if let error = nextExtendError {
            nextExtendError = nil
            throw error
        }
        if let nextExtendResponse { return nextExtendResponse }
        return ExtendCurrentRestResponse(
            restId: "rest-1",
            endsAt: serverDate(startDate.addingTimeInterval(75 + TimeInterval(seconds))),
            remainingSeconds: 75 + seconds
        )
    }

    private func makeStartRest(request: StartRestRequest, startDate: Date) -> StartRestResponse {
        StartRestResponse(
            restId: "rest-1",
            startedAt: serverDate(startDate),
            endsAt: serverDate(startDate.addingTimeInterval(TimeInterval(request.durationSeconds))),
            durationSeconds: request.durationSeconds,
            nextSet: .object([:])
        )
    }

    private func makeCurrentRest(startDate: Date, duration: Int) -> CurrentRestResponse {
        CurrentRestResponse(
            restId: "rest-1",
            status: "ACTIVE",
            startedAt: serverDate(startDate),
            endsAt: serverDate(startDate.addingTimeInterval(TimeInterval(duration))),
            remainingSeconds: duration,
            notificationAt: serverDate(startDate.addingTimeInterval(TimeInterval(max(duration - 10, 0))))
        )
    }

    private func serverDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
