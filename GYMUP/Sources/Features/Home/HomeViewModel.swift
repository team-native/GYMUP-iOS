import Observation

@Observable
@MainActor
final class HomeViewModel {
    let growth = 67
    let experiencePoints = 2_480
    let nextLevelXP = 4_000
    let todayRoutine = "PUSH DAY"
    let weekDays = ["월", "화", "수", "목", "금", "토", "일"]
    let activeDays: Set<Int> = [0, 2, 3]
}
