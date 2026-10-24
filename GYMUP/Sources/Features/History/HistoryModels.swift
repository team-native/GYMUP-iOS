import Foundation

enum HistoryRoute: Hashable {
    case detail(UUID)
    case calendar
    case growth
    case album
    case comparison(String)
}

struct WorkoutSetRecord: Identifiable, Hashable {
    let id: Int
    let weight: Double
    let repetitions: Int
    var isPersonalRecord = false

    var accessibilityDescription: String {
        let personalRecord = isPersonalRecord ? ", 개인 기록" : ""
        return "\(id)세트, \(weight.formatted())킬로그램, \(repetitions)회\(personalRecord)"
    }
}

struct WorkoutExerciseRecord: Identifiable, Hashable {
    let id: Int
    let name: String
    let sets: [WorkoutSetRecord]
}

struct WorkoutRecord: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let routineName: String
    let category: String
    let durationMinutes: Int
    let setCount: Int
    let volumeKilograms: Int
    let growth: Int
    let photoAssetName: String
    let exercises: [WorkoutExerciseRecord]

    var accessibilityDescription: String {
        let date = HistoryDateText.string(self.date, format: "M월 d일 EEEE")
        return "\(date), \(routineName), \(durationMinutes)분, \(setCount)세트, 개인 기록 \(growth)개"
    }
}

enum HistoryGrowthMetric: String, CaseIterable, Identifiable {
    case maxWeight = "최고 무게"
    case estimatedOneRepMax = "예상 1RM"
    case volume = "볼륨"

    var id: String { rawValue }

    var value: String {
        switch self {
        case .maxWeight: "62.5"
        case .estimatedOneRepMax: "70"
        case .volume: "8,420"
        }
    }

    var unit: String {
        "KG"
    }

    var change: String {
        self == .volume ? "+1,240kg" : "+12.5kg"
    }

    var chartValues: [CGFloat] {
        switch self {
        case .maxWeight: [0.18, 0.24, 0.20, 0.34, 0.42, 0.39, 0.58, 0.55, 0.72, 0.68, 0.86]
        case .estimatedOneRepMax: [0.16, 0.23, 0.22, 0.31, 0.40, 0.45, 0.56, 0.61, 0.70, 0.76, 0.90]
        case .volume: [0.12, 0.21, 0.18, 0.38, 0.34, 0.51, 0.48, 0.67, 0.62, 0.78, 0.92]
        }
    }

}

enum HistorySampleData {
    static let records: [WorkoutRecord] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return [
            WorkoutRecord(
                id: UUID(),
                date: today,
                routineName: "상체 A 루틴",
                category: "가슴 · 어깨 · 삼두",
                durationMinutes: 58,
                setCount: 18,
                volumeKilograms: 8_420,
                growth: 1,
                photoAssetName: "H1RoutinePhoto",
                exercises: [
                    WorkoutExerciseRecord(id: 1, name: "벤치프레스", sets: [
                        WorkoutSetRecord(id: 1, weight: 40, repetitions: 12),
                        WorkoutSetRecord(id: 2, weight: 50, repetitions: 10),
                        WorkoutSetRecord(id: 3, weight: 62.5, repetitions: 8, isPersonalRecord: true),
                        WorkoutSetRecord(id: 4, weight: 55, repetitions: 10),
                    ]),
                    WorkoutExerciseRecord(id: 2, name: "인클라인 덤벨 프레스", sets: [
                        WorkoutSetRecord(id: 1, weight: 20, repetitions: 12),
                        WorkoutSetRecord(id: 2, weight: 22.5, repetitions: 10),
                        WorkoutSetRecord(id: 3, weight: 22.5, repetitions: 9),
                    ]),
                    WorkoutExerciseRecord(id: 3, name: "케이블 플라이", sets: [
                        WorkoutSetRecord(id: 1, weight: 15, repetitions: 15),
                        WorkoutSetRecord(id: 2, weight: 17.5, repetitions: 12),
                    ]),
                ]
            ),
            WorkoutRecord(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -2, to: today) ?? today,
                routineName: "하체 루틴",
                category: "하체 · 코어",
                durationMinutes: 64,
                setCount: 20,
                volumeKilograms: 11_260,
                growth: 2,
                photoAssetName: "R1RoutineLower",
                exercises: [
                    WorkoutExerciseRecord(id: 1, name: "스쿼트", sets: [
                        WorkoutSetRecord(id: 1, weight: 60, repetitions: 10),
                        WorkoutSetRecord(id: 2, weight: 80, repetitions: 8),
                        WorkoutSetRecord(id: 3, weight: 90, repetitions: 6, isPersonalRecord: true),
                    ]),
                    WorkoutExerciseRecord(id: 2, name: "레그 프레스", sets: [
                        WorkoutSetRecord(id: 1, weight: 120, repetitions: 12),
                        WorkoutSetRecord(id: 2, weight: 140, repetitions: 10),
                    ]),
                ]
            ),
            WorkoutRecord(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -4, to: today) ?? today,
                routineName: "등 · 이두 루틴",
                category: "등 · 이두",
                durationMinutes: 51,
                setCount: 16,
                volumeKilograms: 7_840,
                growth: 1,
                photoAssetName: "R1RoutineBack",
                exercises: [
                    WorkoutExerciseRecord(id: 1, name: "랫 풀 다운", sets: [
                        WorkoutSetRecord(id: 1, weight: 40, repetitions: 12),
                        WorkoutSetRecord(id: 2, weight: 45, repetitions: 10),
                        WorkoutSetRecord(id: 3, weight: 50, repetitions: 8),
                    ]),
                    WorkoutExerciseRecord(id: 2, name: "시티드 로우", sets: [
                        WorkoutSetRecord(id: 1, weight: 35, repetitions: 12),
                        WorkoutSetRecord(id: 2, weight: 40, repetitions: 10),
                    ]),
                ]
            ),
        ]
    }()

    static func record(with id: UUID) -> WorkoutRecord? {
        records.first { $0.id == id }
    }

    static func records(on date: Date) -> [WorkoutRecord] {
        records.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
