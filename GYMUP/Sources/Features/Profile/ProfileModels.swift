import Foundation

struct ProfileSummary {
    let level: Int
    let stage: String
    let focus: String
    let workoutsPerWeek: Int
    let currentGoal: String
    let goalDurationWeeks: Int
    let notificationPermissionEnabled: Bool
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
        notificationPermissionEnabled: false,
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

enum ProfileGoalType: String, CaseIterable, Identifiable {
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

struct ProfileGoalRecord: Identifiable, Equatable {
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

struct ProfileNotificationPreferences {
    var workoutReminderEnabled = true
    var restTimerEnabled = true
    var weeklySummaryEnabled = false
}

struct ProfileReminderSchedule {
    var weekdays: Set<Int> = [2, 4, 6]
    var time = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? .now

    var summary: String {
        let names = ["일", "월", "화", "수", "목", "금", "토"]
        let selectedDays = weekdays.sorted().compactMap { index in
            names.indices.contains(index - 1) ? names[index - 1] : nil
        }
        let daysSummary: String
        if selectedDays.count == 7 {
            daysSummary = "매일"
        } else if selectedDays.isEmpty {
            daysSummary = "요일 미선택"
        } else {
            daysSummary = selectedDays.joined(separator: " · ")
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return "\(daysSummary) · \(String(format: "%02d:%02d", hour, minute))"
    }
}

enum ProfileSheetDestination: String, Identifiable {
    case restTime
    case playlist

    var id: String { rawValue }
}
