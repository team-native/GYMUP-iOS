import Foundation

struct WorkoutSessionSet: Identifiable, Equatable {
    let id: UUID
    var weightKilograms: Double
    var repetitions: Int
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        weightKilograms: Double,
        repetitions: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.weightKilograms = weightKilograms
        self.repetitions = repetitions
        self.isCompleted = isCompleted
    }
}

struct WorkoutSessionExercise: Identifiable, Equatable {
    let id: String
    let name: String
    let target: String
    let restDurationSeconds: Int
    let formSteps: [String]
    let beginnerTip: String
    var sets: [WorkoutSessionSet]
    var imageAssetOverride: String?
    var usesSampleHistory = true

    var completedSetCount: Int { sets.filter(\.isCompleted).count }
    var isComplete: Bool { !sets.isEmpty && sets.allSatisfy(\.isCompleted) }
    var completedVolumeKilograms: Double {
        sets.filter(\.isCompleted).reduce(0) { $0 + $1.weightKilograms * Double($1.repetitions) }
    }

    var displayTitle: String {
        switch id {
        case "bench-press": "BENCH PRESS"
        case "incline-press": "INCLINE DUMBBELL PRESS"
        case "lat-pulldown": "LAT PULLDOWN"
        case "shoulder-press": "SHOULDER PRESS"
        case "cable-fly": "CABLE FLY"
        case "triceps-pushdown": "TRICEPS PUSHDOWN"
        case "squat": "BARBELL SQUAT"
        case "leg-press": "LEG PRESS"
        case "leg-curl": "LEG CURL"
        case "leg-extension": "LEG EXTENSION"
        case "calf-raise": "CALF RAISE"
        case "deadlift": "DEADLIFT"
        case "seated-row": "SEATED ROW"
        case "dumbbell-curl": "DUMBBELL CURL"
        case "hammer-curl": "HAMMER CURL"
        case "face-pull": "FACE PULL"
        default: name.uppercased()
        }
    }

    var guideDisplayTitle: String {
        id == "incline-press" ? "INCLINE DB PRESS" : displayTitle
    }

    var guideMuscleGroups: [String] {
        switch id {
        case "incline-press": ["윗가슴", "전면 삼각근", "삼두"]
        case "bench-press": ["가슴", "전면 삼각근", "삼두"]
        case "lat-pulldown", "seated-row": ["등", "광배근", "이두"]
        case "shoulder-press", "face-pull": ["어깨", "전면 삼각근", "삼두"]
        case "squat", "leg-press", "leg-extension": ["대퇴사두근", "둔근", "햄스트링"]
        case "leg-curl": ["햄스트링", "둔근"]
        case "calf-raise": ["종아리"]
        case "dumbbell-curl", "hammer-curl": ["이두", "전완"]
        case "triceps-pushdown": ["삼두"]
        default: [target]
        }
    }

    var commonMistakes: [String] {
        switch id {
        case "incline-press": ["허리를 과하게 띄우기", "반동으로 튕겨 올리기"]
        case "bench-press": ["엉덩이를 벤치에서 들기", "바를 튕겨 올리기"]
        case "squat": ["무릎이 안쪽으로 모이기", "발뒤꿈치가 뜨기"]
        default: ["반동으로 동작하기", "관절을 과하게 잠그기"]
        }
    }

    var imageAssetName: String {
        if let imageAssetOverride { return imageAssetOverride }
        switch id {
        case "bench-press": "H1RoutinePhoto"
        case "incline-press", "dumbbell-curl", "hammer-curl": "ExerciseInclinePhoto"
        case "shoulder-press", "cable-fly", "face-pull": "ExerciseChalkPhoto"
        case "squat", "leg-press", "leg-curl", "leg-extension", "calf-raise": "R1RoutineLower"
        default: "ExerciseHeroPhoto"
        }
    }

    func previousPerformanceTitle(for setIndex: Int?) -> String {
        guard usesSampleHistory, id == "bench-press" else { return "이전 기록 없음" }
        let repetitions = setIndex == sets.count - 1 ? 6 : 8
        return "이전 · 10월 8일 60kg × \(repetitions)"
    }

    func previousPerformance(for setIndex: Int) -> String? {
        guard usesSampleHistory, id == "bench-press" else { return nil }
        return setIndex == 3 ? "60 × 6" : "60 × 8"
    }

    var hasPreviousPerformance: Bool {
        previousPerformance(for: 0) != nil
    }

    var personalRecordKilograms: Double? { usesSampleHistory && id == "bench-press" ? 62.5 : nil }

    var personalRecordSet: WorkoutSessionSet? {
        guard let personalRecordKilograms else { return nil }
        return sets.first { $0.isCompleted && $0.weightKilograms >= personalRecordKilograms }
    }
}

struct WorkoutSessionPlan: Identifiable, Equatable {
    let id: String
    let name: String
    let title: String
    let estimatedDurationMinutes: Int
    var exercises: [WorkoutSessionExercise]

    static func make(from routine: RoutinePlan) -> WorkoutSessionPlan? {
        guard !routine.exercises.isEmpty,
              routine.exercises.allSatisfy({ $0.measure == .repetitions && $0.setCount > 0 }) else { return nil }
        let aliases = ["bench": "bench-press", "incline": "incline-press", "shoulder": "shoulder-press",
                       "fly": "cable-fly", "pushdown": "triceps-pushdown", "curl": "dumbbell-curl",
                       "hammer": "hammer-curl"]
        let exercises = routine.exercises.map { item in
            let identifier = aliases[item.id] ?? item.id
            let guidance = WorkoutSessionGuidanceLibrary.guidance(for: identifier)
            let target = RoutineExerciseOption.all.first { $0.id == item.id }?.muscleGroup ?? "운동"
            return WorkoutSessionExercise(
                id: identifier, name: item.name, target: target, restDurationSeconds: item.restSeconds,
                formSteps: guidance.steps, beginnerTip: guidance.beginnerTip,
                sets: (0..<item.setCount).map { _ in
                    WorkoutSessionSet(weightKilograms: item.weight, repetitions: item.repetitions)
                }, imageAssetOverride: item.imageAssetName, usesSampleHistory: false
            )
        }
        return WorkoutSessionPlan(id: routine.id, name: routine.name, title: routine.title,
                                  estimatedDurationMinutes: routine.durationMinutes, exercises: exercises)
    }

    static func sample(for routineID: String) -> WorkoutSessionPlan {
        let template: WorkoutSessionPlan
        switch routineID {
        case "lower-b":
            template = lowerB
        case "back-c":
            template = backC
        default:
            template = upperA
        }

        return WorkoutSessionPlan(
            id: routineID,
            name: template.name,
            title: template.title,
            estimatedDurationMinutes: template.estimatedDurationMinutes,
            exercises: template.exercises
        )
    }

    private static let lowerB = WorkoutSessionPlan(
        id: "lower-b",
        name: "LOWER B",
        title: "하체 B",
        estimatedDurationMinutes: 60,
        exercises: [
            exercise(.init(id: "squat", name: "스쿼트", target: "하체 · 둔근", sets: 4, weight: 60, repetitions: 10)),
            exercise(.init(id: "leg-press", name: "레그 프레스", target: "대퇴사두근", sets: 4, weight: 100, repetitions: 12)),
            exercise(.init(id: "leg-curl", name: "레그 컬", target: "햄스트링", sets: 3, weight: 25, repetitions: 12)),
            exercise(.init(
                id: "leg-extension", name: "레그 익스텐션", target: "대퇴사두근", sets: 3, weight: 30, repetitions: 15
            )),
            exercise(.init(id: "calf-raise", name: "카프 레이즈", target: "종아리", sets: 3, weight: 40, repetitions: 15))
        ]
    )

    private static let backC = WorkoutSessionPlan(
        id: "back-c",
        name: "BACK C",
        title: "등 · 이두 C",
        estimatedDurationMinutes: 50,
        exercises: [
            exercise(.init(id: "deadlift", name: "데드리프트", target: "등 · 하체", sets: 4, weight: 60, repetitions: 8)),
            exercise(.init(id: "lat-pulldown", name: "랫 풀다운", target: "광배근", sets: 4, weight: 35, repetitions: 12)),
            exercise(.init(id: "seated-row", name: "시티드 로우", target: "등 중앙", sets: 3, weight: 30, repetitions: 12)),
            exercise(.init(id: "face-pull", name: "페이스 풀", target: "후면 어깨", sets: 3, weight: 15, repetitions: 15)),
            exercise(.init(id: "dumbbell-curl", name: "덤벨 컬", target: "이두근", sets: 3, weight: 8, repetitions: 12)),
            exercise(.init(id: "hammer-curl", name: "해머 컬", target: "이두근", sets: 3, weight: 8, repetitions: 12))
        ]
    )

    private static let upperA = WorkoutSessionPlan(
        id: "upper-a",
        name: "UPPER A",
        title: "상체 A",
        estimatedDurationMinutes: 55,
        exercises: [
            exercise(.init(id: "bench-press", name: "벤치 프레스", target: "가슴 · 삼두", sets: 4, weight: 62.5, repetitions: 8)),
            exercise(.init(
                id: "incline-press", name: "인클라인 덤벨 프레스", target: "윗가슴", sets: 3, weight: 22, repetitions: 10
            )),
            exercise(.init(id: "lat-pulldown", name: "랫 풀다운", target: "광배근", sets: 3, weight: 35, repetitions: 12)),
            exercise(.init(id: "shoulder-press", name: "숄더 프레스", target: "어깨", sets: 3, weight: 16, repetitions: 10)),
            exercise(.init(id: "cable-fly", name: "케이블 플라이", target: "가슴", sets: 3, weight: 12, repetitions: 15)),
            exercise(.init(id: "triceps-pushdown", name: "케이블 푸시다운", target: "삼두", sets: 3, weight: 20, repetitions: 15))
        ]
    )

    private static func exercise(_ template: WorkoutSessionExerciseTemplate) -> WorkoutSessionExercise {
        let guidance = WorkoutSessionGuidanceLibrary.guidance(for: template.id)
        return WorkoutSessionExercise(
            id: template.id,
            name: template.name,
            target: template.target,
            restDurationSeconds: template.restSeconds,
            formSteps: guidance.steps,
            beginnerTip: guidance.beginnerTip,
            sets: (0..<template.sets).map { _ in
                WorkoutSessionSet(weightKilograms: template.weight, repetitions: template.repetitions)
            }
        )
    }
}

private struct WorkoutSessionExerciseTemplate {
    let id: String
    let name: String
    let target: String
    let sets: Int
    let weight: Double
    let repetitions: Int
    var restSeconds = 90
}

private struct WorkoutSessionGuidance {
    let steps: [String]
    let beginnerTip: String
}

private enum WorkoutSessionGuidanceLibrary {
    private static let fallback = WorkoutSessionGuidance(
        steps: [
            "몸통을 안정적으로 세우고 준비 자세를 잡아요.",
            "목표 근육에 힘을 주며 부드럽게 동작합니다.",
            "반동을 줄이고 시작 자세로 천천히 돌아가요."
        ],
        beginnerTip: "처음에는 가벼운 중량으로 움직임을 익히고, 통증이 있으면 멈추세요."
    )

    private static let byExercise: [String: WorkoutSessionGuidance] = [
        "bench-press": .init(
            steps: [
                "발을 바닥에 고정하고 어깨뼈를 모아요.",
                "바를 가슴 쪽으로 천천히 내립니다.",
                "발로 바닥을 밀며 바를 위로 밀어 올려요."
            ],
            beginnerTip: "처음이라면 빈 바나 가벼운 중량으로 자세를 익히고 가능하면 보조자와 함께하세요."
        ),
        "incline-press": .init(
            steps: [
                "견갑을 모으고 가슴을 든 상태 유지",
                "덤벨은 윗가슴 라인으로 천천히 내리기",
                "팔꿈치는 몸통과 45–60°"
            ],
            beginnerTip: "허리가 과하게 뜨지 않도록 가벼운 덤벨부터 시작하세요."
        ),
        "lat-pulldown": .init(
            steps: [
                "손잡이를 어깨보다 조금 넓게 잡아요.",
                "가슴을 세우고 팔꿈치를 옆구리 쪽으로 당깁니다.",
                "팔을 천천히 펴며 시작 위치로 돌아가요."
            ],
            beginnerTip: "목 뒤로 당기지 말고, 가슴 앞쪽으로 당겨 주세요."
        ),
        "squat": .init(
            steps: [
                "발을 어깨 너비로 벌리고 발끝을 살짝 바깥으로 둡니다.",
                "엉덩이를 뒤로 보내며 무릎을 굽혀요.",
                "발바닥 전체로 바닥을 밀어 일어납니다."
            ],
            beginnerTip: "처음에는 맨몸으로 깊이와 균형을 확인한 뒤 중량을 더하세요."
        ),
        "leg-press": .init(
            steps: [
                "등과 엉덩이를 등받이에 붙여요.",
                "무릎이 발끝 방향을 향하도록 발판을 내립니다.",
                "무릎을 잠그지 않고 발판을 밀어 올려요."
            ],
            beginnerTip: "허리가 말리기 전까지만 내리고, 무릎을 끝까지 잠그지 마세요."
        ),
        "deadlift": .init(
            steps: [
                "바가 발 중앙 위에 오도록 서요.",
                "엉덩이를 뒤로 보내고 등을 편 상태로 바를 잡습니다.",
                "바를 몸 가까이 두고 엉덩이와 무릎을 펴며 일어나요."
            ],
            beginnerTip: "허리가 둥글게 말리지 않도록 가벼운 무게로 동작을 먼저 연습하세요."
        ),
        "shoulder-press": .init(
            steps: [
                "덤벨을 어깨 옆에 두고 손목을 곧게 세워요.",
                "허리를 과하게 젖히지 않고 위로 밀어 올립니다.",
                "팔꿈치를 잠그지 않고 어깨 옆으로 천천히 내립니다."
            ],
            beginnerTip: "등받이를 사용하고 어깨가 불편하면 가동 범위를 줄여 주세요."
        ),
        "cable-fly": .init(
            steps: [
                "케이블 앞에서 가슴을 세우고 팔꿈치를 살짝 굽혀요.",
                "팔을 부드럽게 모아 가슴 앞에서 만납니다.",
                "가슴이 당기는 범위까지만 천천히 벌려요."
            ],
            beginnerTip: "무게를 낮게 설정하고 팔꿈치 각도를 고정해 주세요."
        ),
        "triceps-pushdown": .init(
            steps: [
                "팔꿈치를 몸 옆에 붙이고 손잡이를 잡아요.",
                "팔꿈치 위치를 고정한 채 팔을 아래로 폅니다.",
                "천천히 팔을 굽혀 시작 위치로 돌아가요."
            ],
            beginnerTip: "어깨를 흔들지 말고 팔꿈치만 움직여 주세요."
        )
    ]

    static func guidance(for exerciseID: String) -> WorkoutSessionGuidance {
        byExercise[exerciseID] ?? fallback
    }
}
