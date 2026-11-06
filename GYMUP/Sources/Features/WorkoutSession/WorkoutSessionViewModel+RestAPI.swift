import Foundation

extension WorkoutSessionViewModel {
    func startPendingRest() async -> Bool {
        guard let pendingRestStart else { return false }
        guard let progressService else {
            failServerAction(.startRest, error: APIClientError.invalidBaseURL)
            return false
        }

        do {
            let response = try await progressService.startRest(
                workoutId: pendingRestStart.workoutID,
                request: pendingRestStart.request
            )
            try applyStartedRest(response, at: Date())
            self.pendingRestStart = nil
            clearServerActionError()
            return true
        } catch {
            failServerAction(.startRest, error: error)
            return false
        }
    }

    func reconcilePendingRestStart() async -> Bool {
        guard let pendingRestStart else { return false }
        guard let progressService else {
            failServerAction(.startRest, error: APIClientError.invalidBaseURL)
            return false
        }

        isSubmittingWorkoutAction = true
        clearServerActionError()
        defer { isSubmittingWorkoutAction = false }

        if let currentRest = try? await progressService.currentRest(workoutId: pendingRestStart.workoutID),
           let isActive = try? applyCurrentRest(currentRest, at: Date()) {
            self.pendingRestStart = nil
            clearServerActionError()
            return isActive || currentRest.remainingSeconds == 0 || currentRest.status.uppercased() == "SKIPPED"
        }

        // A failed lookup cannot establish whether the first POST took effect.
        // The user explicitly chose retry, so retry this exact rest request without resubmitting its set.
        return await startPendingRest()
    }

    func skipPendingRestStart() -> Bool {
        guard pendingRestStart != nil else { return false }
        pendingRestStart = nil
        skipRest()
        clearServerActionError()
        return true
    }

    func requestServerRestSkip() async -> Bool {
        guard isServerManagedRest else {
            skipRest()
            return true
        }
        guard let serverWorkoutID, let progressService else {
            failServerAction(.skipRest, error: APIClientError.invalidBaseURL)
            return false
        }
        guard !isSubmittingWorkoutAction else { return false }

        isSubmittingWorkoutAction = true
        clearServerActionError()
        defer { isSubmittingWorkoutAction = false }

        do {
            let response = try await progressService.skipCurrentRest(workoutId: serverWorkoutID)
            guard response.status == .skipped else { throw APIClientError.invalidResponse }
            skipRest()
            clearServerActionError()
            return true
        } catch {
            failServerAction(.skipRest, error: error)
            return false
        }
    }

    func requestServerRestExtension(by seconds: Int) async -> Bool {
        guard isResting, seconds > 0 else { return false }
        guard isServerManagedRest else {
            extendRest(by: seconds)
            return true
        }
        guard let serverWorkoutID, let progressService else {
            failServerAction(.extendRest(seconds: seconds), error: APIClientError.invalidBaseURL)
            return false
        }
        guard !isSubmittingWorkoutAction else { return false }

        isSubmittingWorkoutAction = true
        clearServerActionError()
        defer { isSubmittingWorkoutAction = false }

        do {
            let response = try await progressService.extendCurrentRest(workoutId: serverWorkoutID, by: seconds)
            guard !response.restId.isEmpty,
                  response.remainingSeconds >= 0,
                  let endDate = Self.parseServerDate(response.endsAt) else {
                throw APIClientError.invalidResponse
            }

            let elapsedSeconds = max(0, activeRestDurationSeconds - restSecondsRemaining)
            activeRestDurationSeconds = min(max(elapsedSeconds + response.remainingSeconds, 0), 600)
            restEndsAt = endDate
            _ = refreshClock(at: Date())
            clearServerActionError()
            return true
        } catch {
            failServerAction(.extendRest(seconds: seconds), error: error)
            return false
        }
    }

    func refreshActiveServerRest(at date: Date) async -> Bool {
        guard isServerManagedRest else {
            clearServerActionError()
            return true
        }
        guard !isPaused else { return false }
        guard let restEndsAt, restEndsAt > date else {
            _ = refreshClock(at: date)
            clearServerActionError()
            return true
        }
        guard let serverWorkoutID, let progressService else { return false }
        guard !isSubmittingWorkoutAction else { return false }

        isSubmittingWorkoutAction = true
        clearServerActionError()
        defer { isSubmittingWorkoutAction = false }

        do {
            let response = try await progressService.currentRest(workoutId: serverWorkoutID)
            _ = try applyCurrentRest(response, at: date)
            clearServerActionError()
            return true
        } catch {
            failServerAction(.refreshRest, error: error)
            return false
        }
    }

    private func applyStartedRest(_ response: StartRestResponse, at date: Date) throws {
        guard !response.restId.isEmpty,
              response.durationSeconds >= 0,
              let startedAt = Self.parseServerDate(response.startedAt),
              let endsAt = Self.parseServerDate(response.endsAt),
              endsAt >= startedAt else {
            throw APIClientError.invalidResponse
        }

        _ = refreshClock(at: date)
        activeRestDurationSeconds = min(max(response.durationSeconds, 0), 600)
        restEndsAt = endsAt
        isServerManagedRest = true
    }

    @discardableResult
    private func applyCurrentRest(_ response: CurrentRestResponse, at date: Date) throws -> Bool {
        guard !response.restId.isEmpty,
              response.remainingSeconds >= 0,
              let startedAt = Self.parseServerDate(response.startedAt),
              let endsAt = Self.parseServerDate(response.endsAt),
              endsAt >= startedAt else {
            throw APIClientError.invalidResponse
        }

        guard response.remainingSeconds > 0, response.status.uppercased() != "SKIPPED" else {
            skipRest()
            return false
        }

        _ = refreshClock(at: date)
        activeRestDurationSeconds = min(max(Int(endsAt.timeIntervalSince(startedAt)), 0), 600)
        restEndsAt = endsAt
        isServerManagedRest = true
        return true
    }

    private static func parseServerDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }
}
