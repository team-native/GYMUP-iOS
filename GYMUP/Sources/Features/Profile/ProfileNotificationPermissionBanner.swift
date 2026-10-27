import SwiftUI

struct ProfileNotificationPermissionBanner: View {
    let authorization: ProfileNotificationAuthorizationState
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
                Text(title)
                    .font(ProfileTypography.rowTitle)
                    .foregroundStyle(GymupColors.primaryText)
                Text(detail)
                    .font(ProfileTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
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
            .accessibilityHint("시스템 알림 권한 상태와 설정 화면을 엽니다")
    }

    private var title: String {
        switch authorization {
        case .denied: "알림 권한이 꺼져 있어요"
        case .notDetermined: "알림을 허용해 주세요"
        case .allowed: "알림이 켜져 있어요"
        case .unknown: "알림 상태를 확인해 주세요"
        }
    }

    private var detail: String {
        switch authorization {
        case .denied: "휴식 종료와 리마인더를 받을 수 없어요"
        case .notDetermined: "휴식 종료와 리마인더 알림을 받을 수 있어요"
        case .allowed: "잠금화면과 배너 표시 방식을 확인할 수 있어요"
        case .unknown: "알림 설정에서 권한을 확인할 수 있어요"
        }
    }
}
