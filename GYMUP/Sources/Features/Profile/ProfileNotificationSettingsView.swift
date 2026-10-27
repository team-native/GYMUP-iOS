import SwiftUI

struct ProfileNotificationSettingsView: View {
    @Binding var preferences: ProfileNotificationPreferences
    @Binding var schedule: ProfileReminderSchedule
    @Binding var permissionSnapshot: ProfileNotificationPermissionSnapshot?
    @Environment(\.dismiss) private var dismiss
    @State private var isReminderSchedulePresented = false
    @State private var isPermissionViewPresented = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                notificationSection(title: "운동 중") {
                    VStack(spacing: 0) {
                        preferenceToggle(
                            title: "휴식 종료 알림",
                            subtitle: "잠금화면·Live Activity 포함",
                            isOn: $preferences.restTimerEnabled
                        )
                        separator
                        preferenceToggle(
                            title: "햅틱",
                            subtitle: "Set 종료·휴식 종료 시 진동",
                            isOn: $preferences.hapticsEnabled
                        )
                    }
                }

                notificationSection(title: "리마인더") {
                    VStack(spacing: 0) {
                        preferenceToggle(
                            title: "운동 리마인더",
                            subtitle: "운동하는 날만 알려드려요",
                            isOn: $preferences.workoutReminderEnabled
                        )
                        separator
                        reminderScheduleRow
                    }
                }

                permissionInfoCard
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.large)
            .padding(.bottom, GymupSpacing.xxLarge)
        }
        .background(GymupColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            GymupDetailNavigationBar(title: "알림 설정", onBack: { dismiss() })
                .background(GymupColors.canvas)
        }
        .navigationDestination(isPresented: $isReminderSchedulePresented) {
            ProfileReminderScheduleView(schedule: $schedule)
        }
        .navigationDestination(isPresented: $isPermissionViewPresented) {
            ProfileNotificationPermissionView(permissionSnapshot: $permissionSnapshot)
        }
    }

    private var reminderScheduleRow: some View {
        Button { isReminderSchedulePresented = true } label: {
            HStack(spacing: GymupSpacing.medium) {
                Image(systemName: "calendar")
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text("일정")
                        .font(scaledRowTitle)
                        .foregroundStyle(GymupColors.primaryText)
                    Text(schedule.summary)
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image("H1IconChevronRight")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }
            .padding(GymupSpacing.medium)
            .frame(minHeight: 68)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("일정, \(schedule.summary)")
        .accessibilityHint("운동 리마인더를 받을 요일과 시간을 선택합니다")
    }

    private var permissionInfoCard: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(ProfileNotificationSettingsStyle.secondaryText)
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
                Text("알림 권한이 꺼져 있으면 위 설정이 켜져 있어도 알림이 오지 않아요.")
                    .font(.custom("GothicA1-Medium", size: 11, relativeTo: .caption))
                    .foregroundStyle(ProfileNotificationSettingsStyle.secondaryText)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 30, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(
                ProfileNotificationSettingsStyle.surface,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )

            Button {
                isPermissionViewPresented = true
            } label: {
                HStack(spacing: 6) {
                    Text("알림 권한 상태 확인")
                        .font(.custom("GothicA1-Medium", size: 13, relativeTo: .footnote))
                        .foregroundStyle(GymupColors.brandText)
                    Image("H1IconChevronRight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44, alignment: .leading)
            .accessibilityLabel("알림 권한 상태 확인")
            .accessibilityHint("iPhone의 시스템 알림 권한 상태를 확인합니다")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scaledRowTitle: Font {
        .custom("GothicA1-SemiBold", size: 14, relativeTo: .body)
    }

    private func notificationSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            sectionTitle(title)
            content()
                .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
        }
    }

    private func preferenceToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text(title)
                    .font(scaledRowTitle)
                    .foregroundStyle(GymupColors.primaryText)
                Text(subtitle)
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(GymupColors.accent)
        .padding(.horizontal, GymupSpacing.medium)
        .padding(.vertical, GymupSpacing.small)
        .frame(minHeight: 68)
        .accessibilityLabel(title)
        .accessibilityValue(isOn.wrappedValue ? "켜짐" : "꺼짐")
        .accessibilityHint("\(subtitle). 앱 화면의 샘플 설정을 바꿉니다")
    }

    private var separator: some View {
        Rectangle()
            .fill(GymupColors.border)
            .frame(height: 1)
            .padding(.leading, GymupSpacing.large)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.custom("Archivo-SemiBold", size: 10, relativeTo: .caption2))
            .foregroundStyle(GymupColors.secondaryText)
            .frame(minHeight: 20, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

private enum ProfileNotificationSettingsStyle {
    static let surface = Color(red: 22.0 / 255, green: 22.0 / 255, blue: 26.0 / 255)
    static let secondaryText = Color(red: 161.0 / 255, green: 161.0 / 255, blue: 170.0 / 255)
}

#Preview {
    NavigationStack {
        ProfileNotificationSettingsView(
            preferences: .constant(ProfileNotificationPreferences()),
            schedule: .constant(ProfileReminderSchedule()),
            permissionSnapshot: .constant(nil)
        )
        .preferredColorScheme(.dark)
    }
}
