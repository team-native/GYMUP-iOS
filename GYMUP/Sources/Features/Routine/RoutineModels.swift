import Foundation

struct RoutinePlan: Identifiable, Hashable {
    let id: String
    let name: String
    let focus: String
    let exerciseCount: Int
    let durationMinutes: Int
    let exercises: [WorkoutExercise]

    static let samples = [
        RoutinePlan(
            id: "upper-a",
            name: "UPPER A",
            focus: "가슴 · 어깨 · 삼두",
            exerciseCount: 6,
            durationMinutes: 60,
            exercises: [
                .init(name: "벤치 프레스", detail: "4세트 · 8–10회", weight: "60 kg"),
                .init(name: "인클라인 덤벨 프레스", detail: "3세트 · 10–12회", weight: "20 kg"),
                .init(name: "숄더 프레스", detail: "3세트 · 8–10회", weight: "30 kg"),
                .init(name: "케이블 레터럴 레이즈", detail: "3세트 · 12–15회", weight: "7.5 kg"),
                .init(name: "케이블 푸시다운", detail: "3세트 · 10–12회", weight: "25 kg"),
                .init(name: "오버헤드 익스텐션", detail: "3세트 · 12회", weight: "15 kg")
            ]
        ),
        RoutinePlan(
            id: "lower-a",
            name: "LOWER A",
            focus: "하체 · 코어",
            exerciseCount: 5,
            durationMinutes: 55,
            exercises: [
                .init(name: "바벨 스쿼트", detail: "4세트 · 6–8회", weight: "80 kg"),
                .init(name: "루마니안 데드리프트", detail: "3세트 · 8–10회", weight: "60 kg"),
                .init(name: "레그 프레스", detail: "3세트 · 10–12회", weight: "120 kg"),
                .init(name: "레그 컬", detail: "3세트 · 12회", weight: "35 kg"),
                .init(name: "플랭크", detail: "3세트 · 45초", weight: "체중")
            ]
        ),
        RoutinePlan(
            id: "pull-a",
            name: "PULL A",
            focus: "등 · 이두",
            exerciseCount: 6,
            durationMinutes: 58,
            exercises: [
                .init(name: "랫 풀다운", detail: "4세트 · 8–10회", weight: "45 kg"),
                .init(name: "시티드 로우", detail: "3세트 · 10회", weight: "40 kg"),
                .init(name: "원암 덤벨 로우", detail: "3세트 · 10회", weight: "22 kg"),
                .init(name: "페이스 풀", detail: "3세트 · 15회", weight: "15 kg"),
                .init(name: "바벨 컬", detail: "3세트 · 10회", weight: "20 kg"),
                .init(name: "해머 컬", detail: "3세트 · 12회", weight: "12 kg")
            ]
        )
    ]
}

struct WorkoutExercise: Identifiable, Hashable {
    let name: String
    let detail: String
    let weight: String

    var id: String { name }
}
