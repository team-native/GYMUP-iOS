import ActivityKit
import Foundation

struct WorkoutRestActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var restStartedAt: Date
        var restEndsAt: Date
        var restDurationSeconds: Int
        var routineName: String
        var exerciseName: String
        var exerciseIndex: Int
        var totalExerciseCount: Int
        var completedSetCount: Int
        var nextSetNumber: Int
        var nextSetWeightKilograms: Double
        var nextSetRepetitions: Int
        var isSkipped: Bool
    }

    var sessionID: String
}
