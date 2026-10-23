import SwiftUI

struct HomeView: View {
    let onOpenRoutines: () -> Void
    let onGrowthRouteChanged: (Bool) -> Void
    @State private var viewModel = HomeViewModel()

    init(
        onOpenRoutines: @escaping () -> Void,
        onGrowthRouteChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.onOpenRoutines = onOpenRoutines
        self.onGrowthRouteChanged = onGrowthRouteChanged
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                        .frame(height: 56)
                    VStack(spacing: 16) {
                        NavigationLink {
                            GrowthView(onNavigationStateChanged: onGrowthRouteChanged)
                        } label: {
                            growthCard
                        }
                        .buttonStyle(.plain)
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
        }
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
            HStack(spacing: 6) {
                Image("H1IconZap")
                    .resizable()
                    .frame(width: 14, height: 14)
                Text("LV.\(viewModel.level)")
                    .font(.custom("BarlowCondensed-Bold", size: 15))
                    .tracking(0.13)
                    .foregroundStyle(GymupColors.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.12, green: 0.12, blue: 0.14), in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var growthCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(viewModel.stageTitle)
                    .font(GymupTypography.label)
                    .tracking(0.17)
                    .foregroundStyle(Color(red: 1, green: 0.42, blue: 0.43))
                Spacer(minLength: 6)
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
                .background(Color(red: 0.23, green: 0.07, blue: 0.08), in: RoundedRectangle(cornerRadius: 14))
            }
            equipment
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("GROWTH")
                    .font(GymupTypography.label)
                    .tracking(0.17)
                    .foregroundStyle(GymupColors.secondaryText)
                Text("\(viewModel.growth)")
                    .font(GymupTypography.metric)
                    .tracking(0.13)
                    .foregroundStyle(GymupColors.primaryText)
                Text("/100")
                    .font(GymupTypography.uiMedium)
                    .foregroundStyle(Color(red: 0.42, green: 0.42, blue: 0.46))
                Spacer()
                Text("다음 원판까지 \(viewModel.nextPlateProgress)")
                    .font(GymupTypography.uiCaption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(red: 0.16, green: 0.16, blue: 0.19))
                    Capsule()
                        .fill(GymupColors.accent)
                        .frame(width: geometry.size.width * 0.687)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(height: 318)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }

    private var equipment: some View {
        VStack(spacing: 0) {
            Image("H1Equipment")
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
            NavigationLink {
                WeeklyGoalView(onNavigationStateChanged: onGrowthRouteChanged)
            } label: {
                statistic(
                    icon: "H1IconCalendar",
                    value: "\(viewModel.weeklyWorkoutCount)/\(viewModel.weeklyWorkoutGoal)",
                    title: "이번 주 운동"
                )
            }
            NavigationLink {
                WeeklyGoalView(onNavigationStateChanged: onGrowthRouteChanged)
            } label: {
                statistic(icon: "H1IconFlame", value: "\(viewModel.streakWeeks)주", title: "Streak")
            }
            statistic(icon: "H1IconZap", value: viewModel.experiencePoints.formatted(), title: "XP")
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
}

#Preview {
    HomeView(onOpenRoutines: {})
}
