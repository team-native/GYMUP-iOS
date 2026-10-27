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
                            subtitle: "잠금 화면·Live Activity 포함",
                            isOn: $preferences.restTimerEnabled
                        )
                        separator
                        preferenceToggle(
                            title: "햅틱",
                            subtitle: "Set 완료 · 휴식 종료 시 진동",
                            isOn: $preferences.hapticsEnabled
                        )
                    }
                }

                notificationSection(title: "리마인더") {
                    VStack(spacing: 0) {
                        preferenceToggle(
                            title: "운동 리마인더",
                            subtitle: "운동하는 날 알려드려요",
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
            HStack(alignment: .top, spacing: GymupSpacing.small) {
                Image(systemName: "info.circle")
                    .foregroundStyle(GymupColors.secondaryText)
                    .accessibilityHidden(true)
                Text("알림 권한이 꺼져 있으면 앱 설정이 켜져 있어도 알림이 오지 않아요.")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("알림 권한 상태 확인  >") {
                isPermissionViewPresented = true
            }
            .font(scaledActionTitle)
            .foregroundStyle(GymupColors.accent)
            .frame(minHeight: 44, alignment: .leading)
            .accessibilityHint("iPhone의 시스템 알림 권한 상태를 확인합니다")
        }
        .padding(GymupSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
    }

    private var scaledRowTitle: Font {
        .custom("GothicA1-SemiBold", size: 14, relativeTo: .body)
    }

    private var scaledActionTitle: Font {
        .custom("GothicA1-Bold", size: 13, relativeTo: .body)
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
