import ActivityKit
import Foundation

@MainActor
final class WorkoutRestActivityController {
    static let shared = WorkoutRestActivityController()

    func startOrUpdate(sessionID: String, state: WorkoutRestActivityAttributes.ContentState) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if let activity = Activity<WorkoutRestActivityAttributes>.activities.first(
            where: { $0.attributes.sessionID == sessionID }
        ) {
            await activity.update(ActivityContent(state: state, staleDate: state.restEndsAt))
            return
        }

        let attributes = WorkoutRestActivityAttributes(sessionID: sessionID)
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: state.restEndsAt),
                pushType: nil
            )
        } catch {
            // Live Activities are optional; the in-app rest timer remains available.
        }
    }

    func end(sessionID: String) async {
        guard let activity = Activity<WorkoutRestActivityAttributes>.activities.first(
            where: { $0.attributes.sessionID == sessionID }
        ) else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
    }

    func currentState(sessionID: String) -> WorkoutRestActivityAttributes.ContentState? {
        Activity<WorkoutRestActivityAttributes>.activities.first(
            where: { $0.attributes.sessionID == sessionID }
        )?.content.state
    }
}
