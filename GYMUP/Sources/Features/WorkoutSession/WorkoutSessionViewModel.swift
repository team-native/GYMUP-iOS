import Foundation
import Observation

@Observable
@MainActor
final class WorkoutSessionViewModel {
    private(set) var plan: WorkoutSessionPlan
    var currentExerciseIndex = 0
    private(set) var now: Date
    private(set) var finishedAt: Date?
    var notice: String?
    private(set) var serverWorkoutID: String?
    private let historyStore: HistoryStore
    private let goalSettings: OnboardingStoredSettings?
    private let previousRecordService: ExerciseReadAPIService?
    let progressService: WorkoutSessionProgressing?
    private(set) var previousRecordErrors: [String: String] = [:]
    private(set) var loadingPreviousRecordExerciseIDs: Set<String> = []
    var isSubmittingWorkoutAction = false
    var serverActionErrorMessage: String?
    var failedServerAction: FailedWorkoutServerAction?

    var pendingSetSubmission: PendingWorkoutSetSubmission?
    var pendingExerciseAdvance: AdvanceWorkoutExerciseRequest?
    var pendingRestStart: PendingWorkoutRestStart?

    var hasPendingServerSetSubmission: Bool { pendingSetSubmission != nil }
    var isServerManagedRest = false

    private(set) var startedAt: Date?
    private var pausedAt: Date?
    private var accumulatedPauseSeconds: TimeInterval = 0
    var restEndsAt: Date?
    var activeRestDurationSeconds = 0

    init(
        routineID: String,
        startedAt: Date = Date(),
        startsImmediately: Bool = true,
        historyStore: HistoryStore? = nil,
        goalSettings: OnboardingStoredSettings? = .load(),
        previousRecordService: ExerciseReadAPIService? = nil,
        progressService: WorkoutSessionProgressing? = nil
    ) {
        plan = .sample(for: routineID)
        self.startedAt = startsImmediately ? startedAt : nil
        now = startedAt
        self.historyStore = historyStore ?? HistoryStore()
        self.goalSettings = goalSettings
        self.previousRecordService = previousRecordService
        self.progressService = progressService
        serverWorkoutID = nil
    }

    init(
        plan: WorkoutSessionPlan,
        startedAt: Date = Date(),
        startsImmediately: Bool = true,
        historyStore: HistoryStore? = nil,
        goalSettings: OnboardingStoredSettings? = .load(),
        previousRecordService: ExerciseReadAPIService? = nil,
        serverWorkoutID: String? = nil,
        progressService: WorkoutSessionProgressing? = nil
    ) {
        self.plan = plan
        self.startedAt = startsImmediately ? startedAt : nil
        now = startedAt
        self.historyStore = historyStore ?? HistoryStore()
        self.goalSettings = goalSettings
        self.previousRecordService = previousRecordService
        self.serverWorkoutID = serverWorkoutID
        self.progressService = progressService
    }

    var isPaused: Bool { pausedAt != nil }
    var hasStarted: Bool { startedAt != nil }
    var isFinished: Bool { finishedAt != nil }
    var isResting: Bool { !isPaused && restEndsAt.map { $0 > now } == true }
    var completedExerciseCount: Int { plan.exercises.filter(\.isComplete).count }
    var elapsedSeconds: Int { elapsedSeconds(at: now) }
    var completionData: WorkoutCompletionData? {
        guard let finishedAt else { return nil }
        return WorkoutSessionCompletionDataFactory.make(
            plan: plan,
            elapsedSeconds: elapsedSeconds(at: finishedAt),
            completedAt: finishedAt,
            context: WorkoutCompletionProgressContext(historyStore: historyStore, goalSettings: goalSettings)
        )
    }

    var restSecondsRemaining: Int {
        guard isResting, let restEndsAt else { return 0 }
        return max(0, Int(ceil(restEndsAt.timeIntervalSince(now))))
    }

    var activeRestEndsAt: Date? { restEndsAt }

    func synchronizeRestTimer(endsAt: Date, durationSeconds: Int, at date: Date) {
        guard restEndsAt != nil, !isPaused else { return }
        now = date
        activeRestDurationSeconds = min(max(durationSeconds, 0), 600)
        restEndsAt = endsAt
    }

    func elapsedSeconds(at date: Date) -> Int {
        guard let startedAt else { return 0 }
        let endDate = finishedAt ?? pausedAt ?? date
        let activeDuration = endDate.timeIntervalSince(startedAt) - accumulatedPauseSeconds
        return max(0, Int(activeDuration.rounded(.down)))
    }

    func start(at date: Date = Date()) {
        guard !hasStarted, !isFinished else { return }
        startedAt = date
        now = date
    }

    @discardableResult
    func refreshClock(at date: Date) -> Bool {
        now = date
        let didRestEnd = !isPaused && restEndsAt.map { date >= $0 } == true
        if didRestEnd {
            self.restEndsAt = nil
            activeRestDurationSeconds = 0
            isServerManagedRest = false
        }
        return didRestEnd
    }

    func updateWeight(_ weight: Double, exerciseIndex: Int, setIndex: Int) {
        guard hasStarted,
              !isPaused,
              !isFinished,
              !isSubmittingWorkoutAction,
              !isPendingServerSet(exerciseIndex: exerciseIndex, setIndex: setIndex),
              plan.exercises.indices.contains(exerciseIndex),
              plan.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        plan.exercises[exerciseIndex].sets[setIndex].weightKilograms = min(max(weight, 0), 999)
        notice = nil
    }

    func updateRepetitions(_ repetitions: Int, exerciseIndex: Int, setIndex: Int) {
        guard hasStarted,
              !isPaused,
              !isFinished,
              !isSubmittingWorkoutAction,
              !isPendingServerSet(exerciseIndex: exerciseIndex, setIndex: setIndex),
              plan.exercises.indices.contains(exerciseIndex),
              plan.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        plan.exercises[exerciseIndex].sets[setIndex].repetitions = min(max(repetitions, 0), 999)
        notice = nil
    }

    func addSet(to exerciseIndex: Int) {
        guard hasStarted,
              !isPaused,
              !isFinished,
              !isSubmittingWorkoutAction,
              pendingSetSubmission == nil,
              plan.exercises.indices.contains(exerciseIndex) else { return }
        let lastSet = plan.exercises[exerciseIndex].sets.last
        let newSet = WorkoutSessionSet(
            weightKilograms: lastSet?.weightKilograms ?? 0,
            repetitions: lastSet?.repetitions ?? 10
        )
        plan.exercises[exerciseIndex].sets.append(newSet)
        notice = nil
    }

    func toggleSetCompletion(exerciseIndex: Int, setIndex: Int, at date: Date? = nil) {
        guard hasStarted,
              !isPaused,
              !isFinished,
              serverWorkoutID == nil,
              plan.exercises.indices.contains(exerciseIndex),
              plan.exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }

        if plan.exercises[exerciseIndex].sets[setIndex].isCompleted {
            plan.exercises[exerciseIndex].sets[setIndex].isCompleted = false
            restEndsAt = nil
            activeRestDurationSeconds = 0
            return
        }

        markSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex, at: date)
    }

    func markSetCompleted(
        exerciseIndex: Int,
        setIndex: Int,
        at date: Date?,
        startsLocalRest: Bool = true
    ) {
        guard plan.exercises.indices.contains(exerciseIndex),
              plan.exercises[exerciseIndex].sets.indices.contains(setIndex),
              !plan.exercises[exerciseIndex].sets[setIndex].isCompleted else { return }
        plan.exercises[exerciseIndex].sets[setIndex].isCompleted = true
        notice = nil

        guard startsLocalRest else {
            restEndsAt = nil
            activeRestDurationSeconds = 0
            isServerManagedRest = false
            return
        }

        let hasMoreSets = plan.exercises[exerciseIndex].sets.contains { !$0.isCompleted }
        if hasMoreSets, let date {
            now = date
            activeRestDurationSeconds = min(max(plan.exercises[exerciseIndex].restDurationSeconds, 0), 600)
            restEndsAt = date.addingTimeInterval(TimeInterval(activeRestDurationSeconds))
        } else if hasMoreSets {
            activeRestDurationSeconds = min(max(plan.exercises[exerciseIndex].restDurationSeconds, 0), 600)
            restEndsAt = now.addingTimeInterval(TimeInterval(activeRestDurationSeconds))
        } else {
            restEndsAt = nil
            activeRestDurationSeconds = 0
        }
        isServerManagedRest = false
    }

    func skipRest() {
        restEndsAt = nil
        activeRestDurationSeconds = 0
        isServerManagedRest = false
    }

    func extendRest(by seconds: Int) {
        guard seconds > 0, isResting, let restEndsAt else { return }
        let updatedDuration = min(activeRestDurationSeconds + seconds, 600)
        let addedDuration = updatedDuration - activeRestDurationSeconds
        guard addedDuration > 0 else { return }
        activeRestDurationSeconds = updatedDuration
        self.restEndsAt = restEndsAt.addingTimeInterval(TimeInterval(addedDuration))
    }

    func togglePause(at date: Date) {
        guard hasStarted, !isFinished else { return }
        now = date

        if let pausedAt {
            let pauseDuration = max(0, date.timeIntervalSince(pausedAt))
            accumulatedPauseSeconds += pauseDuration
            if let restEndsAt {
                self.restEndsAt = restEndsAt.addingTimeInterval(pauseDuration)
            }
            self.pausedAt = nil
        } else {
            pausedAt = date
        }
    }

    func finish(at date: Date = Date()) {
        guard hasStarted, !isFinished else { return }
        now = date
        if let pausedAt {
            accumulatedPauseSeconds += max(0, date.timeIntervalSince(pausedAt))
            self.pausedAt = nil
        }
        finishedAt = date
        restEndsAt = nil
        activeRestDurationSeconds = 0
        isServerManagedRest = false
        notice = nil
    }
}

extension WorkoutSessionViewModel {
    func previousRecordError(for exerciseID: String) -> String? {
        previousRecordErrors[exerciseID]
    }

    func isLoadingPreviousRecord(for exerciseID: String) -> Bool {
        loadingPreviousRecordExerciseIDs.contains(exerciseID)
    }

    func loadPreviousRecord(for exerciseID: String) async {
        guard let previousRecordService,
              plan.exercises.contains(where: { $0.id == exerciseID }),
              !loadingPreviousRecordExerciseIDs.contains(exerciseID) else { return }

        loadingPreviousRecordExerciseIDs.insert(exerciseID)
        defer { loadingPreviousRecordExerciseIDs.remove(exerciseID) }

        do {
            let response = try await previousRecordService.previousRecord(exerciseId: exerciseID)
            guard response.exerciseId == exerciseID,
                  let exerciseIndex = plan.exercises.firstIndex(where: { $0.id == exerciseID }) else {
                throw APIClientError.invalidResponse
            }

            plan.exercises[exerciseIndex].usesSampleHistory = false
            plan.exercises[exerciseIndex].previousRecord = response.hasPreviousRecord
                ? WorkoutSessionPreviousRecord(response: response)
                : nil
            previousRecordErrors.removeValue(forKey: exerciseID)
        } catch {
            guard !Task.isCancelled else { return }
            if let clientError = error as? APIClientError,
               case let .server(_, detail) = clientError {
                previousRecordErrors[exerciseID] = detail.message
            } else {
                previousRecordErrors[exerciseID] = "이전 기록을 불러오지 못했어요."
            }
        }
    }
}
