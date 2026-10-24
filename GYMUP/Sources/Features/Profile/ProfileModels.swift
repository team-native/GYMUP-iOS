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
}

enum ProfileAction {
    case level
    case goals
    case restTime
    case notifications
    case photoAccess
    case playlist

    var message: String {
        switch self {
        case .level: "레벨 상세 화면을 다음 단계에서 연결할게요."
        case .goals: "운동 목표 화면을 다음 단계에서 연결할게요."
        case .restTime: "기본 휴식 시간 설정을 다음 단계에서 연결할게요."
        case .notifications: "알림 설정을 다음 단계에서 연결할게요."
        case .photoAccess: "카메라와 사진 권한 설정을 다음 단계에서 연결할게요."
        case .playlist: "플레이리스트 연결을 다음 단계에서 연결할게요."
        }
    }
}
