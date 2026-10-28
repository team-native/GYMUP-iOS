import SwiftUI
import UserNotifications

struct MyProfileView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isLevelPresented = false
    @State private var isGoalHistoryPresented = false
    @State private var goals: [ProfileGoalRecord]
    @State private var isNotificationSettingsPresented = false
    @State private var isPhotoPermissionsPresented = false
    @State private var restTimeSeconds = 90
    @State private var notificationPreferences = ProfileNotificationPreferences()
    @State private var notificationPermissionSnapshot: ProfileNotificationPermissionSnapshot?
    @State private var isNotificationPermissionPresented = false
    @State private var reminderSchedule = ProfileReminderSchedule()
    @State private var presentedSheet: ProfileSheetDestination?
    @State private var restTimeSheetDetent: PresentationDetent = .height(426)
    @State private var isPlaylistPresented = false

    private let profile: ProfileSummary

    init() {
        let sample = ProfileSampleData.summary
        if let settings = OnboardingStoredSettings.load() {
            let experienceTitles = ["처음", "입문", "중급", "숙련"]
            let types: [ProfileGoalType] = [.body, .strength, .consistency]
            let current = ProfileGoalRecord(type: types[settings.goal], workoutsPerWeek: settings.frequency,
                                            durationWeeks: settings.weeks, period: "진행 중", growth: 0,
                                            completedWeeks: 0, isCurrent: true)
            _goals = State(initialValue: [current])
            profile = ProfileSummary(level: sample.level, stage: sample.stage,
                                     focus: "\(experienceTitles[settings.experience]) · \(settings.purposes.joined(separator: " · "))",
                                     workoutsPerWeek: settings.frequency, currentGoal: current.type.rawValue,
                                     goalDurationWeeks: settings.weeks, restTimeSummary: sample.restTimeSummary,
                                     notificationSummary: sample.notificationSummary,
                                     photoPermissionSummary: sample.photoPermissionSummary)
        } else {
            _goals = State(initialValue: ProfileSampleData.goalHistory)
            profile = sample
        }
    }

    private var currentGoal: ProfileGoalRecord {
        goals.first(where: \.isCurrent) ?? ProfileSampleData.goalHistory[0]
    }

    private var restTimeSummary: String {
        String(format: "%d:%02d", restTimeSeconds / 60, restTimeSeconds % 60)
    }

    private var notificationSummary: String {
        var items: [String] = []
        if notificationPreferences.restTimerEnabled { items.append("휴식 종료") }
        if notificationPreferences.hapticsEnabled { items.append("햅틱") }
        if notificationPreferences.workoutReminderEnabled { items.append("리마인더") }
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
                ProfileGoalHistoryView(goals: $goals)
            }
            .navigationDestination(isPresented: $isNotificationSettingsPresented) {
                ProfileNotificationSettingsView(
                    preferences: $notificationPreferences,
                    schedule: $reminderSchedule,
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
        }
    }

    private var currentGoalSummary: String {
        "\(currentGoal.type.rawValue) · \(currentGoal.durationWeeks)주 · 주 \(currentGoal.workoutsPerWeek)회"
    }

    @ViewBuilder
    private func sheet(for destination: ProfileSheetDestination) -> some View {
        switch destination {
        case .restTime:
            ProfileRestTimeSheetView(selection: $restTimeSeconds)
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
    }
}

struct ProfileGoalWorkoutSection: View {
    let goalSummary: String
    let restTimeSummary: String
    let onGoal: () -> Void
    let onRestTime: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            ProfileSectionTitle("목표 · 운동")
            VStack(spacing: 0) {
                ProfileSettingRow(
                    icon: "target",
                    title: "운동 목표",
                    subtitle: goalSummary,
                    horizontalPadding: 0,
                    action: onGoal
                )
                ProfileRowSeparator()
                ProfileSettingRow(
                    icon: "timer",
                    title: "기본 휴식 시간",
                    subtitle: "운동별 설정이 없을 때 사용",
                    value: restTimeSummary,
                    horizontalPadding: 0,
                    action: onRestTime
                )
            }
            .padding(.horizontal, GymupSpacing.large)
            .background(ProfileOverviewColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
        }
    }
}

struct ProfilePermissionSection: View {
    let notificationSummary: String
    let photoPermissionSummary: String
    let onNotifications: () -> Void
    let onPhotoAccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            ProfileSectionTitle("알림 · 권한")
            VStack(spacing: 0) {
                ProfileSettingRow(
                    icon: "bell",
                    title: "알림 설정",
                    subtitle: notificationSummary,
                    horizontalPadding: 0,
                    action: onNotifications
                )
                ProfileRowSeparator()
                ProfileSettingRow(
                    icon: "camera",
                    title: "카메라 · 사진 권한",
                    subtitle: photoPermissionSummary,
                    horizontalPadding: 0,
                    action: onPhotoAccess
                )
            }
            .padding(.horizontal, GymupSpacing.large)
            .background(ProfileOverviewColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
        }
    }
}

struct ProfilePlaylistSection: View {
    let onPlaylist: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            ProfileSectionTitle("V2")
            ProfileSettingRow(
                icon: "music.note",
                title: "루틴별 플레이리스트",
                subtitle: "Apple Music · Spotify 연결",
                value: "V2",
                action: onPlaylist
            )
            .overlay(alignment: .bottom) { ProfileRowSeparator(horizontalInset: 16) }
        }
    }
}

private struct ProfileSettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String?
    let horizontalPadding: CGFloat
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        icon: String,
        title: String,
        subtitle: String,
        value: String? = nil,
        horizontalPadding: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.horizontalPadding = horizontalPadding
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: GymupSpacing.xSmall / 2) {
                        HStack(spacing: GymupSpacing.medium) {
                            iconView
                            Text(title)
                                .font(ProfileTypography.rowTitle)
                                .foregroundStyle(GymupColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text(subtitle)
                            .font(ProfileTypography.settingSubtitle)
                            .foregroundStyle(ProfileOverviewColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 48)

                        HStack(spacing: GymupSpacing.small) {
                            Spacer(minLength: 0)
                            valueLabel
                            ProfileChevron()
                        }
                    }
                } else {
                    HStack(spacing: GymupSpacing.medium) {
                        iconView
                        VStack(alignment: .leading, spacing: GymupSpacing.xSmall / 2) {
                            Text(title)
                                .font(ProfileTypography.rowTitle)
                                .foregroundStyle(GymupColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(ProfileTypography.settingSubtitle)
                                .foregroundStyle(ProfileOverviewColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        valueLabel
                        ProfileChevron()
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, GymupSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)\(value.map { ", \($0)" } ?? "")")
        .accessibilityHint("설정을 엽니다")
    }

    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(GymupColors.primaryText)
            .frame(width: 30, height: 30)
            .background(ProfileOverviewColors.iconSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var valueLabel: some View {
        if let value {
            Text(value)
                .font(ProfileTypography.level)
                .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxxLarge)
                .foregroundStyle(ProfileOverviewColors.brandPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

private struct ProfileSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(ProfileTypography.section)
            .foregroundStyle(ProfileOverviewColors.secondaryText)
            .frame(minHeight: 20, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct ProfileRowSeparator: View {
    var horizontalInset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(GymupColors.border)
            .frame(height: 1)
            .padding(.horizontal, horizontalInset)
    }
}

#Preview {
    MyProfileView()
        .preferredColorScheme(.dark)
}
