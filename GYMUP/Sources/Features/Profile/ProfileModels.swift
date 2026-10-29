import Foundation

struct ProfileSummary {
    let level: Int
    let stage: String
    let focus: String
    let workoutsPerWeek: Int
    let currentGoal: String
    let goalDurationWeeks: Int
    let restTimeSummary: String
    let notificationSummary: String
    let photoPermissionSummary: String
}

enum ProfileSampleData {
    static let summary = ProfileSummary(
        level: 17,
        stage: "HEAVY",
        focus: "입문 · 근비대",
        workoutsPerWeek: 3,
        currentGoal: "체형",
        goalDurationWeeks: 12,
        restTimeSummary: "1:30",
        notificationSummary: "휴식 종료 · 햅틱 · 리마인더",
        photoPermissionSummary: "오운완 사진 촬영 · 저장"
    )

    static let goalHistory = [
        ProfileGoalRecord(
            type: .body,
            workoutsPerWeek: 3,
            durationWeeks: 12,
            period: "진행 중",
            growth: 67,
            completedWeeks: 7,
            isCurrent: true
        ),
        ProfileGoalRecord(
            type: .strength,
            workoutsPerWeek: 4,
            durationWeeks: 16,
            period: "2026.03–2026.06",
            growth: 100,
            completedWeeks: 16,
            badge: "PEAK"
        ),
        ProfileGoalRecord(
            type: .consistency,
            workoutsPerWeek: 3,
            durationWeeks: 8,
            period: "2025.11–2026.01",
            growth: 100,
            completedWeeks: 8,
            badge: "PEAK"
        ),
        ProfileGoalRecord(
            type: .body,
            workoutsPerWeek: 2,
            durationWeeks: 12,
            period: "2025.08–2025.10",
            growth: 82,
            completedWeeks: 12,
            badge: "HEAVY"
        )
    ]
}

enum ProfileGoalType: String, CaseIterable, Identifiable, Codable {
    case body = "체형"
    case strength = "근력"
    case consistency = "꾸준함"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .body: "균형 잡힌 몸을 만들어요"
        case .strength: "점점 더 강해져요"
        case .consistency: "꾸준한 운동 습관을 만들어요"
        }
    }
}

struct ProfileGoalRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var type: ProfileGoalType
    var workoutsPerWeek: Int
    var durationWeeks: Int
    var period: String
    var growth: Int
    var completedWeeks: Int
    var badge: String?
    var isCurrent: Bool

    init(
        id: UUID = UUID(),
        type: ProfileGoalType,
        workoutsPerWeek: Int,
        durationWeeks: Int,
        period: String,
        growth: Int,
        completedWeeks: Int,
        badge: String? = nil,
        isCurrent: Bool = false
    ) {
        self.id = id
        self.type = type
        self.workoutsPerWeek = workoutsPerWeek
        self.durationWeeks = durationWeeks
        self.period = period
        self.growth = growth
        self.completedWeeks = completedWeeks
        self.badge = badge
        self.isCurrent = isCurrent
    }
}

enum ProfileAction: Equatable {
    case goals
    case restTime
    case notifications
    case photoAccess
    case playlist
}

struct ProfileNotificationPreferences: Codable {
    var workoutReminderEnabled = true
    var restTimerEnabled = true
    var hapticsEnabled = true
}

struct ProfileReminderSchedule: Equatable, Codable {
    static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]
    static let recommendedWeekdays: Set<Int> = [2, 4, 6]

    static let weekdayNames = [1: "일", 2: "월", 3: "화", 4: "수", 5: "목", 6: "금", 7: "토"]

    var weekdays: Set<Int> = [2, 4, 6]
    var time = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? .now

    var isEnabled: Bool {
        !weekdays.isEmpty
    }

    var selectedWeekdaySummary: String {
        let selectedNames = Self.weekdayOrder
            .filter(weekdays.contains)
            .compactMap { Self.weekdayNames[$0] }
        return selectedNames.count == Self.weekdayOrder.count ? "매일" : selectedNames.joined(separator: " · ")
    }

    var summary: String {
        guard isEnabled else { return "일정 없음" }

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let period = hour < 12 ? "오전" : "오후"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return "\(selectedWeekdaySummary) \(period) \(displayHour):\(String(format: "%02d", minute))"
    }

    mutating func toggleWeekday(_ weekday: Int) {
        guard Self.weekdayOrder.contains(weekday) else { return }

        if weekdays.contains(weekday) {
            weekdays.remove(weekday)
        } else {
            weekdays.insert(weekday)
        }
    }
}

enum ProfileSheetDestination: String, Identifiable {
    case restTime

    var id: String { rawValue }
}
