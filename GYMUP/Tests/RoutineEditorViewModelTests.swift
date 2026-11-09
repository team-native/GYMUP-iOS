import XCTest
@testable import GYMUP

final class RoutineEditorViewModelTests: XCTestCase {
    @MainActor
    func testTitleIsLimitedToTwentyCharactersAndWhitespaceCannotSave() {
        let viewModel = RoutineEditorViewModel(store: RoutineStore(), routineID: "upper-a")
        viewModel.limitTitle(String(repeating: "가", count: 21))
        XCTAssertEqual(viewModel.title.count, 20)
        XCTAssertTrue(viewModel.canSave)
        viewModel.title = "   "
        XCTAssertFalse(viewModel.canSave)
        XCTAssertNil(viewModel.save())
    }

    @MainActor
    func testReorderingMovesExerciseBeforeTarget() {
        let viewModel = RoutineEditorViewModel(store: RoutineStore(), routineID: "upper-a")
        viewModel.moveExercise(id: "pushdown", before: "bench")
        XCTAssertEqual(viewModel.exercises.first?.id, "pushdown")
        viewModel.moveExercise(id: "bench", before: "shoulder")
        XCTAssertEqual(viewModel.exercises.map(\.id), ["pushdown", "incline", "bench", "shoulder", "fly"])
    }

    @MainActor
    func testSavingUpdatesSharedRoutineAndCreatesNewRoutine() {
        let store = RoutineStore()
        let editor = RoutineEditorViewModel(store: store, routineID: "upper-a")
        editor.title = "가슴 루틴"
        editor.exercises.removeLast()
        XCTAssertEqual(editor.save(), "upper-a")
        XCTAssertEqual(store.routine(id: "upper-a")?.title, "가슴 루틴")
        XCTAssertEqual(store.routine(id: "upper-a")?.exerciseCount, 4)

        let newEditor = RoutineEditorViewModel(store: store, routineID: nil)
        newEditor.title = "하체 A"
        newEditor.exercises = [RoutineExercise.lower[0]]
        let newID = newEditor.save()
        XCTAssertEqual(store.routine(id: newID ?? "")?.title, "하체 A")
    }

    @MainActor
    func testRoutineWithoutExercisesCannotBeSaved() {
        let store = RoutineStore()
        let editor = RoutineEditorViewModel(store: store, routineID: nil)
        editor.title = "상체 A"

        XCTAssertFalse(editor.canSave)
        XCTAssertNil(editor.save())
        XCTAssertEqual(store.routines.count, RoutinePlan.samples.count)
    }

    @MainActor
    func testExerciseSettingsApplyAndDeleteUpdateEditorDraft() {
        let viewModel = RoutineEditorViewModel(store: RoutineStore(), routineID: "upper-a")
        var edited = viewModel.exercises[0]
        edited.weight = 62.5
        viewModel.updateExercise(edited)
        XCTAssertEqual(viewModel.exercises.first?.weight, 62.5)
        viewModel.removeExercise(id: edited.id)
        XCTAssertFalse(viewModel.exercises.contains(where: { $0.id == edited.id }))
    }

    @MainActor
    func testServerBackedSaveSyncsExerciseChangesAndOrderWithoutClearingServerID() async throws {
        let store = RoutineStore()
        XCTAssertTrue(store.storeServerRoutineID("server-routine-1", for: "upper-a"))
        let originalExercises = store.routine(id: "upper-a")?.exercises ?? []
        let service = RoutineExerciseEditorStub(exercises: Self.responses(for: originalExercises))
        let editor = RoutineEditorViewModel(store: store, routineID: "upper-a")
        editor.title = "가슴 루틴 이름"
        editor.exercises.removeAll { $0.id == "incline" }
        var bench = try XCTUnwrap(editor.exercises.first { $0.id == "bench" })
        bench.weight = 62.5
        editor.updateExercise(bench)
        editor.exercises.append(
            RoutineExercise(id: "cable", name: "케이블 플라이", imageAssetName: "R1RoutineBack",
                            setCount: 3, repetitions: 12, weight: 15, restSeconds: 60)
        )
        editor.moveExercise(id: "cable", before: "bench")

        let result = await editor.saveAndSync(using: service)

        guard case .saved("upper-a") = result else { return XCTFail("Expected a successful save, got \(result).") }
        let patchRequests = await service.recordedPatchRequests()
        let orderRequests = await service.recordedOrderRequests()
        XCTAssertEqual(patchRequests.count, 1)
        XCTAssertEqual(patchRequests[0].add.map(\.exerciseId), ["cable"])
        XCTAssertEqual(patchRequests[0].update.map(\.exerciseId), ["bench"])
        XCTAssertEqual(patchRequests[0].update.first?.weight, 62.5)
        XCTAssertEqual(patchRequests[0].removeExerciseIds, ["incline"])
        XCTAssertEqual(orderRequests.map(\.exerciseIds), [editor.exercises.map(\.id)])
        XCTAssertEqual(store.routine(id: "upper-a")?.serverRoutineId, "server-routine-1")
        XCTAssertEqual(store.routine(id: "upper-a")?.title, "가슴 루틴 이름")
    }

    @MainActor
    func testRetryAfterOrderFailureDoesNotRepeatSuccessfulPatchAndKeepsDraft() async throws {
        let store = RoutineStore()
        XCTAssertTrue(store.storeServerRoutineID("server-routine-1", for: "upper-a"))
        let original = try XCTUnwrap(store.routine(id: "upper-a"))
        let service = RoutineExerciseEditorStub(
            exercises: Self.responses(for: original.exercises),
            failNextOrderBeforeApplying: true
        )
        let editor = RoutineEditorViewModel(store: store, routineID: "upper-a")
        editor.removeExercise(id: "pushdown")
        editor.moveExercise(id: "bench", before: "shoulder")
        let draft = editor.exercises

        let firstResult = await editor.saveAndSync(using: service)

        guard case .failed = firstResult else { return XCTFail("Expected the order failure to be reported.") }
        XCTAssertEqual(editor.exercises, draft)
        XCTAssertEqual(store.routine(id: "upper-a")?.exercises, original.exercises)
        XCTAssertEqual(store.routine(id: "upper-a")?.serverRoutineId, "server-routine-1")

        let retryResult = await editor.saveAndSync(using: service)

        guard case .saved("upper-a") = retryResult else { return XCTFail("Expected retry to save, got \(retryResult).") }
        let patchRequests = await service.recordedPatchRequests()
        let orderRequests = await service.recordedOrderRequests()
        XCTAssertEqual(patchRequests.count, 1)
        XCTAssertEqual(orderRequests.count, 2)
        XCTAssertEqual(orderRequests[0], orderRequests[1])
        XCTAssertEqual(store.routine(id: "upper-a")?.exercises, draft)
    }

    @MainActor
    func testAmbiguousPatchRetryResendsSameRequestAndDoesNotDuplicateAddedExercise() async throws {
        let store = RoutineStore()
        XCTAssertTrue(store.storeServerRoutineID("server-routine-1", for: "upper-a"))
        let original = try XCTUnwrap(store.routine(id: "upper-a"))
        let service = RoutineExerciseEditorStub(
            exercises: Self.responses(for: original.exercises),
            failNextPatchAfterApplying: true
        )
        let editor = RoutineEditorViewModel(store: store, routineID: "upper-a")
        let added = RoutineExercise(id: "cable", name: "케이블 플라이", imageAssetName: "R1RoutineBack",
                                    setCount: 3, repetitions: 12, weight: 15, restSeconds: 60)
        editor.exercises.append(added)

        let firstResult = await editor.saveAndSync(using: service)
        guard case .failed = firstResult else { return XCTFail("Expected the ambiguous PATCH to be reported.") }

        let retryResult = await editor.saveAndSync(using: service)

        guard case .saved("upper-a") = retryResult else { return XCTFail("Expected retry to save, got \(retryResult).") }
        let patchRequests = await service.recordedPatchRequests()
        let savedServerExercises = await service.currentExercises()
        XCTAssertEqual(patchRequests.count, 2)
        XCTAssertEqual(patchRequests[0], patchRequests[1])
        XCTAssertEqual(savedServerExercises.filter { $0.exerciseId == "cable" }.count, 1)
    }

    @MainActor
    func testLocalRoutineSaveDoesNotCallExerciseSyncService() async {
        let store = RoutineStore()
        let editor = RoutineEditorViewModel(store: store, routineID: "lower-b")
        editor.title = "하체 루틴"
        let service = RoutineExerciseEditorStub(exercises: [])

        let result = await editor.saveAndSync(using: service)

        guard case .saved("lower-b") = result else { return XCTFail("Expected local save, got \(result).") }
        XCTAssertNil(store.routine(id: "lower-b")?.serverRoutineId)
        let patchRequests = await service.recordedPatchRequests()
        let orderRequests = await service.recordedOrderRequests()
        XCTAssertTrue(patchRequests.isEmpty)
        XCTAssertTrue(orderRequests.isEmpty)
    }

    @MainActor
    func testServerBackedTitleCanSaveLocallyWithoutSendingUnsupportedNameUpdate() async {
        let store = RoutineStore()
        XCTAssertTrue(store.storeServerRoutineID("server-routine-1", for: "upper-a"))
        let editor = RoutineEditorViewModel(store: store, routineID: "upper-a")
        editor.title = "내 루틴 이름"

        let result = await editor.saveAndSync(using: nil)

        guard case .saved("upper-a") = result else { return XCTFail("Expected the local title to save, got \(result).") }
        XCTAssertEqual(store.routine(id: "upper-a")?.title, "내 루틴 이름")
        XCTAssertEqual(store.routine(id: "upper-a")?.serverRoutineId, "server-routine-1")
    }

    private static func responses(for exercises: [RoutineExercise]) -> [RoutineExerciseResponse] {
        exercises.enumerated().map { response(for: $0.element, order: $0.offset) }
    }

    private static func response(for exercise: RoutineExercise, order: Int) -> RoutineExerciseResponse {
        RoutineExerciseResponse(
            exerciseId: exercise.id,
            sets: exercise.setCount,
            reps: exercise.repetitions,
            weight: exercise.weight,
            restSeconds: exercise.restSeconds,
            order: order
        )
    }
}

private actor RoutineExerciseEditorStub: RoutineExerciseEditing {
    private let routineID = "server-routine-1"
    private var exercises: [RoutineExerciseResponse]
    private var patchRequests: [UpdateRoutineExercisesRequest] = []
    private var orderRequests: [UpdateRoutineExerciseOrderRequest] = []
    private var failNextPatchAfterApplying: Bool
    private var failNextOrderBeforeApplying: Bool

    init(
        exercises: [RoutineExerciseResponse],
        failNextPatchAfterApplying: Bool = false,
        failNextOrderBeforeApplying: Bool = false
    ) {
        self.exercises = exercises
        self.failNextPatchAfterApplying = failNextPatchAfterApplying
        self.failNextOrderBeforeApplying = failNextOrderBeforeApplying
    }

    func updateExercises(
        routineId: String,
        request: UpdateRoutineExercisesRequest
    ) async throws -> UpdateRoutineExercisesResponse {
        patchRequests.append(request)
        guard routineId == routineID else { throw URLError(.badURL) }
        let removeIDs = Set(request.removeExerciseIds)
        exercises.removeAll { removeIDs.contains($0.exerciseId) }
        for update in request.update {
            guard let index = exercises.firstIndex(where: { $0.exerciseId == update.exerciseId }) else { continue }
            exercises[index] = RoutineExerciseResponse(
                exerciseId: update.exerciseId,
                sets: update.sets,
                reps: update.reps,
                weight: update.weight,
                restSeconds: update.restSeconds,
                order: exercises[index].order
            )
        }
        for addition in request.add {
            if let index = exercises.firstIndex(where: { $0.exerciseId == addition.exerciseId }) {
                exercises[index] = RoutineExerciseResponse(
                    exerciseId: addition.exerciseId,
                    sets: addition.sets,
                    reps: addition.reps,
                    weight: addition.weight,
                    restSeconds: addition.restSeconds,
                    order: exercises[index].order
                )
            } else {
                exercises.append(
                    RoutineExerciseResponse(
                        exerciseId: addition.exerciseId,
                        sets: addition.sets,
                        reps: addition.reps,
                        weight: addition.weight,
                        restSeconds: addition.restSeconds,
                        order: addition.order
                    )
                )
            }
        }
        if failNextPatchAfterApplying {
            failNextPatchAfterApplying = false
            throw URLError(.timedOut)
        }
        return UpdateRoutineExercisesResponse(
            routineId: routineID,
            exercises: exercises,
            updatedAt: "2026-11-09T00:00:00Z"
        )
    }

    func updateExerciseOrder(
        routineId: String,
        request: UpdateRoutineExerciseOrderRequest
    ) async throws -> UpdateRoutineExerciseOrderResponse {
        orderRequests.append(request)
        guard routineId == routineID else { throw URLError(.badURL) }
        if failNextOrderBeforeApplying {
            failNextOrderBeforeApplying = false
            throw URLError(.timedOut)
        }
        let byID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.exerciseId, $0) })
        guard request.exerciseIds.count == byID.count,
              Set(request.exerciseIds) == Set(byID.keys) else { throw URLError(.cannotParseResponse) }
        exercises = request.exerciseIds.enumerated().compactMap { index, exerciseID in
            guard let exercise = byID[exerciseID] else { return nil }
            return RoutineExerciseResponse(
                exerciseId: exercise.exerciseId,
                sets: exercise.sets,
                reps: exercise.reps,
                weight: exercise.weight,
                restSeconds: exercise.restSeconds,
                order: index
            )
        }
        return UpdateRoutineExerciseOrderResponse(
            routineId: routineID,
            orderedExercises: exercises,
            updatedAt: "2026-11-09T00:00:00Z"
        )
    }

    func recordedPatchRequests() -> [UpdateRoutineExercisesRequest] { patchRequests }
    func recordedOrderRequests() -> [UpdateRoutineExerciseOrderRequest] { orderRequests }
    func currentExercises() -> [RoutineExerciseResponse] { exercises }
}
