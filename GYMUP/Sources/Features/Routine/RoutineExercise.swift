import Foundation

enum RoutineExerciseMeasure: Hashable {
    case repetitions, seconds
}

struct RoutineExercise: Identifiable, Hashable {
    let id: String
    let name: String
    let imageAssetName: String
    var setCount: Int
    var repetitions: Int
    var weight: Double
    var restSeconds: Int
    var measure = RoutineExerciseMeasure.repetitions

    var restTitle: String { "\(restSeconds / 60):\(String(format: "%02d", restSeconds % 60))" }
    var weightTitle: String { weight.formatted(.number.precision(.fractionLength(0...1))) }
    var resistanceTitle: String { weight == 0 ? "체중" : "\(weightTitle)kg" }
    var repetitionTitle: String { "\(repetitions)\(measure == .seconds ? "초" : "회")" }
    var summary: String { "\(setCount)세트 · \(repetitionTitle) · \(resistanceTitle) · 휴식 \(restTitle)" }

    static let upper = [
        RoutineExercise(id: "bench", name: "벤치프레스", imageAssetName: "H1RoutinePhoto",
                        setCount: 4, repetitions: 8, weight: 60, restSeconds: 90),
        RoutineExercise(id: "incline", name: "인클라인 덤벨 프레스", imageAssetName: "ExerciseInclinePhoto",
                        setCount: 3,
                        repetitions: 10, weight: 22, restSeconds: 75),
        RoutineExercise(id: "shoulder", name: "숄더 프레스", imageAssetName: "ExerciseChalkPhoto",
                        setCount: 4,
                        repetitions: 10, weight: 40, restSeconds: 90),
        RoutineExercise(id: "fly", name: "케이블 플라이", imageAssetName: "R1RoutineBack",
                        setCount: 3, repetitions: 12, weight: 15, restSeconds: 60),
        RoutineExercise(id: "pushdown", name: "트라이셉스 푸시다운", imageAssetName: "ExerciseHeroPhoto",
                        setCount: 3,
                        repetitions: 12, weight: 25, restSeconds: 60)
    ]

    static let lower = [
        RoutineExercise(id: "squat", name: "바벨 스쿼트", imageAssetName: "R1RoutineLower",
                        setCount: 4, repetitions: 8, weight: 80, restSeconds: 90),
        RoutineExercise(id: "deadlift", name: "루마니안 데드리프트", imageAssetName: "ExerciseHeroPhoto",
                        setCount: 3,
                        repetitions: 10, weight: 60, restSeconds: 90),
        RoutineExercise(id: "leg-press", name: "레그 프레스", imageAssetName: "R1RoutineLower",
                        setCount: 3,
                        repetitions: 12, weight: 120, restSeconds: 90),
        RoutineExercise(id: "leg-curl", name: "레그 컬", imageAssetName: "R1RoutineLower",
                        setCount: 3, repetitions: 12, weight: 35, restSeconds: 90),
        RoutineExercise(id: "plank", name: "플랭크", imageAssetName: "R1RoutineLower",
                        setCount: 3, repetitions: 45, weight: 0, restSeconds: 60, measure: .seconds)
    ]

    static let back = [
        RoutineExercise(id: "lat", name: "랫 풀다운", imageAssetName: "R1RoutineBack",
                        setCount: 4, repetitions: 10, weight: 45, restSeconds: 90),
        RoutineExercise(id: "row", name: "시티드 로우", imageAssetName: "ExerciseHeroPhoto",
                        setCount: 3, repetitions: 10, weight: 40, restSeconds: 90),
        RoutineExercise(id: "dumbbell-row", name: "원암 덤벨 로우", imageAssetName: "ExerciseInclinePhoto",
                        setCount: 3,
                        repetitions: 10, weight: 22, restSeconds: 90),
        RoutineExercise(id: "face-pull", name: "페이스 풀", imageAssetName: "R1RoutineBack",
                        setCount: 3, repetitions: 15, weight: 15, restSeconds: 60),
        RoutineExercise(id: "curl", name: "바벨 컬", imageAssetName: "ExerciseChalkPhoto",
                        setCount: 3, repetitions: 10, weight: 20, restSeconds: 60),
        RoutineExercise(id: "hammer", name: "해머 컬", imageAssetName: "ExerciseInclinePhoto",
                        setCount: 3, repetitions: 12, weight: 12, restSeconds: 60)
    ]
}
