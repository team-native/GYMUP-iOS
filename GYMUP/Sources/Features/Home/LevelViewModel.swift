import Observation

struct LevelXPFactor: Identifiable {
    let title: String
    let value: String
    var id: String { title }
}

struct LevelXPEntry: Identifiable {
    let title: String
    let date: String
    let value: Int
    var id: String { title }
}

@Observable
@MainActor
final class LevelViewModel {
    let level = 17
    let experience = 2_340
    let targetExperience = 3_000
    let nextReward = "골드 칼라 (바벨 아이템)"
    let factors = [
        LevelXPFactor(title: "운동 완료", value: "+200"),
        LevelXPFactor(title: "루틴 100%", value: "+100"),
        LevelXPFactor(title: "PR", value: "+25/개"),
        LevelXPFactor(title: "주간 목표", value: "+30")
    ]
    let recentExperience = [
        LevelXPEntry(title: "상체 A 완료", date: "10월 11일", value: 380),
        LevelXPEntry(title: "하체 B 완료", date: "10월 8일", value: 300),
        LevelXPEntry(title: "주간 목표 달성", date: "10월 5일", value: 30)
    ]

    var remainingExperience: Int { max(targetExperience - experience, 0) }
    var progress: Double { Double(experience) / Double(targetExperience) }
}
