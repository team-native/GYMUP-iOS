import Foundation
import Observation

enum HistoryRoute: Hashable {
    case detail(UUID)
    case calendar
    case growth
    case album
    case comparison(UUID)
}

struct WorkoutSetRecord: Identifiable, Hashable, Codable {
    let id: Int
    let weight: Double
    let repetitions: Int
    var isPersonalRecord = false
    var measure = RoutineExerciseMeasure.repetitions

    var valueTitle: String { "\(repetitions)\(measure == .seconds ? "초" : "회")" }

    var accessibilityDescription: String {
        let personalRecord = isPersonalRecord ? ", 개인 기록" : ""
        return "\(id)세트, \(weight.formatted())킬로그램, \(valueTitle)\(personalRecord)"
    }
}

struct WorkoutExerciseRecord: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let sets: [WorkoutSetRecord]
}

struct WorkoutRecord: Identifiable, Hashable, Codable {
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
    var routineCompleted = false
    var earnedExperience: Int?

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

    var unit: String {
        "KG"
    }

    var progressionSeedValues: [Double] {
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
                        WorkoutSetRecord(id: 4, weight: 55, repetitions: 10)
                    ]),
                    WorkoutExerciseRecord(id: 2, name: "인클라인 덤벨 프레스", sets: [
                        WorkoutSetRecord(id: 1, weight: 20, repetitions: 12),
                        WorkoutSetRecord(id: 2, weight: 22.5, repetitions: 10),
                        WorkoutSetRecord(id: 3, weight: 22.5, repetitions: 9)
                    ]),
                    WorkoutExerciseRecord(id: 3, name: "케이블 플라이", sets: [
                        WorkoutSetRecord(id: 1, weight: 15, repetitions: 15),
                        WorkoutSetRecord(id: 2, weight: 17.5, repetitions: 12)
                    ])
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
                        WorkoutSetRecord(id: 3, weight: 90, repetitions: 6, isPersonalRecord: true)
                    ]),
                    WorkoutExerciseRecord(id: 2, name: "레그 프레스", sets: [
                        WorkoutSetRecord(id: 1, weight: 120, repetitions: 12),
                        WorkoutSetRecord(id: 2, weight: 140, repetitions: 10)
                    ])
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
                        WorkoutSetRecord(id: 3, weight: 50, repetitions: 8)
                    ]),
                    WorkoutExerciseRecord(id: 2, name: "시티드 로우", sets: [
                        WorkoutSetRecord(id: 1, weight: 35, repetitions: 12),
                        WorkoutSetRecord(id: 2, weight: 40, repetitions: 10)
                    ])
                ]
            )
        ]
    }()

    static func record(with id: UUID) -> WorkoutRecord? {
        records.first { $0.id == id }
    }

    static func records(on date: Date) -> [WorkoutRecord] {
        records.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

enum HistoryListSampleData {
    private struct SampleWorkout {
        let day: Int
        let routineName: String
        let category: String
        let durationMinutes: Int
        let setCount: Int
        let volumeKilograms: Int
        let personalRecordCount: Int
    }

    static let sampleMonth: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = .current
        components.year = 2025
        components.month = 10
        components.day = 1
        return Calendar(identifier: .gregorian).date(from: components) ?? .now
    }()

    static let records: [WorkoutRecord] = {
        let workouts = [
            SampleWorkout(
                day: 11,
                routineName: "상체 A",
                category: "가슴 · 어깨 · 삼두",
                durationMinutes: 50,
                setCount: 18,
                volumeKilograms: 8_420,
                personalRecordCount: 2
            ),
            SampleWorkout(
                day: 8,
                routineName: "하체 B",
                category: "하체 · 코어",
                durationMinutes: 62,
                setCount: 17,
                volumeKilograms: 11_200,
                personalRecordCount: 0
            ),
            SampleWorkout(
                day: 6,
                routineName: "등 · 이두 C",
                category: "등 · 이두",
                durationMinutes: 49,
                setCount: 16,
                volumeKilograms: 7_050,
                personalRecordCount: 1
            ),
            SampleWorkout(
                day: 3,
                routineName: "상체 A",
                category: "가슴 · 어깨 · 삼두",
                durationMinutes: 55,
                setCount: 18,
                volumeKilograms: 8_100,
                personalRecordCount: 0
            ),
            SampleWorkout(
                day: 3,
                routineName: "하체 B",
                category: "하체 · 코어",
                durationMinutes: 54,
                setCount: 16,
                volumeKilograms: 7_200,
                personalRecordCount: 1
            ),
            SampleWorkout(
                day: 2,
                routineName: "등 · 이두 C",
                category: "등 · 이두",
                durationMinutes: 52,
                setCount: 17,
                volumeKilograms: 6_800,
                personalRecordCount: 0
            ),
            SampleWorkout(
                day: 2,
                routineName: "상체 A",
                category: "가슴 · 어깨 · 삼두",
                durationMinutes: 56,
                setCount: 18,
                volumeKilograms: 7_900,
                personalRecordCount: 2
            ),
            SampleWorkout(
                day: 1,
                routineName: "하체 B",
                category: "하체 · 코어",
                durationMinutes: 57,
                setCount: 18,
                volumeKilograms: 7_600,
                personalRecordCount: 1
            ),
            SampleWorkout(
                day: 1,
                routineName: "등 · 이두 C",
                category: "등 · 이두",
                durationMinutes: 57,
                setCount: 17,
                volumeKilograms: 8_130,
                personalRecordCount: 0
            )
        ]

        return workouts.map { workout in
            let date = date(day: workout.day)
            return WorkoutRecord(
                id: UUID(),
                date: date,
                routineName: workout.routineName,
                category: workout.category,
                durationMinutes: workout.durationMinutes,
                setCount: workout.setCount,
                volumeKilograms: workout.volumeKilograms,
                growth: workout.personalRecordCount,
                photoAssetName: photoAsset(for: workout.routineName),
                exercises: exercises(
                    for: workout.routineName,
                    setCount: workout.setCount,
                    personalRecordCount: workout.personalRecordCount
                )
            )
        }
    }()

    static func records(inMonthOf date: Date) -> [WorkoutRecord] {
        let calendar = Calendar.current
        guard let month = calendar.dateInterval(of: .month, for: date) else { return [] }
        return records.filter { $0.date >= month.start && $0.date < month.end }
    }

    static func records(on date: Date) -> [WorkoutRecord] {
        records.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    static func record(with id: UUID) -> WorkoutRecord? {
        records.first { $0.id == id }
    }

    static func date(day: Int, inMonthOf date: Date) -> Date {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.era, .year, .month], from: date)) ?? date
        return calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
    }

    private static func date(day: Int) -> Date {
        date(day: day, inMonthOf: sampleMonth)
    }

    private static func photoAsset(for routineName: String) -> String {
        switch routineName {
        case "하체 B": "R1RoutineLower"
        case "등 · 이두 C": "R1RoutineBack"
        default: "H1RoutinePhoto"
        }
    }

    private static func exercises(
        for routineName: String,
        setCount: Int,
        personalRecordCount: Int
    ) -> [WorkoutExerciseRecord] {
        let names: [String]
        switch routineName {
        case "하체 B":
            names = ["스쿼트", "레그 프레스", "레그 컬"]
        case "등 · 이두 C":
            names = ["랫 풀 다운", "시티드 로우", "덤벨 컬"]
        default:
            names = ["벤치프레스", "인클라인 덤벨 프레스", "케이블 플라이"]
        }

        let baseSetCount = setCount / names.count
        let remainingSets = setCount % names.count
        var flattenedSetIndex = 0

        return names.enumerated().map { exerciseIndex, name in
            let exerciseSetCount = baseSetCount + (exerciseIndex < remainingSets ? 1 : 0)
            return WorkoutExerciseRecord(
                id: exerciseIndex + 1,
                name: name,
                sets: (1...exerciseSetCount).map { setIndex in
                    let isPersonalRecord = flattenedSetIndex < personalRecordCount
                    flattenedSetIndex += 1
                    return WorkoutSetRecord(
                        id: setIndex,
                        weight: 40 + Double(exerciseIndex * 10 + setIndex * 2),
                        repetitions: 12 - setIndex,
                        isPersonalRecord: isPersonalRecord
                    )
                }
            )
        }
    }
}
