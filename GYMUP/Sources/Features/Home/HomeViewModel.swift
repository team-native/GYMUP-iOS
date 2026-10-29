import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var dateTitle: String { HistoryDateText.string(.now, format: "M월 d일 EEEE") }
    let level = 17
    let stageTitle = "STAGE 5 · HEAVY"
    let rewardNotice = "새 원판이 해금됐어요"
    let barbellWeight = 130
    let growth = 67
    let nextPlateProgress = 17
    let weeklyWorkoutCount = 2
    let weeklyWorkoutGoal = 3
    let streakWeeks = 7
    let experiencePoints = 2_340
    let todayRoutine = "UPPER A"
}
