import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class WorkoutSettings {
    static let shared: WorkoutSettings = {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitest-reset-settings") {
            ["workout.restSeconds", "workout.notifications", "workout.reminder"].forEach {
                UserDefaults.standard.removeObject(forKey: $0)
            }
        }
#endif
        return WorkoutSettings()
    }()
    private let defaults: UserDefaults
    private let schedulesNotifications: Bool
    var restSeconds: Int { didSet { save() } }
    var preferences: ProfileNotificationPreferences { didSet { save() } }
    var schedule: ProfileReminderSchedule { didSet { save() } }

    init(defaults: UserDefaults = .standard, schedulesNotifications: Bool = true) {
        self.defaults = defaults
        self.schedulesNotifications = schedulesNotifications
        let storedRest = defaults.integer(forKey: "workout.restSeconds")
        restSeconds = (15...300).contains(storedRest) ? storedRest : 90
        preferences = defaults.data(forKey: "workout.notifications")
            .flatMap { try? JSONDecoder().decode(ProfileNotificationPreferences.self, from: $0) }
            ?? ProfileNotificationPreferences()
        schedule = defaults.data(forKey: "workout.reminder")
            .flatMap { try? JSONDecoder().decode(ProfileReminderSchedule.self, from: $0) }
            ?? ProfileReminderSchedule()
    }

    private func save() {
        defaults.set(restSeconds, forKey: "workout.restSeconds")
        defaults.set(try? JSONEncoder().encode(preferences), forKey: "workout.notifications")
        defaults.set(try? JSONEncoder().encode(schedule), forKey: "workout.reminder")
        if schedulesNotifications { Task { await refreshReminders() } }
    }

    static func reminderComponents(schedule: ProfileReminderSchedule) -> [DateComponents] {
        let time = Calendar.current.dateComponents([.hour, .minute], from: schedule.time)
        return ProfileReminderSchedule.weekdayOrder.filter(schedule.weekdays.contains).map { weekday in
            DateComponents(hour: time.hour, minute: time.minute, weekday: weekday)
        }
    }

    func cancelRestNotification(sessionID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["workout.rest.\(sessionID)"])
    }

    func scheduleRestNotification(sessionID: String, endsAt: Date) {
        cancelRestNotification(sessionID: sessionID)
        guard preferences.restTimerEnabled, endsAt.timeIntervalSinceNow > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "휴식 시간이 끝났어요"
        content.body = "준비가 되면 다음 세트를 시작해 주세요."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "workout.rest.\(sessionID)", content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(endsAt.timeIntervalSinceNow, 1), repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func refreshReminders() async {
        let center = UNUserNotificationCenter.current()
        let identifiers = (1...7).map { "workout.reminder.\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        guard preferences.workoutReminderEnabled else { return }
        let authorization = await center.notificationSettings().authorizationStatus
        guard authorization == .authorized || authorization == .provisional || authorization == .ephemeral else { return }
        for components in Self.reminderComponents(schedule: schedule) {
            let content = UNMutableNotificationContent()
            content.title = "오늘도 한 단계 위로"
            content.body = "오늘의 운동을 시작해 볼까요?"
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "workout.reminder.\(components.weekday ?? 0)", content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            )
            try? await center.add(request)
        }
    }
}
