import SwiftUI

enum GymupTab: Hashable {
    case home
    case routine
    case history
    case profile
}

struct MainTabView: View {
    @State private var selection: GymupTab = .home
    @State private var inventory = BarbellCustomizationViewModel()
    @State private var routineStore = RoutineStore()
    @State private var requestedRoutineID: String?
    @State private var requestedExerciseAddRoutineID: String?
    @State private var emptyStartRoutineID: String?
    @State private var isDetailPresented = false

    var body: some View {
        Group {
            switch selection {
            case .home:
                HomeView(
                    onOpenRoutines: { requestedRoutineID = "upper-a"; selection = .routine },
                    inventory: inventory,
                    onDetailRouteChanged: { isDetailPresented = $0 }
                )
            case .routine:
                RoutineView(store: routineStore, requestedRoutineID: $requestedRoutineID,
                            requestedExerciseAddRoutineID: $requestedExerciseAddRoutineID,
                            onEmptyStartAttempt: { emptyStartRoutineID = $0 },
                            onDetailRouteChanged: { isDetailPresented = $0 })
            case .history:
                HistoryView(onOpenRoutines: { selection = .routine })
            case .profile:
                MyProfileView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isDetailPresented {
                tabBar
            }
        }
        .overlay {
            if let routineID = emptyStartRoutineID {
                RoutineEmptyStartAlert(
                    onClose: { emptyStartRoutineID = nil },
                    onAddExercise: {
                        emptyStartRoutineID = nil
                        requestedExerciseAddRoutineID = routineID
                    }
                )
            }
        }
        .background(GymupColors.canvas)
        .preferredColorScheme(.dark)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tab(.home, title: "홈", icon: selection == .home ? "H1IconHome" : "R1IconHomeInactive")
            tab(.routine, title: "루틴", icon: selection == .routine ? "R1IconRoutineActive" : "H1IconRoutine")
            tab(.history, title: "기록", icon: "H1IconHistory")
            tab(.profile, title: "마이", icon: "H1IconUser")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .frame(height: 58, alignment: .top)
        .background {
            GymupColors.canvas
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.17))
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tab(_ value: GymupTab, title: String, icon: String) -> some View {
        Button {
            selection = value
        } label: {
            VStack(spacing: 4) {
                Image(icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                Text(title)
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(selection == value ? GymupColors.primaryText : Color(red: 0.42, green: 0.42, blue: 0.46))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50, alignment: .top)
            .padding(.top, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selection == value ? .isSelected : [])
    }
}
