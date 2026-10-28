import SwiftUI

enum ProfileOverviewColors {
    static let canvas = Color(red: 11.0 / 255, green: 11.0 / 255, blue: 13.0 / 255)
    static let surface = Color(red: 22.0 / 255, green: 22.0 / 255, blue: 26.0 / 255)
    static let iconSurface = Color(red: 31.0 / 255, green: 31.0 / 255, blue: 36.0 / 255)
    static let secondaryText = Color(red: 161.0 / 255, green: 161.0 / 255, blue: 170.0 / 255)
    static let brandPrimary = Color(red: 255.0 / 255, green: 18.0 / 255, blue: 22.0 / 255)
    static let statusCritical = Color(red: 255.0 / 255, green: 69.0 / 255, blue: 58.0 / 255)
}

enum ProfileTypography {
    static let pageTitle = Font.custom("GothicA1-ExtraBold", size: 20, relativeTo: .title2)
    static let level = Font.custom("BarlowCondensed-ExtraBold", size: 18, relativeTo: .title3)
    static let stage = Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption2)
    static let rowTitle = Font.custom("GothicA1-SemiBold", size: 14, relativeTo: .headline)
    static let settingSubtitle = Font.custom("GothicA1-Medium", size: 11, relativeTo: .caption)
    static let action = Font.custom("GothicA1-Bold", size: 13, relativeTo: .body)
    static let caption = Font.custom("NotoSansKR-Regular", size: 12, relativeTo: .caption)
    static let section = Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption2)
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
                    HStack(spacing: 14) {
                        equipmentImage
                        profileDetails
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ProfileChevron()
                    }
                }
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(ProfileOverviewColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "레벨 \(profile.level), \(profile.stage), \(profile.focus), 주 \(profile.workoutsPerWeek)회, 레벨 상세 보기"
        )
        .accessibilityHint("레벨 정보를 확인합니다")
    }

    private var equipmentImage: some View {
        Image("H2EquipmentHeavy")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 40)
            .frame(width: 96, height: 48)
            .background(ProfileOverviewColors.iconSurface, in: RoundedRectangle(cornerRadius: 12))
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
                .font(ProfileTypography.settingSubtitle)
                .foregroundStyle(ProfileOverviewColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ProfileChevron: View {
    var body: some View {
        Image("H3IconChevronRight")
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .accessibilityHidden(true)
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
                valueColor: GymupColors.tertiaryText,
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
    let valueColor: Color
    let horizontalPadding: CGFloat
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        icon: String,
        title: String,
        subtitle: String,
        value: String? = nil,
        valueColor: Color = GymupColors.brandText,
        horizontalPadding: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.valueColor = valueColor
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
                .foregroundStyle(valueColor)
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
