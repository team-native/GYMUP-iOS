import SwiftUI

private enum HomeRoute: Hashable {
    case growth, weeklyGoal, level, customization, goalHistory
}

struct HomeView: View {
    let onOpenRoutines: () -> Void
    let onDetailRouteChanged: (Bool) -> Void
    private let historyStore: HistoryStore?
    @State private var viewModel = HomeViewModel()
    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    @AppStorage("onboarding.frequency") private var onboardingFrequency = 3
    @Bindable private var inventory: BarbellCustomizationViewModel
    @State private var path: [HomeRoute] = []
    @State private var isNewItemPresented = false
    @State private var shouldOpenCustomization = false

    init(
        onOpenRoutines: @escaping () -> Void,
        inventory: BarbellCustomizationViewModel,
        historyStore: HistoryStore? = nil,
        onDetailRouteChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.onOpenRoutines = onOpenRoutines
        self.inventory = inventory
        self.historyStore = historyStore
        self.onDetailRouteChanged = onDetailRouteChanged
    }

    private var weeklyGoal: Int {
        onboardingCompleted ? min(max(onboardingFrequency, 1), 7) : viewModel.weeklyWorkoutGoal
    }

    private var weeklyRecords: [WorkoutRecord]? {
        guard onboardingCompleted, let historyStore,
              let week = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return nil }
        return historyStore.records.filter { week.contains($0.date) }
    }

    private var weeklyCount: Int { weeklyRecords?.count ?? viewModel.weeklyWorkoutCount }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                        .frame(height: 56)
                    VStack(spacing: 16) {
                        growthCard
                        statistics
                        todayRoutine
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 0)
                .padding(.bottom, 24)
            }
            .background(GymupColors.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self, destination: destination)
        }
        .overlay {
            if isNewItemPresented {
                Color.black.opacity(0.7).ignoresSafeArea().allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $isNewItemPresented, onDismiss: finishUnlockPresentation) {
            NewItemUnlockView(onEquip: equipNewItem, onLater: { isNewItemPresented = false })
                .presentationDetents([.height(409)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
                .presentationBackground(GymupColors.surface)
        }
        .onChange(of: path) { _, newPath in
            onDetailRouteChanged(!newPath.isEmpty)
        }
        .onAppear { onDetailRouteChanged(!path.isEmpty) }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.dateTitle)
                    .font(GymupTypography.homeDate)
                    .foregroundStyle(GymupColors.secondaryText)
                Text("오늘도 한 단계 위로")
                    .font(GymupTypography.homeTitle)
                    .tracking(-0.43)
                    .foregroundStyle(GymupColors.primaryText)
            }
            Spacer()
            NavigationLink(value: HomeRoute.level) {
                HStack(spacing: 6) {
                    Image("H1IconZap")
                        .resizable()
                        .frame(width: 14, height: 14)
                    Text("LV.\(viewModel.level)")
                        .font(GymupTypography.number)
                        .tracking(0.13)
                        .foregroundStyle(GymupColors.primaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.12, green: 0.12, blue: 0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var growthCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(viewModel.stageTitle)
                    .font(GymupTypography.label)
                    .tracking(0.17)
                    .foregroundStyle(GymupColors.brandText)
                Spacer(minLength: 6)
                if inventory.hasNewItem {
                    Button { isNewItemPresented = true } label: { newItemBanner }
                        .buttonStyle(.plain)
                }
            }
            NavigationLink(value: HomeRoute.growth) {
                VStack(spacing: 12) {
                    equipment
                    HomeGrowthSummaryView(growth: viewModel.growth, nextPlateProgress: viewModel.nextPlateProgress)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(height: 318)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var newItemBanner: some View {
        HStack(spacing: 10) {
            Image("H1IconSparkle")
                .resizable()
                .frame(width: 16, height: 16)
            Text(viewModel.rewardNotice)
                .font(GymupTypography.uiMedium)
                .tracking(-0.09)
                .lineLimit(1)
            Image("H1IconChevronRight")
                .resizable()
                .frame(width: 16, height: 16)
        }
        .foregroundStyle(GymupColors.primaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(GymupColors.brandSubtle, in: RoundedRectangle(cornerRadius: 14))
    }

    private var equipment: some View {
        VStack(spacing: 0) {
            Image(inventory.equippedPlateID == .blackPlate ? "H6Equipment" : "H1Equipment")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 150)
            Text("\(viewModel.barbellWeight) KG")
                .font(GymupTypography.display)
                .lineSpacing(-1)
                .foregroundStyle(GymupColors.primaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var statistics: some View {
        HStack(spacing: 8) {
            NavigationLink(value: HomeRoute.weeklyGoal) {
                statistic(
                    icon: "H1IconCalendar",
                    value: "\(weeklyCount)/\(weeklyGoal)",
                    title: "이번 주 운동"
                )
            }
            NavigationLink(value: HomeRoute.weeklyGoal) {
                statistic(icon: "H1IconFlame", value: "\(viewModel.streakWeeks)주", title: "Streak")
            }
            NavigationLink(value: HomeRoute.level) {
                statistic(icon: "H1IconZap", value: viewModel.experiencePoints.formatted(), title: "XP")
            }
        }
        .buttonStyle(.plain)
        .frame(height: 91)
    }

    private func statistic(icon: String, value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(icon)
                .resizable()
                .frame(width: 18, height: 18)
            Text(value)
                .font(GymupTypography.metric)
                .tracking(0.13)
                .foregroundStyle(GymupColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(GymupTypography.uiCaption)
                .foregroundStyle(GymupColors.secondaryText)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var todayRoutine: some View {
        Button(action: onOpenRoutines) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    Image("H1RoutinePhoto")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    LinearGradient(
                        colors: [.clear, GymupColors.canvas.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    VStack(alignment: .leading, spacing: 0) {
                        Text("오늘의 루틴")
                            .font(GymupTypography.uiCaption)
                            .foregroundStyle(GymupColors.secondaryText)
                        Text(viewModel.todayRoutine)
                            .font(GymupTypography.display)
                            .foregroundStyle(GymupColors.primaryText)
                    }
                    .position(x: 83, y: 80)
                    Text("시작")
                        .font(GymupTypography.uiBold)
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 34)
                        .background(GymupColors.accent, in: Capsule())
                        .position(x: geometry.size.width - 44, y: 93)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(height: 132)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func destination(for route: HomeRoute) -> some View {
        switch route {
        case .growth:
            GrowthView(onNavigationStateChanged: { _ in }, onOpenHistory: { path.append(.goalHistory) })
        case .weeklyGoal:
            WeeklyGoalView(onNavigationStateChanged: { _ in }, goal: weeklyGoal, records: weeklyRecords)
        case .level:
            LevelView(onNavigationStateChanged: { _ in })
        case .goalHistory:
            GoalHistoryView()
        case .customization:
            BarbellCustomizationView(
                viewModel: inventory,
                onNavigationStateChanged: { _ in },
                onOpenNewItem: { isNewItemPresented = true }
            )
        }
    }

    private func equipNewItem() {
        guard inventory.equipPlate(.blackPlate) else { return }
        shouldOpenCustomization = true
        isNewItemPresented = false
    }

    private func finishUnlockPresentation() {
        guard shouldOpenCustomization else { return }
        shouldOpenCustomization = false
        if path.last != .customization { path.append(.customization) }
    }
}

#Preview {
    HomeView(onOpenRoutines: {}, inventory: BarbellCustomizationViewModel())
}
