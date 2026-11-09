import SwiftUI

enum GymupTab: Hashable {
    case home
    case routine
    case history
    case profile
}

@MainActor
private struct MainTabStorageState {
    let routineStore: RoutineStore
    let historyStore: HistoryStore
    let selection: GymupTab
}

struct MainTabView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selection: GymupTab = .home
    @State private var inventory = BarbellCustomizationViewModel()
    @State private var routineStore = RoutineStore()
    @State private var historyStore = HistoryStore()
    @State private var levelViewModel: LevelViewModel
    @State private var weeklyStreakViewModel: WeeklyStreakViewModel
    @State private var currentWeeklyGoalViewModel: CurrentWeeklyGoalViewModel
    @State private var historyListViewModel: HistoryListViewModel
    @State private var requestedRoutineID: String?
    @State private var requestedExerciseAddRoutineID: String?
    @State private var emptyStartRoutineID: String?
    @State private var isDetailPresented = false
    @State private var isHistoryComparisonPresented = false
    @State private var isHistoryGrowthPresented = false
    private let completionTestData: WorkoutCompletionData?
    private let restTimeService: ProfileRestTimeUpdating?
    private let workoutDetailService: WorkoutDetailReading?
    private let photosService: PhotosListing?
    private let activeGoalProgressService: ActiveGoalProgressReading?
    private let apiServiceContainer: APIServiceContainer?

    @MainActor
    init(
        restTimeService: ProfileRestTimeUpdating? = nil,
        apiServiceContainer: APIServiceContainer? = nil
    ) {
        self.restTimeService = restTimeService
#if DEBUG
        let apiServices = apiServiceContainer ?? DebugOnboardingNetworking.makeAPIServiceContainer()
        self.apiServiceContainer = apiServices
        let levelService = apiServices?.level
        let weeklyStreakService = apiServices?.weeklyStreak
        let currentWeeklyGoalService = apiServices?.currentWeeklyGoal
        let arguments = ProcessInfo.processInfo.arguments
        activeGoalProgressService = arguments.contains("--uitest-ephemeral") || arguments.contains("--uitest-no-onboarding-service")
            ? nil
            : apiServices?.goalProgress
#else
        self.apiServiceContainer = apiServiceContainer
        let levelService: UserLevelReading? = nil
        let weeklyStreakService: WeeklyStreakReading? = nil
        let currentWeeklyGoalService: CurrentWeeklyGoalReading? = nil
        activeGoalProgressService = nil
#endif
        _levelViewModel = State(initialValue: LevelViewModel(service: levelService))
        _weeklyStreakViewModel = State(initialValue: WeeklyStreakViewModel(service: weeklyStreakService))
        _currentWeeklyGoalViewModel = State(initialValue: CurrentWeeklyGoalViewModel(service: currentWeeklyGoalService))
        let storageState = Self.makeStorageState()
        let routineStore = storageState.routineStore
        _routineStore = State(initialValue: routineStore)
        _selection = State(initialValue: storageState.selection)
        _historyStore = State(initialValue: storageState.historyStore)
#if DEBUG
        let workoutReadService = apiServices?.workoutRead
        let workoutDetailService = apiServices?.workoutHistory
        let photosService = apiServices?.photos
#else
        let workoutReadService: WorkoutReadAPIService? = nil
        let workoutDetailService: WorkoutDetailReading? = nil
        let photosService: PhotosListing? = nil
#endif
        self.workoutDetailService = workoutDetailService
        self.photosService = photosService
        _historyListViewModel = State(initialValue: HistoryListViewModel(
            service: workoutReadService,
            routineStore: routineStore
        ))
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
                    showsPhotoAction: true,
                    showsPeakGoalActions: false
                )
            } else {
                switch selection {
                case .home:
                    HomeView(
                        onOpenRoutines: {
                            requestedRoutineID = routineStore.routines.first(where: { !$0.isEmpty })?.id
                            selection = .routine
                        },
                        inventory: inventory,
                        historyStore: historyStore,
                        routineStore: routineStore,
                        levelViewModel: levelViewModel,
                        weeklyStreakViewModel: weeklyStreakViewModel,
                        currentWeeklyGoalViewModel: currentWeeklyGoalViewModel,
                        activeGoalProgressService: activeGoalProgressService,
                        onDetailRouteChanged: { isDetailPresented = $0 }
                    )
                case .routine:
                    RoutineView(store: routineStore, historyStore: historyStore,
                                apiServiceContainer: apiServiceContainer,
                                requestedRoutineID: $requestedRoutineID,
                                requestedExerciseAddRoutineID: $requestedExerciseAddRoutineID,
                                onEmptyStartAttempt: { emptyStartRoutineID = $0 },
                                onDetailRouteChanged: { isDetailPresented = $0 })
                case .history:
                    HistoryView(
                        store: historyStore,
                        listViewModel: historyListViewModel,
                        workoutDetailService: workoutDetailService,
                        photosService: photosService,
                        onOpenRoutines: { selection = .routine },
                        onComparisonPresented: { isHistoryComparisonPresented = $0 },
                        onGrowthPresented: { isHistoryGrowthPresented = $0 }
                    )
                case .profile:
                    MyProfileView(
                        historyStore: historyStore,
                        restTimeService: restTimeService,
                        levelViewModel: levelViewModel,
                        onDetailRouteChanged: { isDetailPresented = $0 }
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            let isHistoryDetailPresented = isHistoryComparisonPresented || isHistoryGrowthPresented
            if completionTestData == nil && !isDetailPresented && !(selection == .history && isHistoryDetailPresented) {
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

private extension MainTabView {
    @MainActor
    static func makeStorageState() -> MainTabStorageState {
        let arguments = ProcessInfo.processInfo.arguments
        let storage: UserDefaults? = arguments.contains("--uitest-ephemeral") ? nil : .standard
        let routineStore = RoutineStore(defaults: storage)
        let isGrowthUITest = arguments.contains("--uitest-g5-growth")
        let historyStore = HistoryStore(
            records: isGrowthUITest ? HistorySampleData.growthGraphUITestRecords : [],
            defaults: isGrowthUITest ? nil : storage
        )
        return MainTabStorageState(
            routineStore: routineStore,
            historyStore: historyStore,
            selection: isGrowthUITest ? .history : .home
        )
    }
}
