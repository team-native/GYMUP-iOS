import Foundation

enum WorkoutSessionCompletionDataFactory {
    static func make(
        plan: WorkoutSessionPlan,
        elapsedSeconds: Int,
        completedAt: Date
    ) -> WorkoutCompletionData {
        let completedSets = plan.exercises.flatMap(\.sets).filter(\.isCompleted)
        let volume = completedSets.reduce(0.0) { $0 + ($1.weightKilograms * Double($1.repetitions)) }
        let minutes = max(0, Int(ceil(Double(max(0, elapsedSeconds)) / 60)))
        let sampleProgress = WorkoutCompletionData.sample
        let personalRecordCount = plan.exercises.filter { $0.personalRecordSet != nil }.count
        let workoutXP = completedSets.count * 20
        let routineBonus = !plan.exercises.isEmpty && plan.exercises.allSatisfy(\.isComplete) ? 100 : 0
        let personalRecordBonus = personalRecordCount * 25
        let weeklyGoalBonus = sampleProgress.weeklyWorkoutCount >= sampleProgress.weeklyWorkoutGoal ? 30 : 0
        let experienceBreakdown = [
            WorkoutCompletionExperienceItem(title: "운동 완료", amount: workoutXP),
            WorkoutCompletionExperienceItem(title: "루틴 100% 완료", amount: routineBonus),
            WorkoutCompletionExperienceItem(title: "PR \(personalRecordCount)개", amount: personalRecordBonus),
            WorkoutCompletionExperienceItem(title: "주간 목표 달성", amount: weeklyGoalBonus)
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
            previousGrowth: sampleProgress.previousGrowth,
            growth: sampleProgress.growth,
            earnedXP: earnedXP,
            experienceBreakdown: experienceBreakdown,
            weeklyWorkoutCount: sampleProgress.weeklyWorkoutCount,
            weeklyWorkoutGoal: sampleProgress.weeklyWorkoutGoal,
            streakWeeks: sampleProgress.streakWeeks,
            levelReward: sampleProgress.levelReward,
            stageReward: sampleProgress.stageReward,
            peakReward: sampleProgress.peakReward,
            exerciseDetails: exerciseDetails(from: plan.exercises)
        )
    }

    static func makeHistoryRecord(
        plan: WorkoutSessionPlan,
        elapsedSeconds: Int,
        completedAt: Date
    ) -> WorkoutRecord {
        let completedSets = plan.exercises.flatMap(\.sets).filter(\.isCompleted)
        let volume = completedSets.reduce(0.0) { $0 + ($1.weightKilograms * Double($1.repetitions)) }
        let exercises = plan.exercises.enumerated().compactMap { exerciseIndex, exercise -> WorkoutExerciseRecord? in
            let personalRecordSetID = exercise.personalRecordSet?.id
            let sets = exercise.sets.enumerated().compactMap { setIndex, set -> WorkoutSetRecord? in
                guard set.isCompleted else { return nil }
                return WorkoutSetRecord(
                    id: setIndex + 1,
                    weight: set.weightKilograms,
                    repetitions: set.repetitions,
                    isPersonalRecord: set.id == personalRecordSetID
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
            exercises: exercises
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
