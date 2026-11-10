import Foundation
import Observation

enum RoutineListMode: String, CaseIterable, Identifiable {
    case mine = "내 루틴"
    case recommended = "추천"
    var id: Self { self }
}

enum RoutineServerIDPreparationResult {
    case ready
    case failed(message: String)
}

enum RoutineWorkoutStartResult: Equatable {
    case started(serverWorkoutID: String, startedAt: Date)
    case routineSyncFailed(message: String)
    case workoutStartFailed(message: String)
}

@Observable
@MainActor
final class RoutineViewModel {
    let store: RoutineStore
    private let routineCreator: RoutineCreating?
    private let workoutStarter: WorkoutStarting?
    let routineExerciseEditor: RoutineExerciseEditing?
    private var startedWorkoutVersions: [String: Int] = [:]
    private(set) var preparingServerRoutineID: String?
    var isPreparingServerRoutineID: Bool { preparingServerRoutineID != nil }
    var mode = RoutineListMode.mine

    init(
        store: RoutineStore,
        routineCreator: RoutineCreating? = nil,
        workoutStarter: WorkoutStarting? = nil,
        routineExerciseEditor: RoutineExerciseEditing? = nil
    ) {
        self.store = store
        self.routineCreator = routineCreator
        self.workoutStarter = workoutStarter
        self.routineExerciseEditor = routineExerciseEditor
    }

    var routines: [RoutinePlan] {
        mode == .mine ? store.routines : store.routines.filter(\.isRecommended)
    }

    func prepareServerRoutineID(for localRoutineID: String) async -> RoutineServerIDPreparationResult {
        guard let context = routineCreationContext(for: localRoutineID) else { return .ready }

        preparingServerRoutineID = localRoutineID
        defer { preparingServerRoutineID = nil }

        let request = createRoutineRequest(from: context.routine)

        do {
            let response = try await context.creator.createRoutine(request)
            return saveServerRoutineID(
                response.routineId,
                for: localRoutineID,
                matching: context.routine,
                requestName: request.name
            )
        } catch {
            return routineCreationFailure(for: error)
        }
    }

    private func routineCreationContext(for localRoutineID: String) -> (routine: RoutinePlan, creator: RoutineCreating)? {
        guard !isPreparingServerRoutineID,
              let routine = store.routine(id: localRoutineID),
              routine.serverRoutineId == nil,
              let routineCreator else { return nil }
        return (routine, routineCreator)
    }

    private func createRoutineRequest(from routine: RoutinePlan) -> CreateRoutineRequest {
        CreateRoutineRequest(
            name: routine.name,
            exercises: routine.exercises.enumerated().map { index, exercise in
                CreateRoutineExerciseRequest(
                    exerciseId: exercise.id,
                    sets: exercise.setCount,
                    reps: exercise.repetitions,
                    weight: exercise.weight,
                    restSeconds: exercise.restSeconds,
                    order: index
                )
            }
        )
    }

    private func saveServerRoutineID(
        _ serverRoutineID: String,
        for localRoutineID: String,
        matching originalRoutine: RoutinePlan,
        requestName: String
    ) -> RoutineServerIDPreparationResult {
        guard !serverRoutineID.isEmpty else {
            return .failed(message: "서버에서 루틴 ID를 확인하지 못했어요.")
        }
        guard let currentRoutine = store.routine(id: localRoutineID),
              currentRoutine.name == requestName,
              currentRoutine.exercises == originalRoutine.exercises else {
            return .failed(message: "요청 중 루틴이 변경되었어요. 다시 시도해 주세요.")
        }
        guard store.storeServerRoutineID(serverRoutineID, for: localRoutineID) else {
            return .failed(message: "서버에서 루틴 ID를 확인하지 못했어요.")
        }
        return .ready
    }

    private func routineCreationFailure(for error: Error) -> RoutineServerIDPreparationResult {
        if case let APIClientError.server(_, detail) = error {
            return .failed(message: detail.message)
        }
        return .failed(message: "서버에 루틴을 저장하지 못했어요.")
    }

    func startServerWorkout(
        for localRoutineID: String,
        at startedAt: Date = .now,
        timeZone: TimeZone = .current
    ) async -> RoutineWorkoutStartResult {
        guard let routine = store.routine(id: localRoutineID) else {
            return .routineSyncFailed(message: "루틴을 찾을 수 없어요. 다시 시도해 주세요.")
        }

        if routine.serverRoutineId == nil {
            switch await prepareServerRoutineID(for: localRoutineID) {
            case .ready:
                break
            case let .failed(message):
                return .routineSyncFailed(message: message)
            }
        }

        guard let currentRoutine = store.routine(id: localRoutineID),
              let serverRoutineID = currentRoutine.serverRoutineId,
              !serverRoutineID.isEmpty
        else {
            return .routineSyncFailed(message: "서버에서 루틴 ID를 확인하지 못했어요.")
        }
        return await startServerWorkout(
            with: serverRoutineID,
            for: localRoutineID,
            at: startedAt,
            timeZone: timeZone
        )
    }

    private func startServerWorkout(
        with serverRoutineID: String,
        for localRoutineID: String,
        at startedAt: Date,
        timeZone: TimeZone
    ) async -> RoutineWorkoutStartResult {
        guard let workoutStarter else {
            return .workoutStartFailed(message: "서버 운동 시작 기능을 사용할 수 없어요.")
        }
        guard !isPreparingServerRoutineID else {
            return .workoutStartFailed(message: "요청을 처리 중이에요. 잠시 후 다시 시도해 주세요.")
        }

        preparingServerRoutineID = localRoutineID
        defer { preparingServerRoutineID = nil }

        let request = StartWorkoutRequest(
            routineId: serverRoutineID,
            startedAt: Self.iso8601String(from: startedAt),
            timezone: timeZone.identifier
        )

        do {
            let response = try await workoutStarter.startWorkout(request: request)
            guard !response.workoutId.isEmpty else {
                return .workoutStartFailed(message: "서버에서 운동 ID를 확인하지 못했어요.")
            }
            if let version = response.version, version > 0 {
                startedWorkoutVersions[response.workoutId] = version
            }
            return .started(serverWorkoutID: response.workoutId, startedAt: startedAt)
        } catch let APIClientError.server(_, detail) {
            return .workoutStartFailed(message: detail.message)
        } catch {
            return .workoutStartFailed(message: "서버에 운동을 시작하지 못했어요.")
        }
    }

    private static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    func serverWorkoutVersion(for workoutId: String) -> Int? {
        startedWorkoutVersions[workoutId]
    }
}
