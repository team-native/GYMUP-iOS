import Foundation
import Observation

enum RoutineEditorSaveResult: Equatable {
    case saved(String)
    case invalid
    case failed(String)
}

@Observable
@MainActor
final class RoutineEditorViewModel {
    let store: RoutineStore
    let routineID: String?
    var title: String
    var exercises: [RoutineExercise]
    var draggingExerciseID: String?
    private(set) var isSaving = false

    private let serverRoutineIDAtOpen: String?
    private var serverExercises: [RoutineEditorServerExercise]?
    private var serverExerciseOrder: [String]?
    private var pendingExercisePatch: UpdateRoutineExercisesRequest?
    private var pendingExerciseOrder: [String]?

    init(store: RoutineStore, routineID: String?) {
        self.store = store
        self.routineID = routineID
        let routine = routineID.flatMap(store.routine(id:))
        title = routine?.title ?? ""
        exercises = routine?.exercises ?? []
        serverRoutineIDAtOpen = routine?.serverRoutineId
        if routine?.serverRoutineId != nil {
            serverExercises = routine?.exercises.map(RoutineEditorServerExercise.init)
            serverExerciseOrder = routine?.exercises.map(\.id)
        } else {
            serverExercises = nil
            serverExerciseOrder = nil
        }
    }

    var exerciseCount: Int { exercises.count }
    var validation: RoutineSaveValidation {
        RoutineSaveValidation(title: title, exerciseCount: exerciseCount)
    }
    var canSave: Bool { validation.isValid }

    func limitTitle(_ value: String) {
        title = String(value.prefix(20))
    }

    func moveExercise(id draggedID: String, before targetID: String) {
        guard draggedID != targetID,
              let source = exercises.firstIndex(where: { $0.id == draggedID }),
              let target = exercises.firstIndex(where: { $0.id == targetID }) else { return }
        let movingExercise = exercises.remove(at: source)
        let destination = source < target ? target - 1 : target
        exercises.insert(movingExercise, at: destination)
    }

    func updateExercise(_ exercise: RoutineExercise) {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        exercises[index] = exercise
    }

    func removeExercise(id: String) {
        exercises.removeAll { $0.id == id }
    }

    /// Local routines keep the existing local-first save behavior. A server-backed
    /// routine must go through `saveAndSync` so the server ID cannot become stale.
    @discardableResult
    func save() -> String? {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validation.isValid else { return nil }
        if let routineID, store.routine(id: routineID)?.serverRoutineId != nil { return nil }
        return store.saveRoutine(id: routineID, title: normalizedTitle, exercises: exercises)
    }

    func saveAndSync(using service: RoutineExerciseEditing?) async -> RoutineEditorSaveResult {
        guard validation.isValid else { return .invalid }

        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let routineID, let routine = store.routine(id: routineID) else {
            return saveLocally(routineID: routineID, title: normalizedTitle)
        }
        guard let serverRoutineID = routine.serverRoutineId else {
            return saveLocally(routineID: routineID, title: normalizedTitle)
        }
        return await saveServerBackedRoutine(
            routineID: routineID,
            serverRoutineID: serverRoutineID,
            title: normalizedTitle,
            using: service
        )
    }

    private func saveLocally(routineID: String?, title: String) -> RoutineEditorSaveResult {
        .saved(store.saveRoutine(id: routineID, title: title, exercises: exercises))
    }

    private func saveServerBackedRoutine(
        routineID: String,
        serverRoutineID: String,
        title: String,
        using service: RoutineExerciseEditing?
    ) async -> RoutineEditorSaveResult {
        guard !serverRoutineID.isEmpty else {
            return .failed("서버에서 루틴 ID를 확인하지 못했어요. 변경 내용은 유지돼요.")
        }
        guard canSyncServerRoutine(serverRoutineID) else {
            return .failed("루틴의 서버 정보가 바뀌었어요. 화면을 다시 열어 주세요.")
        }
        guard hasServerChanges else {
            return saveLocally(routineID: routineID, title: title)
        }
        guard let service else {
            return .failed("서버 연결을 사용할 수 없어요. 변경 내용은 이 화면에 유지돼요.")
        }
        guard !isSaving else {
            return .failed("저장 요청을 처리 중이에요. 잠시 후 다시 시도해 주세요.")
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await synchronizeServerRoutine(using: service, routineID: serverRoutineID)
            guard serverStateMatchesDraft else {
                return .failed("서버 저장 내용을 확인하지 못했어요. 변경은 이 화면에 유지돼요. 다시 시도해 주세요.")
            }
            guard store.routine(id: routineID)?.serverRoutineId == serverRoutineID else {
                return .failed("루틴 정보가 바뀌어 로컬 저장을 완료하지 못했어요. 다시 열어 확인해 주세요.")
            }
            return saveLocally(routineID: routineID, title: title)
        } catch {
            clearRejectedOperations(for: error)
            return .failed(Self.failureMessage(for: error))
        }
    }

    private var hasServerChanges: Bool {
        pendingExercisePatch != nil
            || pendingExerciseOrder != nil
            || exercisePatch(for: exercises) != nil
            || serverExerciseOrder != exercises.map(\.id)
    }

    private var serverStateMatchesDraft: Bool {
        let confirmedByID = (serverExercises ?? []).reduce(into: [String: RoutineEditorServerExercise]()) {
            $0[$1.exerciseId] = $1
        }
        let expectedByID = exercises.reduce(into: [String: RoutineEditorServerExercise]()) {
            let state = RoutineEditorServerExercise($1)
            $0[state.exerciseId] = state
        }
        return serverExerciseOrder == exercises.map(\.id)
            && confirmedByID.count == expectedByID.count
            && confirmedByID == expectedByID
    }

    private func canSyncServerRoutine(_ serverRoutineID: String) -> Bool {
        serverRoutineIDAtOpen == serverRoutineID
            && serverExercises != nil
            && serverExerciseOrder != nil
    }

    private func synchronizeServerRoutine(
        using service: RoutineExerciseEditing,
        routineID: String
    ) async throws {
        // Resolve an earlier ambiguous PATCH before creating a fresh delta.
        try await sendPendingExercisePatch(using: service, routineID: routineID)
        if let request = exercisePatch(for: exercises) {
            pendingExercisePatch = request
            try await sendPendingExercisePatch(using: service, routineID: routineID)
        }

        // PUT sends an absolute order, so retrying the saved request is safe.
        try await sendPendingExerciseOrder(using: service, routineID: routineID)
        let desiredOrder = exercises.map(\.id)
        if serverExerciseOrder != desiredOrder {
            pendingExerciseOrder = desiredOrder
            try await sendPendingExerciseOrder(using: service, routineID: routineID)
        }
    }

    private func clearRejectedOperations(for error: Error) {
        guard case let APIClientError.server(statusCode, _) = error,
              (400..<500).contains(statusCode) else { return }
        pendingExercisePatch = nil
        pendingExerciseOrder = nil
    }

    private func exercisePatch(for draft: [RoutineExercise]) -> UpdateRoutineExercisesRequest? {
        guard let serverExercises else { return nil }
        let serverByID = serverExercises.reduce(into: [String: RoutineEditorServerExercise]()) {
            $0[$1.exerciseId] = $1
        }
        let draftIDs = Set(draft.map(\.id))

        let additions = draft.enumerated().compactMap { index, exercise -> CreateRoutineExerciseRequest? in
            guard serverByID[exercise.id] == nil else { return nil }
            return RoutineEditorServerExercise(exercise).additionRequest(order: index)
        }
        let updates = draft.compactMap { exercise -> UpdateRoutineExerciseRequest? in
            guard let current = serverByID[exercise.id] else { return nil }
            let desired = RoutineEditorServerExercise(exercise)
            guard current != desired else { return nil }
            return desired.updateRequest
        }
        let removals = serverExercises.compactMap { current in
            draftIDs.contains(current.exerciseId) ? nil : current.exerciseId
        }

        guard !additions.isEmpty || !updates.isEmpty || !removals.isEmpty else { return nil }
        return UpdateRoutineExercisesRequest(add: additions, update: updates, removeExerciseIds: removals)
    }

    private func sendPendingExercisePatch(
        using service: RoutineExerciseEditing,
        routineID: String
    ) async throws {
        guard let request = pendingExercisePatch else { return }
        let response = try await service.updateExercises(routineId: routineID, request: request)
        guard response.routineId == routineID else { throw RoutineEditorSyncError.unexpectedRoutineID }
        serverExercises = response.exercises.map(RoutineEditorServerExercise.init)
        serverExerciseOrder = response.exercises.map(\.exerciseId)
        pendingExercisePatch = nil
    }

    private func sendPendingExerciseOrder(
        using service: RoutineExerciseEditing,
        routineID: String
    ) async throws {
        guard let exerciseIDs = pendingExerciseOrder else { return }
        let response = try await service.updateExerciseOrder(
            routineId: routineID,
            request: UpdateRoutineExerciseOrderRequest(exerciseIds: exerciseIDs)
        )
        let responseIDs = response.orderedExercises.map(\.exerciseId)
        guard response.routineId == routineID,
              responseIDs == exerciseIDs,
              responseIDs.count == Set(responseIDs).count else {
            throw RoutineEditorSyncError.invalidOrderResponse
        }
        serverExercises = response.orderedExercises.map(RoutineEditorServerExercise.init)
        serverExerciseOrder = responseIDs
        pendingExerciseOrder = nil
    }

    private static func failureMessage(for error: Error) -> String {
        if case let APIClientError.server(_, detail) = error {
            return "\(detail.message)\n\n입력한 내용은 이 화면에 유지돼요."
        }
        if error is RoutineEditorSyncError {
            return "서버 응답을 확인하지 못했어요. 변경 내용은 이 화면에 유지돼요. 다시 시도해 주세요."
        }
        return "서버에 루틴을 저장하지 못했어요. 입력한 내용은 이 화면에 유지돼요. 다시 시도해 주세요."
    }
}

private struct RoutineEditorServerExercise: Equatable {
    let exerciseId: String
    let sets: Int
    let reps: Int
    let weight: Double
    let restSeconds: Int

    init(_ exercise: RoutineExercise) {
        exerciseId = exercise.id
        sets = exercise.setCount
        reps = exercise.repetitions
        weight = exercise.weight
        restSeconds = exercise.restSeconds
    }

    init(_ response: RoutineExerciseResponse) {
        exerciseId = response.exerciseId
        sets = response.sets
        reps = response.reps
        weight = response.weight
        restSeconds = response.restSeconds
    }

    var updateRequest: UpdateRoutineExerciseRequest {
        UpdateRoutineExerciseRequest(
            exerciseId: exerciseId,
            sets: sets,
            reps: reps,
            weight: weight,
            restSeconds: restSeconds
        )
    }

    func additionRequest(order: Int) -> CreateRoutineExerciseRequest {
        CreateRoutineExerciseRequest(
            exerciseId: exerciseId,
            sets: sets,
            reps: reps,
            weight: weight,
            restSeconds: restSeconds,
            order: order
        )
    }
}

private enum RoutineEditorSyncError: Error {
    case unexpectedRoutineID
    case invalidOrderResponse
}
