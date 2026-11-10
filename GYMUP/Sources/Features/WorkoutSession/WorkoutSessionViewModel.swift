import Foundation
import Observation

@Observable
@MainActor
final class WorkoutSessionViewModel {
    private(set) var plan: WorkoutSessionPlan
    var currentExerciseIndex = 0
    private(set) var now: Date
    private(set) var finishedAt: Date?
    private(set) var serverCompletionData: WorkoutCompletionData?
    var notice: String?
    private(set) var serverWorkoutID: String?
    private(set) var serverWorkoutVersion: Int?
    private let historyStore: HistoryStore
    private let goalSettings: OnboardingStoredSettings?
    private let previousRecordService: WorkoutPreviousRecordLoading?
    private let completionService: WorkoutCompletionProcessing?
    private let rewardService: WorkoutRewardReading?
    private(set) var isLoadingReward = false
    private(set) var rewardErrorMessage: String?
    let exerciseGuidance: WorkoutExerciseGuidanceViewModel
    let nextSetService: WorkoutNextSetReading?
    let progressService: WorkoutSessionProgressing?
    private(set) var previousRecordErrors: [String: String] = [:]
    private(set) var loadingPreviousRecordExerciseIDs: Set<String> = []
    private(set) var nextSetPreview: NextWorkoutSetResponse?
    private(set) var nextSetPreviewError: String?
    private(set) var isLoadingNextSetPreview = false
    var isSubmittingWorkoutAction = false
    var serverActionErrorMessage: String?
    var failedServerAction: FailedWorkoutServerAction?

    var pendingSetSubmission: PendingWorkoutSetSubmission?
    var pendingExerciseAdvance: AdvanceWorkoutExerciseRequest?
    var pendingRestStart: PendingWorkoutRestStart?
    var pendingWorkoutCompletion: PendingWorkoutCompletion?

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
        previousRecordService: WorkoutPreviousRecordLoading? = nil,
        exerciseGuidanceService: ExerciseGuidanceReading? = nil,
        progressService: WorkoutSessionProgressing? = nil,
        nextSetService: WorkoutNextSetReading? = nil,
        completionService: WorkoutCompletionProcessing? = nil,
        rewardService: WorkoutRewardReading? = nil
    ) {
        plan = .sample(for: routineID)
        self.startedAt = startsImmediately ? startedAt : nil
        now = startedAt
        self.historyStore = historyStore ?? HistoryStore()
        self.goalSettings = goalSettings
        self.previousRecordService = previousRecordService
        self.completionService = completionService
        self.rewardService = rewardService
        exerciseGuidance = WorkoutExerciseGuidanceViewModel(service: exerciseGuidanceService)
        self.progressService = progressService
        self.nextSetService = nextSetService
        serverWorkoutID = nil
    }

    init(
        plan: WorkoutSessionPlan,
        startedAt: Date = Date(),
        startsImmediately: Bool = true,
        historyStore: HistoryStore? = nil,
        goalSettings: OnboardingStoredSettings? = .load(),
        previousRecordService: WorkoutPreviousRecordLoading? = nil,
        exerciseGuidanceService: ExerciseGuidanceReading? = nil,
        serverWorkoutID: String? = nil,
        serverWorkoutVersion: Int? = nil,
        progressService: WorkoutSessionProgressing? = nil,
        nextSetService: WorkoutNextSetReading? = nil,
        completionService: WorkoutCompletionProcessing? = nil,
        rewardService: WorkoutRewardReading? = nil
    ) {
        self.plan = plan
        self.startedAt = startsImmediately ? startedAt : nil
        now = startedAt
        self.historyStore = historyStore ?? HistoryStore()
        self.goalSettings = goalSettings
        self.previousRecordService = previousRecordService
        self.completionService = completionService
        self.rewardService = rewardService
        exerciseGuidance = WorkoutExerciseGuidanceViewModel(service: exerciseGuidanceService)
        self.serverWorkoutID = serverWorkoutID
        self.serverWorkoutVersion = serverWorkoutVersion
        self.progressService = progressService
        self.nextSetService = nextSetService
    }

    var isPaused: Bool { pausedAt != nil }
    var hasStarted: Bool { startedAt != nil }
    var isFinished: Bool { finishedAt != nil }
    var isResting: Bool { !isPaused && restEndsAt.map { $0 > now } == true }
    var completedExerciseCount: Int { plan.exercises.filter(\.isComplete).count }
    var elapsedSeconds: Int { elapsedSeconds(at: now) }
    var completionData: WorkoutCompletionData? {
        guard let finishedAt else { return nil }
        if let serverCompletionData { return serverCompletionData }
        return makeLocalCompletionData(at: finishedAt)
    }

    private func makeLocalCompletionData(at completedAt: Date) -> WorkoutCompletionData {
        return WorkoutSessionCompletionDataFactory.make(
            plan: plan,
            elapsedSeconds: elapsedSeconds(at: completedAt),
            completedAt: completedAt,
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

    func finishWorkout(at date: Date = .now) async -> Bool {
        guard hasStarted, !isFinished else { return false }
        guard let serverWorkoutID else {
            finish(at: date)
            return true
        }
        guard let completionService,
              let serverWorkoutVersion,
              serverWorkoutVersion > 0 else {
            failServerAction(.completeWorkout, error: APIClientError.invalidResponse)
            return false
        }
        guard !isSubmittingWorkoutAction else { return false }

        let pendingCompletion = pendingWorkoutCompletion ?? PendingWorkoutCompletion(
            workoutID: serverWorkoutID,
            request: CompleteWorkoutRequest(
                endedAt: Self.iso8601String(from: date),
                expectedVersion: serverWorkoutVersion
            ),
            completedAt: date
        )
        guard pendingCompletion.workoutID == serverWorkoutID,
              pendingCompletion.request.expectedVersion == serverWorkoutVersion else {
            failServerAction(.completeWorkout, error: APIClientError.invalidResponse)
            return false
        }
        pendingWorkoutCompletion = pendingCompletion

        isSubmittingWorkoutAction = true
        clearServerActionError()
        defer { isSubmittingWorkoutAction = false }

        do {
            let response = try await completionService.complete(
                workoutId: serverWorkoutID,
                request: pendingCompletion.request
            )
            guard response.workoutId == serverWorkoutID,
                  response.status == .completed,
                  response.duration >= 0,
                  response.totalSets >= 0,
                  response.volume.isFinite,
                  response.volume >= 0,
                  response.experiencePoints >= 0 else {
                throw APIClientError.invalidResponse
            }

            let summary = try? await completionService.summary(workoutId: serverWorkoutID)
            pendingWorkoutCompletion = nil
            finish(at: pendingCompletion.completedAt)

            let localData = makeLocalCompletionData(at: pendingCompletion.completedAt)
            serverCompletionData = WorkoutSessionCompletionDataFactory.applyingServerCompletion(response, to: localData)

            if let summary, isValidCompletedSummary(summary) {
                serverCompletionData = WorkoutSessionCompletionDataFactory.applyingServerSummary(
                    summary,
                    to: localData
                )
            }

            await loadWorkoutReward()

            clearServerActionError()
            return true
        } catch {
            let completionError = error
            if let summary = try? await completionService.summary(workoutId: serverWorkoutID),
               isValidCompletedSummary(summary) {
                pendingWorkoutCompletion = nil
                finish(at: pendingCompletion.completedAt)
                let localData = makeLocalCompletionData(at: pendingCompletion.completedAt)
                serverCompletionData = WorkoutSessionCompletionDataFactory.applyingServerSummary(
                    summary,
                    to: localData
                )
                await loadWorkoutReward()
                clearServerActionError()
                return true
            }

            failServerAction(.completeWorkout, error: completionError)
            return false
        }
    }

    private func isValidCompletedSummary(_ summary: WorkoutSummaryResponse) -> Bool {
        summary.duration >= 0
            && summary.totalSets >= 0
            && summary.volume.isFinite
            && summary.volume >= 0
            && summary.experiencePoints >= 0
    }

    @discardableResult
    func loadWorkoutReward() async -> Bool {
        guard !isLoadingReward,
              let rewardService,
              let serverWorkoutID else { return false }
        isLoadingReward = true
        rewardErrorMessage = nil
        defer { isLoadingReward = false }

        do {
            let response = try await rewardService.fetch(workoutId: serverWorkoutID)
            guard response.workoutId == serverWorkoutID,
                  response.xp >= 0,
                  response.growthDelta >= 0,
                  !response.grantedAt.isEmpty else {
                throw APIClientError.invalidResponse
            }
            guard let currentData = serverCompletionData ?? completionData else {
                throw APIClientError.invalidResponse
            }
            serverCompletionData = WorkoutSessionCompletionDataFactory.applyingServerReward(
                response,
                to: currentData
            )
            return true
        } catch is CancellationError {
            return false
        } catch {
            if case let APIClientError.server(_, detail) = error {
                rewardErrorMessage = detail.message
            } else {
                rewardErrorMessage = "운동 보상 정보를 불러오지 못했어요. 다시 시도해 주세요."
            }
            return false
        }
    }

    func updateServerWorkoutVersion(from responseVersion: Int?) throws {
        guard let responseVersion else {
            if serverWorkoutVersion != nil { throw APIClientError.invalidResponse }
            return
        }
        guard responseVersion > 0 else { throw APIClientError.invalidResponse }
        if let serverWorkoutVersion {
            guard responseVersion == serverWorkoutVersion + 1 else {
                throw APIClientError.invalidResponse
            }
        }
        serverWorkoutVersion = responseVersion
    }

    private static func iso8601String(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}

struct PendingWorkoutCompletion: Equatable {
    let workoutID: String
    let request: CompleteWorkoutRequest
    let completedAt: Date
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
            let response = try await previousRecordService.fetchPreviousRecord(for: exerciseID)
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

extension WorkoutSessionViewModel {
    func loadNextSetPreview() async {
        guard !isLoadingNextSetPreview,
              isServerManagedRest,
              let workoutID = serverWorkoutID,
              let nextSetService,
              let exercise = currentExercise,
              exercise.measure == .repetitions,
              let localSetIndex = currentSetIndex else { return }

        let expectedSetIndex = localSetIndex + 1
        isLoadingNextSetPreview = true
        nextSetPreview = nil
        nextSetPreviewError = nil
        defer { isLoadingNextSetPreview = false }

        do {
            let response = try await nextSetService.nextSet(workoutId: workoutID)
            guard isCurrentNextSetRequest(
                workoutID: workoutID,
                exerciseID: exercise.id,
                setIndex: localSetIndex
            ) else { return }
            guard response.exerciseId == exercise.id,
                  response.setIndex == expectedSetIndex,
                  !response.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  response.weight.isFinite,
                  response.weight >= 0,
                  response.reps >= 0 else {
                throw APIClientError.invalidResponse
            }

            nextSetPreview = response
        } catch {
            guard !Task.isCancelled,
                  isCurrentNextSetRequest(
                    workoutID: workoutID,
                    exerciseID: exercise.id,
                    setIndex: localSetIndex
                  ) else { return }
            nextSetPreviewError = Self.nextSetPreviewMessage(for: error)
        }
    }

    private func isCurrentNextSetRequest(workoutID: String, exerciseID: String, setIndex: Int) -> Bool {
        serverWorkoutID == workoutID &&
            isServerManagedRest &&
            currentExercise?.id == exerciseID &&
            currentSetIndex == setIndex
    }

    private static func nextSetPreviewMessage(for error: Error) -> String {
        if let apiError = error as? APIClientError,
           case let .server(_, detail) = apiError {
            return detail.message
        }
        return "다음 세트 정보를 불러오지 못했어요."
    }
}
