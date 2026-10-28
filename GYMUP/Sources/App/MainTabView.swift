import SwiftUI

enum GymupTab: Hashable {
    case home
    case routine
    case history
    case profile
}

struct MainTabView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selection: GymupTab = .home
    @State private var inventory = BarbellCustomizationViewModel()
    @State private var routineStore = RoutineStore()
    @State private var historyStore = HistoryStore()
    @State private var requestedRoutineID: String?
    @State private var requestedExerciseAddRoutineID: String?
    @State private var emptyStartRoutineID: String?
    @State private var isDetailPresented = false
    @State private var isHistoryComparisonPresented = false
    private let completionTestData: WorkoutCompletionData?

    @MainActor
    init() {
#if DEBUG
        completionTestData = ProcessInfo.processInfo.arguments.contains("--uitest-e1-completion")
            ? Self.makeCompletionTestData()
            : nil
#else
        completionTestData = nil
#endif
    }

    var body: some View {
        Group {
            if let completionTestData {
                WorkoutCompletionFlowView(
                    data: completionTestData,
                    onFinish: {},
                    showsPhotoAction: false,
                    showsPeakGoalActions: false
                )
            } else {
                switch selection {
                case .home:
                    HomeView(
                        onOpenRoutines: { requestedRoutineID = "upper-a"; selection = .routine },
                        inventory: inventory,
                        historyStore: historyStore,
                        onDetailRouteChanged: { isDetailPresented = $0 }
                    )
                case .routine:
                    RoutineView(store: routineStore, historyStore: historyStore, requestedRoutineID: $requestedRoutineID,
                                requestedExerciseAddRoutineID: $requestedExerciseAddRoutineID,
                                onEmptyStartAttempt: { emptyStartRoutineID = $0 },
                                onDetailRouteChanged: { isDetailPresented = $0 })
                case .history:
                    HistoryView(
                        store: historyStore,
                        onOpenRoutines: { selection = .routine },
                        onComparisonPresented: { isHistoryComparisonPresented = $0 }
                    )
                case .profile:
                    MyProfileView()
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if completionTestData == nil && !isDetailPresented && !(selection == .history && isHistoryComparisonPresented) {
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
        .background(selection == .profile ? ProfileOverviewColors.canvas : GymupColors.canvas)
        .preferredColorScheme(.dark)
    }

#if DEBUG
    @MainActor
    private static func makeCompletionTestData() -> WorkoutCompletionData {
        let calendar = Calendar.current
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 12)) ?? .now
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start ?? anchor
        let completedAt = calendar.date(byAdding: .day, value: 5, to: weekStart) ?? anchor
        let firstWorkout = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart
        let secondWorkout = calendar.date(byAdding: .day, value: 2, to: weekStart) ?? weekStart
        let records = [firstWorkout, secondWorkout].enumerated().map { index, date in
            WorkoutRecord(
                id: UUID(), date: date, routineName: "기존 운동 \(index + 1)", category: "가슴",
                durationMinutes: 40, setCount: 8, volumeKilograms: 1_600, growth: 0,
                photoAssetName: "H1RoutinePhoto", exercises: []
            )
        }
        let goalStart = calendar.date(byAdding: .weekOfYear, value: -4, to: weekStart) ?? weekStart
        let settings = OnboardingStoredSettings(
            experience: 1,
            purposes: ["근력 향상"],
            frequency: 3,
            goal: 1,
            weeks: 12,
            goalStartedAt: goalStart
        )
        var plan = WorkoutSessionPlan.sample(for: "upper-a")
        for exerciseIndex in plan.exercises.indices {
            for setIndex in plan.exercises[exerciseIndex].sets.indices {
                plan.exercises[exerciseIndex].sets[setIndex].isCompleted = true
            }
        }
        return WorkoutSessionCompletionDataFactory.make(
            plan: plan,
            elapsedSeconds: 3_480,
            completedAt: completedAt,
            context: WorkoutCompletionProgressContext(historyStore: HistoryStore(records: records), goalSettings: settings)
        )
    }
#endif

    private var tabBar: some View {
        HStack(spacing: 0) {
            tab(.home, title: "홈", icon: selection == .home ? "H1IconHome" : "R1IconHomeInactive")
            tab(.routine, title: "루틴", icon: selection == .routine ? "R1IconRoutineActive" : "H1IconRoutine")
            tab(.history, title: "기록", icon: "H1IconHistory")
            tab(.profile, title: "마이", icon: "H1IconUser")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .frame(height: dynamicTypeSize.isAccessibilitySize ? 76 : 58, alignment: .top)
        .background {
            (selection == .profile ? ProfileOverviewColors.canvas : GymupColors.canvas)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(selection == .profile ? GymupColors.border : Color(red: 0.15, green: 0.15, blue: 0.17))
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
                    .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxxLarge)
                    .foregroundStyle(
                        selection == value
                            ? GymupColors.primaryText
                            : selection == .profile
                                ? ProfileOverviewColors.secondaryText
                                : Color(red: 0.42, green: 0.42, blue: 0.46)
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 66 : 50, alignment: .top)
            .padding(.top, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selection == value ? .isSelected : [])
    }
}
