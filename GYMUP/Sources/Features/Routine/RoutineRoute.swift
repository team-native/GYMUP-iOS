import SwiftUI

enum RoutineRoute: Hashable {
    case detail(String)
    case create
    case more(String)
    case edit(String)
    case addExercise(String)
    case exerciseSettings(String, String)
    case emptyStart(String)
    case workout(String)

    var title: String {
        switch self {
        case .detail: "루틴 상세"
        case .create: "루틴 만들기"
        case .more: "루틴 더보기"
        case .edit: "루틴 편집"
        case .addExercise: "운동 추가"
        case .exerciseSettings: "운동 설정"
        case .emptyStart: "빈 루틴"
        case .workout: "운동"
        }
    }
}

struct RoutinePendingView: View {
    let route: RoutineRoute
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            GymupDetailNavigationBar(title: route.title, onBack: dismiss.callAsFunction)
            GymupEmptyState(symbol: "dumbbell", title: route.title, message: "이 화면은 준비 중이에요.")
                .frame(maxHeight: .infinity)
        }
        .background(GymupColors.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}
