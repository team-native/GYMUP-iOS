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
                    .foregroundStyle(ProfileOverviewColors.brandPrimary)
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
        Image("H1IconChevronRight")
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .accessibilityHidden(true)
    }
}
