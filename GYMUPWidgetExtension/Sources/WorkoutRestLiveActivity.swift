import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct WorkoutRestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutRestActivityAttributes.self) { context in
            WorkoutRestLockScreenView(state: context.state, activityID: context.attributes.sessionID)
                .activityBackgroundTint(Color(red: 11 / 255, green: 11 / 255, blue: 13 / 255))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("REST")
                        .font(.custom("Archivo-SemiBold", size: 10))
                        .foregroundStyle(WorkoutLiveColors.brand)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.exerciseIndex) / \(context.state.totalExerciseCount)")
                        .font(.custom("GothicA1-Medium", size: 11))
                        .foregroundStyle(WorkoutLiveColors.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(timerInterval: context.state.restStartedAt...context.state.restEndsAt, countsDown: true, showsHours: false)
                        .font(.custom("BarlowCondensed-Bold", size: 24))
                        .foregroundStyle(WorkoutLiveColors.primary)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.exerciseName)
                            .font(.custom("GothicA1-Medium", size: 12))
                            .foregroundStyle(WorkoutLiveColors.secondary)
                        Spacer()
                        Text(nextSetText(context.state))
                            .font(.custom("BarlowCondensed-ExtraBold", size: 15))
                            .foregroundStyle(WorkoutLiveColors.primary)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WorkoutLiveColors.brand)
            } compactTrailing: {
                Text(timerInterval: context.state.restStartedAt...context.state.restEndsAt, countsDown: true, showsHours: false)
                    .font(.custom("BarlowCondensed-Bold", size: 13))
                    .foregroundStyle(WorkoutLiveColors.brandText)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WorkoutLiveColors.brand)
            }
            .keylineTint(WorkoutLiveColors.brand)
        }
    }
}

private struct WorkoutRestLockScreenView: View {
    let state: WorkoutRestActivityAttributes.ContentState
    let activityID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REST · \(state.routineName)")
                    .font(.custom("Archivo-SemiBold", size: 10))
                    .tracking(0.17)
                    .foregroundStyle(WorkoutLiveColors.brandText)
                Spacer()
                Text("\(state.exerciseIndex) / \(state.totalExerciseCount)")
                    .font(.custom("GothicA1-Medium", size: 11))
                    .foregroundStyle(WorkoutLiveColors.secondary)
            }

            HStack(alignment: .bottom) {
                Text(timerInterval: state.restStartedAt...state.restEndsAt, countsDown: true, showsHours: false)
                    .font(.custom("BarlowCondensed-Black", size: 40))
                    .foregroundStyle(WorkoutLiveColors.primary)
                    .monospacedDigit()
                    .frame(width: 105, alignment: .leading)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("NEXT")
                        .font(.custom("Archivo-SemiBold", size: 10))
                        .tracking(0.17)
                        .foregroundStyle(WorkoutLiveColors.secondary)
                    Text(nextSetText(state))
                        .font(.custom("BarlowCondensed-ExtraBold", size: 18))
                        .foregroundStyle(WorkoutLiveColors.primary)
                }
            }

            ProgressView(timerInterval: state.restStartedAt...state.restEndsAt, countsDown: false)
                .tint(WorkoutLiveColors.brand)

            HStack(spacing: 8) {
                Button(intent: WorkoutRestTimerIntent(activityID: activityID, shouldSkip: false)) {
                    Text("+15초")
                        .font(.custom("GothicA1-Bold", size: 13))
                        .foregroundStyle(WorkoutLiveColors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(WorkoutLiveColors.elevated, in: Capsule())
                }
                .disabled(state.restDurationSeconds >= 600)
                Button(intent: WorkoutRestTimerIntent(activityID: activityID, shouldSkip: true)) {
                    Text("건너뛰기")
                        .font(.custom("GothicA1-Bold", size: 13))
                        .foregroundStyle(WorkoutLiveColors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .overlay(Capsule().strokeBorder(WorkoutLiveColors.border, lineWidth: 1.5))
                }
            }
        }
        .padding(18)
        .background(WorkoutLiveColors.canvas.opacity(0.94), in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct WorkoutRestTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "운동 휴식 타이머 조정"
    static var openAppWhenRun = false

    @Parameter(title: "활동 식별자") var activityID: String
    @Parameter(title: "휴식 건너뛰기") var shouldSkip: Bool

    init() {
        activityID = ""
        shouldSkip = false
    }

    init(activityID: String, shouldSkip: Bool) {
        self.activityID = activityID
        self.shouldSkip = shouldSkip
    }

    func perform() async throws -> some IntentResult {
        guard let activity = Activity<WorkoutRestActivityAttributes>.activities.first(
            where: { $0.attributes.sessionID == activityID }
        ) else { return .result() }

        var state = activity.content.state
        if shouldSkip {
            state.restEndsAt = .now
            state.isSkipped = true
            await activity.update(ActivityContent(state: state, staleDate: .now))
        } else {
            let updatedDuration = min(state.restDurationSeconds + 15, 600)
            let addedSeconds = updatedDuration - state.restDurationSeconds
            guard addedSeconds > 0 else { return .result() }
            state.restEndsAt = state.restEndsAt.addingTimeInterval(TimeInterval(addedSeconds))
            state.restDurationSeconds = updatedDuration
            await activity.update(ActivityContent(state: state, staleDate: state.restEndsAt))
        }
        return .result()
    }
}

private enum WorkoutLiveColors {
    static let canvas = Color(red: 11 / 255, green: 11 / 255, blue: 13 / 255)
    static let elevated = Color(red: 31 / 255, green: 31 / 255, blue: 36 / 255)
    static let border = Color(red: 58 / 255, green: 58 / 255, blue: 66 / 255)
    static let primary = Color.white
    static let secondary = Color(red: 161 / 255, green: 161 / 255, blue: 170 / 255)
    static let brand = Color(red: 1, green: 0.07, blue: 0.09)
    static let brandText = Color(red: 1, green: 0.42, blue: 0.43)
}

private func nextSetText(_ state: WorkoutRestActivityAttributes.ContentState) -> String {
    let weight = state.nextSetWeightKilograms.formatted(.number.precision(.fractionLength(0...1)))
    let unit = state.nextSetIsTimed == true ? "초" : ""
    return "\(weight) KG × \(state.nextSetRepetitions)\(unit)"
}
