import Foundation

@MainActor
struct WorkoutCompletionProgressContext {
    let historyStore: HistoryStore
    let goalSettings: OnboardingStoredSettings?
}

private struct WorkoutCompletionProgress {
    let previousGrowth: Int
    let growth: Int
    let weeklyWorkoutCount: Int
    let weeklyWorkoutGoal: Int
    let streakWeeks: Int
    let weeklyGoalBonus: Int
    let stageReward: WorkoutCompletionData.StageReward?
    let peakReward: WorkoutCompletionData.PeakReward?
}

private struct WorkoutCompletionWeeklyProgress {
    let count: Int
    let goal: Int
    let streakWeeks: Int
    let bonus: Int
}

private struct WorkoutCompletionPeakUnlockContext {
    let settings: OnboardingStoredSettings?
    let records: [WorkoutRecord]
    let streakWeeks: Int
    let peakWeight: Int
    let completedAt: Date
}

enum WorkoutSessionCompletionDataFactory {
    @MainActor
    static func make(
        plan: WorkoutSessionPlan,
        elapsedSeconds: Int,
        completedAt: Date,
        context: WorkoutCompletionProgressContext
    ) -> WorkoutCompletionData {
        let completedSets = plan.exercises.flatMap(\.sets).filter(\.isCompleted)
        let volume = plan.exercises.reduce(0.0) { $0 + $1.completedVolumeKilograms }
        let minutes = max(0, Int(ceil(Double(max(0, elapsedSeconds)) / 60)))
        let currentRecord = makeHistoryRecord(plan: plan, elapsedSeconds: elapsedSeconds, completedAt: completedAt)
        let progress = progressAfterWorkout(
            currentRecord: currentRecord,
            context: context,
            completedAt: completedAt
        )
        let personalRecordCount = plan.exercises.filter { $0.personalRecordSet != nil }.count
        let workoutXP = completedSets.count * 20
        let routineBonus = !plan.exercises.isEmpty && plan.exercises.allSatisfy(\.isComplete) ? 100 : 0
        let personalRecordBonus = personalRecordCount * 25
        let experienceBreakdown = [
            WorkoutCompletionExperienceItem(title: "운동 완료", amount: workoutXP),
            WorkoutCompletionExperienceItem(title: "루틴 100% 완료", amount: routineBonus),
            WorkoutCompletionExperienceItem(title: "PR \(personalRecordCount)개", amount: personalRecordBonus),
            WorkoutCompletionExperienceItem(title: "주간 목표 달성", amount: progress.weeklyGoalBonus)
        ].filter { $0.amount > 0 }
        let earnedXP = experienceBreakdown.reduce(0) { $0 + $1.amount }

        return WorkoutCompletionData(
            routineName: plan.name,
            completedAt: dateDescription(completedAt, elapsedSeconds: elapsedSeconds),
            metrics: [
                .init(title: "TIME", value: String(minutes), unit: "MIN"),
                .init(title: "SETS", value: String(completedSets.count), unit: "SETS"),
                .init(title: "VOLUME", value: formattedVolume(volume), unit: "KG"),
                .init(title: "PERSONAL RECORD", value: String(personalRecordCount), unit: "PR")
            ],
            previousGrowth: progress.previousGrowth,
            growth: progress.growth,
            earnedXP: earnedXP,
            experienceBreakdown: experienceBreakdown,
            weeklyWorkoutCount: progress.weeklyWorkoutCount,
            weeklyWorkoutGoal: progress.weeklyWorkoutGoal,
            streakWeeks: progress.streakWeeks,
            levelReward: nil,
            stageReward: progress.stageReward,
            peakReward: progress.peakReward,
            exerciseDetails: exerciseDetails(from: plan.exercises)
        )
    }

    @MainActor
    private static func progressAfterWorkout(
        currentRecord: WorkoutRecord,
        context: WorkoutCompletionProgressContext,
        completedAt: Date
    ) -> WorkoutCompletionProgress {
        let previous = GrowthViewModel(
            historyStore: context.historyStore,
            goalSettings: context.goalSettings,
            now: completedAt
        )
        let recordsAfterWorkout = currentRecord.setCount > 0
            ? context.historyStore.records + [currentRecord]
            : context.historyStore.records
        let updatedStore = HistoryStore(records: recordsAfterWorkout)
        let current = GrowthViewModel(historyStore: updatedStore, goalSettings: context.goalSettings, now: completedAt)
        let weekly = weeklyProgress(
            previousRecords: context.historyStore.records,
            records: updatedStore.records,
            goal: context.goalSettings?.frequency ?? 0,
            at: completedAt
        )
        let stageReward = stageTransition(from: previous.currentStage, to: current.currentStage)
        let peakReward = peakUnlock(
            from: previous.growth,
            to: current.growth,
            context: WorkoutCompletionPeakUnlockContext(
                settings: context.goalSettings,
                records: updatedStore.records,
                streakWeeks: weekly.streakWeeks,
                peakWeight: current.currentStage.weight,
                completedAt: completedAt
            )
        )
        return WorkoutCompletionProgress(
            previousGrowth: previous.growth,
            growth: current.growth,
            weeklyWorkoutCount: weekly.count,
            weeklyWorkoutGoal: weekly.goal,
            streakWeeks: weekly.streakWeeks,
            weeklyGoalBonus: weekly.bonus,
            stageReward: stageReward,
            peakReward: peakReward
        )
    }

    private static func weeklyProgress(
        previousRecords: [WorkoutRecord],
        records: [WorkoutRecord],
        goal: Int,
        at date: Date
    ) -> WorkoutCompletionWeeklyProgress {
        let currentWeekRecords = records.filter { isInWeek($0.date, of: date) && $0.date <= date }
        let previousWeekCount = previousRecords.filter { isInWeek($0.date, of: date) && $0.date <= date }.count
        return WorkoutCompletionWeeklyProgress(
            count: currentWeekRecords.count,
            goal: goal,
            streakWeeks: currentStreakWeeks(records: records, goal: goal, at: date),
            bonus: goal > 0 && previousWeekCount < goal && currentWeekRecords.count >= goal ? 30 : 0
        )
    }

    private static func isInWeek(_ recordDate: Date, of date: Date) -> Bool {
        Calendar.current.isDate(recordDate, equalTo: date, toGranularity: .weekOfYear)
    }

    static func currentStreakWeeks(records: [WorkoutRecord], goal: Int, at date: Date) -> Int {
        guard goal > 0, let currentWeek = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return 0 }
        var weekStart = currentWeek.start
        var streak = 0
        let currentWeekCount = records.filter { $0.date <= date && $0.date >= currentWeek.start && $0.date < currentWeek.end }.count
        if currentWeekCount < goal {
            guard let previousWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { return 0 }
            weekStart = previousWeek
        }

        while true {
            let weekEnd = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? date
            let completed = records.filter { $0.date <= date && $0.date >= weekStart && $0.date < weekEnd }.count
            guard completed >= goal else { return streak }
            streak += 1
            guard let previousWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { return streak }
            weekStart = previousWeek
        }
    }

    private static func stageTransition(
        from previous: GrowthStage,
        to current: GrowthStage
    ) -> WorkoutCompletionData.StageReward? {
        guard current.weight > previous.weight,
              let stage = ["EMPTY BAR", "WARM-UP", "WORKING", "STRONG", "HEAVY", "PEAK"].firstIndex(of: current.title) else {
            return nil
        }
        return WorkoutCompletionData.StageReward(
            previousWeight: previous.weight,
            weight: current.weight,
            stage: stage + 1,
            plateWeight: (current.weight - previous.weight) / 2
        )
    }

    private static func peakUnlock(
        from previousGrowth: Int,
        to currentGrowth: Int,
        context: WorkoutCompletionPeakUnlockContext
    ) -> WorkoutCompletionData.PeakReward? {
        guard let settings = context.settings, previousGrowth < 100, currentGrowth == 100 else { return nil }
        let goalStart = settings.goalStartedAt ?? context.records.map(\.date).min() ?? .now
        let goalEnd = Calendar.current.date(byAdding: .weekOfYear, value: settings.weeks, to: goalStart) ?? .distantFuture
        let goalWorkoutCount = context.records.filter {
            $0.date >= goalStart && $0.date <= goalEnd && $0.date <= context.completedAt
        }.count
        return WorkoutCompletionData.PeakReward(
            goalGrowth: currentGrowth,
            durationWeeks: settings.weeks,
            workoutCount: goalWorkoutCount,
            longestStreakWeeks: context.streakWeeks,
            fullyLoadedWeight: context.peakWeight,
            rewardXP: 1_000
        )
    }

    static func makeHistoryRecord(
        plan: WorkoutSessionPlan,
        elapsedSeconds: Int,
        completedAt: Date
    ) -> WorkoutRecord {
        let completedSets = plan.exercises.flatMap(\.sets).filter(\.isCompleted)
        let volume = plan.exercises.reduce(0.0) { $0 + $1.completedVolumeKilograms }
        let exercises = plan.exercises.enumerated().compactMap { exerciseIndex, exercise -> WorkoutExerciseRecord? in
            let personalRecordSetID = exercise.personalRecordSet?.id
            let sets = exercise.sets.enumerated().compactMap { setIndex, set -> WorkoutSetRecord? in
                guard set.isCompleted else { return nil }
                return WorkoutSetRecord(
                    id: setIndex + 1,
                    weight: set.weightKilograms,
                    repetitions: set.repetitions,
                    isPersonalRecord: set.id == personalRecordSetID,
                    measure: exercise.measure
                )
            }
            guard !sets.isEmpty else { return nil }
            return WorkoutExerciseRecord(id: exerciseIndex + 1, name: exercise.name, sets: sets)
        }
        var seenCategories = Set<String>()
        let category = plan.exercises.compactMap { exercise -> String? in
            seenCategories.insert(exercise.target).inserted ? exercise.target : nil
        }.joined(separator: " · ")

        return WorkoutRecord(
            id: UUID(),
            date: completedAt,
            routineName: plan.title,
            category: category,
            durationMinutes: max(0, Int(ceil(Double(max(0, elapsedSeconds)) / 60))),
            setCount: completedSets.count,
            volumeKilograms: Int(volume.rounded()),
            growth: plan.exercises.filter { $0.personalRecordSet != nil }.count,
            photoAssetName: plan.exercises.first?.imageAssetName ?? "H1RoutinePhoto",
            exercises: exercises,
            routineCompleted: !plan.exercises.isEmpty && plan.exercises.allSatisfy(\.isComplete)
        )
    }

    private static func exerciseDetails(
        from exercises: [WorkoutSessionExercise]
    ) -> [WorkoutCompletionExerciseDetail] {
        exercises.compactMap { exercise -> WorkoutCompletionExerciseDetail? in
            let completed = exercise.sets.enumerated().compactMap { index, set -> WorkoutCompletionSetDetail? in
                guard set.isCompleted else { return nil }
                return WorkoutCompletionSetDetail(
                    id: "\(exercise.id)-\(index + 1)",
                    number: index + 1,
                    weightKilograms: set.weightKilograms,
                    repetitions: set.repetitions
                )
            }
            guard !completed.isEmpty else { return nil }
            return WorkoutCompletionExerciseDetail(
                id: exercise.id,
                name: exercise.name,
                sets: completed
            )
        }
    }

    private static func dateDescription(_ date: Date, elapsedSeconds: Int) -> String {
        let startDate = date.addingTimeInterval(-TimeInterval(max(0, elapsedSeconds)))
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M월 d일 EEE"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ko_KR")
        timeFormatter.dateFormat = "HH:mm"

        return "\(dateFormatter.string(from: date)) · \(timeFormatter.string(from: startDate)) - \(timeFormatter.string(from: date))"
    }

    private static func formattedVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: volume)) ?? String(Int(volume))
    }
}
