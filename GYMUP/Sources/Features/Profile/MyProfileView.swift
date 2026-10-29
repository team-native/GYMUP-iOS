import SwiftUI
import UserNotifications

struct MyProfileView: View {
    let onDetailRouteChanged: (Bool) -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isLevelPresented = false
    @State private var isGoalHistoryPresented = false
    var historyStore: HistoryStore = HistoryStore()
    @State private var goalStore = GoalStore.shared
    private var goals: [ProfileGoalRecord] { goalStore.goals(historyStore: historyStore) }
    @State private var isNotificationSettingsPresented = false
    @State private var isPhotoPermissionsPresented = false
    @State private var settings = WorkoutSettings.shared
    @State private var notificationPermissionSnapshot: ProfileNotificationPermissionSnapshot?
    @State private var isNotificationPermissionPresented = false
    @State private var presentedSheet: ProfileSheetDestination?
    @State private var restTimeSheetDetent: PresentationDetent = .height(426)
    @State private var isPlaylistPresented = false

    @MainActor
    init(historyStore: HistoryStore? = nil, onDetailRouteChanged: @escaping (Bool) -> Void = { _ in }) {
        self.historyStore = historyStore ?? HistoryStore()
        self.onDetailRouteChanged = onDetailRouteChanged
    }

    private var profile: ProfileSummary {
        let settings = goalStore.settings
        let growth = GrowthViewModel(historyStore: historyStore, goalSettings: settings)
        let experienceTitles = ["처음", "입문", "중급", "숙련"]
        return ProfileSummary(
            level: ProfileSampleData.summary.level, stage: growth.currentStage.title,
            focus: settings.map { "\(experienceTitles[$0.experience]) · \($0.purposes.joined(separator: " · "))" } ?? "목표를 설정해 주세요",
            workoutsPerWeek: settings?.frequency ?? 3, currentGoal: growth.goalTitle,
            goalDurationWeeks: settings?.weeks ?? 12, restTimeSummary: restTimeSummary,
            notificationSummary: notificationSummary, photoPermissionSummary: "오운완 사진 촬영 · 저장"
        )
    }

    private var currentGoal: ProfileGoalRecord {
        goals.first(where: \.isCurrent) ?? ProfileGoalRecord(type: .body, workoutsPerWeek: 3,
            durationWeeks: 12, period: "목표 설정 필요", growth: 0, completedWeeks: 0, isCurrent: true)
    }

    private var restTimeSummary: String {
        String(format: "%d:%02d", settings.restSeconds / 60, settings.restSeconds % 60)
    }

    private var notificationSummary: String {
        var items: [String] = []
        if settings.preferences.restTimerEnabled { items.append("휴식 종료") }
        if settings.preferences.hapticsEnabled { items.append("햅틱") }
        if settings.preferences.workoutReminderEnabled { items.append("리마인더") }
        return items.isEmpty ? "모든 알림 꺼짐" : items.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                HStack {
                    Text("마이")
                        .font(ProfileTypography.pageTitle)
                        .foregroundStyle(GymupColors.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 48, alignment: .leading)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        ProfileLevelCard(profile: profile) { isLevelPresented = true }

                        if let notificationPermissionSnapshot,
                           notificationPermissionSnapshot.shouldShowPermissionBanner {
                            ProfileNotificationPermissionBanner(
                                authorization: notificationPermissionSnapshot.authorization,
                                onEnable: { isNotificationPermissionPresented = true }
                            )
                        }

                        ProfileGoalWorkoutSection(
                            goalSummary: currentGoalSummary,
                            restTimeSummary: restTimeSummary,
                            onGoal: { perform(.goals) },
                            onRestTime: { perform(.restTime) }
                        )
                        ProfilePermissionSection(
                            notificationSummary: notificationSummary,
                            photoPermissionSummary: profile.photoPermissionSummary,
                            onNotifications: { perform(.notifications) },
                            onPhotoAccess: { perform(.photoAccess) }
                        )
                        ProfilePlaylistSection { perform(.playlist) }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 120 : GymupSpacing.xxLarge)
                }
            }
            .background(ProfileOverviewColors.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isLevelPresented) {
                LevelView(onNavigationStateChanged: { _ in })
            }
            .navigationDestination(isPresented: $isGoalHistoryPresented) {
                ProfileGoalHistoryView(historyStore: historyStore)
            }
            .navigationDestination(isPresented: $isNotificationSettingsPresented) {
                ProfileNotificationSettingsView(
                    preferences: $settings.preferences,
                    schedule: $settings.schedule,
                    permissionSnapshot: $notificationPermissionSnapshot
                )
            }
            .navigationDestination(isPresented: $isNotificationPermissionPresented) {
                ProfileNotificationPermissionView(permissionSnapshot: $notificationPermissionSnapshot)
            }
            .navigationDestination(isPresented: $isPhotoPermissionsPresented) {
                ProfilePhotoPermissionView()
            }
            .navigationDestination(isPresented: $isPlaylistPresented) {
                ProfilePlaylistView()
            }
            .sheet(item: $presentedSheet) { destination in
                sheet(for: destination)
                    .presentationDetents([.height(426), .large], selection: $restTimeSheetDetent)
                    .presentationDragIndicator(.visible)
            }
            .task {
                await refreshNotificationPermissionStatus()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task { await refreshNotificationPermissionStatus() }
            }
            .onChange(of: hasPresentedDetail) { _, isPresented in
                onDetailRouteChanged(isPresented)
            }
            .onAppear { onDetailRouteChanged(hasPresentedDetail) }
        }
    }

    private var hasPresentedDetail: Bool {
        isLevelPresented
            || isGoalHistoryPresented
            || isNotificationSettingsPresented
            || isPhotoPermissionsPresented
            || isNotificationPermissionPresented
            || isPlaylistPresented
            || presentedSheet != nil
    }

    private var currentGoalSummary: String {
        "\(currentGoal.type.rawValue) · \(currentGoal.durationWeeks)주 · 주 \(currentGoal.workoutsPerWeek)회"
    }

    @ViewBuilder
    private func sheet(for destination: ProfileSheetDestination) -> some View {
        switch destination {
        case .restTime:
            ProfileRestTimeSheetView(selection: $settings.restSeconds)
        }
    }

    private func perform(_ action: ProfileAction) {
        switch action {
        case .goals:
            isGoalHistoryPresented = true
        case .restTime:
            presentedSheet = .restTime
        case .notifications:
            isNotificationSettingsPresented = true
        case .photoAccess:
            isPhotoPermissionsPresented = true
        case .playlist:
            isPlaylistPresented = true
        }
    }

    @MainActor
    private func refreshNotificationPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationPermissionSnapshot = ProfileNotificationPermissionSnapshot(settings: settings)
        await self.settings.refreshReminders()
    }
}

#Preview {
    MyProfileView()
        .preferredColorScheme(.dark)
}
