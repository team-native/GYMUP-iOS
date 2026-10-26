import SwiftUI

enum ProfileTypography {
    static let pageTitle = Font.custom("GothicA1-ExtraBold", size: 20, relativeTo: .title2)
    static let level = Font.custom("BarlowCondensed-ExtraBold", size: 18, relativeTo: .title3)
    static let stage = Font.custom("Archivo-SemiBold", size: 10, relativeTo: .caption2)
    static let rowTitle = Font.custom("GothicA1-SemiBold", size: 14, relativeTo: .headline)
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
                    .foregroundStyle(GymupColors.brandText)
            }
            Text("\(profile.focus) · 주 \(profile.workoutsPerWeek)회")
                .font(ProfileTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
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
