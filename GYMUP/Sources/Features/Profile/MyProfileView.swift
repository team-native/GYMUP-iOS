import SwiftUI

private enum ProfileTypography {
    static let pageTitle = Font.custom("GothicA1-ExtraBold", size: 20, relativeTo: .title2)
    static let level = Font.custom("BarlowCondensed-ExtraBold", size: 18, relativeTo: .title3)
    static let stage = Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption2)
    static let rowTitle = Font.custom("GothicA1-SemiBold", size: 14, relativeTo: .headline)
    static let action = Font.custom("GothicA1-Bold", size: 13, relativeTo: .body)
    static let caption = Font.custom("NotoSansKR-Regular", size: 12, relativeTo: .caption)
    static let section = Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption2)
}

struct MyProfileView: View {
    @State private var isLevelPresented = false
    @State private var isGoalHistoryPresented = false
    @State private var goals = ProfileSampleData.goalHistory
    @State private var isNotificationSettingsPresented = false
    @State private var isPhotoPermissionsPresented = false
    @State private var restTimeSeconds = 90
    @State private var notificationPreferences = ProfileNotificationPreferences()
    @State private var reminderSchedule = ProfileReminderSchedule()
    @State private var presentedSheet: ProfileSheetDestination?

    private let profile = ProfileSampleData.summary

    private var currentGoal: ProfileGoalRecord {
        goals.first(where: \.isCurrent) ?? ProfileSampleData.goalHistory[0]
    }

    private var restTimeSummary: String {
        String(format: "%d:%02d", restTimeSeconds / 60, restTimeSeconds % 60)
    }

    private var notificationSummary: String {
        var items: [String] = []
        if notificationPreferences.restTimerEnabled {
            items.append("휴식 종료")
            items.append("햅틱")
        }
        if notificationPreferences.workoutReminderEnabled { items.append("리마인더") }
        if notificationPreferences.weeklySummaryEnabled { items.append("주간 요약") }
        return items.isEmpty ? "모든 알림 꺼짐" : items.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                    Text("마이")
                        .font(ProfileTypography.pageTitle)
                        .foregroundStyle(GymupColors.primaryText)
                        .accessibilityAddTraits(.isHeader)

                    ProfileLevelCard(profile: profile) { isLevelPresented = true }

                    if !profile.notificationPermissionEnabled {
                        ProfileNotificationPermissionBanner { perform(.notifications) }
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
                .padding(.horizontal, GymupSpacing.large)
                .padding(.top, GymupSpacing.large)
                .padding(.bottom, GymupSpacing.xxLarge)
            }
            .background(GymupColors.canvas)
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
                    schedule: $reminderSchedule
                )
            }
            .navigationDestination(isPresented: $isPhotoPermissionsPresented) {
                ProfilePhotoPermissionView()
            }
            .sheet(item: $presentedSheet) { destination in
                sheet(for: destination)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
        case .playlist:
            ProfilePlaylistSheetView()
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
            presentedSheet = .playlist
        }
    }
}

struct ProfileLevelCard: View {
    let profile: ProfileSummary
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: GymupSpacing.small) {
                        HStack {
                            equipmentImage
                            Spacer(minLength: 0)
                            ProfileChevron()
                        }
                        profileDetails
                    }
                } else {
                    HStack(spacing: GymupSpacing.medium) {
                        equipmentImage
                        profileDetails
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ProfileChevron()
                    }
                }
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.vertical, GymupSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("레벨 \(profile.level), \(profile.stage), 레벨 상세 보기")
        .accessibilityHint("레벨 정보를 확인합니다")
    }

    private var equipmentImage: some View {
        Image("H2EquipmentHeavy")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 40)
            .accessibilityHidden(true)
    }

    private var profileDetails: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: GymupSpacing.small) {
                Text("LV.\(profile.level)")
                    .font(ProfileTypography.level)
                    .foregroundStyle(GymupColors.primaryText)
                Text(profile.stage)
                    .font(ProfileTypography.stage)
                    .foregroundStyle(GymupColors.brandText)
            }
            Text("\(profile.focus) · 주 \(profile.workoutsPerWeek)회")
                .font(ProfileTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ProfileNotificationPermissionBanner: View {
    let onEnable: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    message
                    enableButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(spacing: GymupSpacing.medium) {
                    message
                    enableButton
                }
            }
        }
        .padding(GymupSpacing.medium)
        .background(GymupColors.canvas, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: GymupRadius.medium)
                .strokeBorder(GymupColors.accent, lineWidth: 1)
        }
    }

    private var message: some View {
        HStack(spacing: GymupSpacing.medium) {
            Image(systemName: "bell.badge")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(GymupColors.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text("알림 권한이 꺼져 있어요")
                    .font(ProfileTypography.rowTitle)
                    .foregroundStyle(GymupColors.primaryText)
                Text("휴식 종료 알림을 받을 수 없어요")
                    .font(ProfileTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var enableButton: some View {
        Button("켜기", action: onEnable)
            .font(ProfileTypography.action)
            .foregroundStyle(.white)
            .frame(minWidth: 56, minHeight: 44)
            .background(GymupColors.accent, in: Capsule())
            .buttonStyle(.plain)
            .accessibilityLabel("알림 설정 열기")
            .accessibilityHint("앱의 알림 설정 화면을 엽니다")
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
                    action: onGoal
                )
                ProfileRowSeparator()
                ProfileSettingRow(
                    icon: "timer",
                    title: "기본 휴식 시간",
                    subtitle: "운동별 설정이 없을 때 사용",
                    value: restTimeSummary,
                    action: onRestTime
                )
            }
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
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
                    action: onNotifications
                )
                ProfileRowSeparator()
                ProfileSettingRow(
                    icon: "camera",
                    title: "카메라 · 사진 권한",
                    subtitle: photoPermissionSummary,
                    action: onPhotoAccess
                )
            }
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
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
            .padding(.horizontal, GymupSpacing.medium)
            .overlay(alignment: .bottom) { ProfileRowSeparator() }
        }
    }
}

private struct ProfileSettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String?
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        icon: String,
        title: String,
        subtitle: String,
        value: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: GymupSpacing.small) {
                        HStack(spacing: GymupSpacing.medium) {
                            iconView
                            Text(title)
                                .font(ProfileTypography.rowTitle)
                                .foregroundStyle(GymupColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text(subtitle)
                            .font(ProfileTypography.caption)
                            .foregroundStyle(GymupColors.secondaryText)
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
                        VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                            Text(title)
                                .font(ProfileTypography.rowTitle)
                                .foregroundStyle(GymupColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(ProfileTypography.caption)
                                .foregroundStyle(GymupColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        valueLabel
                        ProfileChevron()
                    }
                }
            }
            .padding(.horizontal, GymupSpacing.medium)
            .padding(.vertical, GymupSpacing.small)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
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
            .frame(width: 36, height: 36)
            .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var valueLabel: some View {
        if let value {
            Text(value)
                .font(ProfileTypography.level)
                .foregroundStyle(GymupColors.brandText)
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
            .foregroundStyle(GymupColors.secondaryText)
            .frame(minHeight: 20, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct ProfileRowSeparator: View {
    var body: some View {
        Rectangle()
            .fill(GymupColors.border)
            .frame(height: 1)
            .padding(.leading, 56)
    }
}

private struct ProfileChevron: View {
    var body: some View {
        Image("H1IconChevronRight")
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .accessibilityHidden(true)
    }
}

#Preview {
    MyProfileView()
        .preferredColorScheme(.dark)
}
