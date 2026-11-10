import Foundation

extension WorkoutSessionViewModel {
    func makeLocalCompletionData(at completedAt: Date) -> WorkoutCompletionData {
        return WorkoutSessionCompletionDataFactory.make(
            plan: plan,
            elapsedSeconds: elapsedSeconds(at: completedAt),
            completedAt: completedAt,
            context: WorkoutCompletionProgressContext(historyStore: historyStore, goalSettings: goalSettings)
        )
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
              let pendingCompletion = makePendingCompletion(workoutID: serverWorkoutID, at: date) else {
            failServerAction(.completeWorkout, error: APIClientError.invalidResponse)
            return false
        }
        guard !isSubmittingWorkoutAction else { return false }

        pendingWorkoutCompletion = pendingCompletion
        isSubmittingWorkoutAction = true
        clearServerActionError()
        defer { isSubmittingWorkoutAction = false }

        do {
            try await submitServerCompletion(pendingCompletion, service: completionService)
            return true
        } catch {
            return await recoverServerCompletion(
                pendingCompletion,
                workoutID: serverWorkoutID,
                service: completionService,
                error: error
            )
        }
    }

    private func makePendingCompletion(workoutID: String, at date: Date) -> PendingWorkoutCompletion? {
        guard let serverWorkoutVersion, serverWorkoutVersion > 0 else { return nil }
        let pending = pendingWorkoutCompletion ?? PendingWorkoutCompletion(
            workoutID: workoutID,
            request: CompleteWorkoutRequest(
                endedAt: Self.iso8601String(from: date),
                expectedVersion: serverWorkoutVersion
            ),
            completedAt: date
        )
        guard pending.workoutID == workoutID,
              pending.request.expectedVersion == serverWorkoutVersion else { return nil }
        return pending
    }

    private func submitServerCompletion(
        _ pending: PendingWorkoutCompletion,
        service: WorkoutCompletionProcessing
    ) async throws {
        let response = try await service.complete(workoutId: pending.workoutID, request: pending.request)
        guard isValidCompletion(response, workoutID: pending.workoutID) else {
            throw APIClientError.invalidResponse
        }

        let summary = try? await service.summary(workoutId: pending.workoutID)
        pendingWorkoutCompletion = nil
        finish(at: pending.completedAt)
        let localData = makeLocalCompletionData(at: pending.completedAt)
        serverCompletionData = WorkoutSessionCompletionDataFactory.applyingServerCompletion(response, to: localData)
        if let summary, isValidCompletedSummary(summary) {
            serverCompletionData = WorkoutSessionCompletionDataFactory.applyingServerSummary(summary, to: localData)
        }
        await loadWorkoutReward()
        clearServerActionError()
    }

    private func recoverServerCompletion(
        _ pending: PendingWorkoutCompletion,
        workoutID: String,
        service: WorkoutCompletionProcessing,
        error: Error
    ) async -> Bool {
        if let summary = try? await service.summary(workoutId: workoutID), isValidCompletedSummary(summary) {
            pendingWorkoutCompletion = nil
            finish(at: pending.completedAt)
            let localData = makeLocalCompletionData(at: pending.completedAt)
            serverCompletionData = WorkoutSessionCompletionDataFactory.applyingServerSummary(summary, to: localData)
            await loadWorkoutReward()
            clearServerActionError()
            return true
        }
        failServerAction(.completeWorkout, error: error)
        return false
    }

    private func isValidCompletion(_ response: CompleteWorkoutResponse, workoutID: String) -> Bool {
        response.workoutId == workoutID
            && response.status == .completed
            && response.duration >= 0
            && response.totalSets >= 0
            && response.volume.isFinite
            && response.volume >= 0
            && response.experiencePoints >= 0
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
                  response.experiencePoints >= 0,
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
