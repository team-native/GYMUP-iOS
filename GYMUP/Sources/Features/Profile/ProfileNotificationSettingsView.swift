import SwiftUI

struct ProfileNotificationSettingsView: View {
    @Binding var preferences: ProfileNotificationPreferences
    @Binding var schedule: ProfileReminderSchedule
    @Environment(\.dismiss) private var dismiss
    @State private var isReminderSchedulePresented = false
    @State private var isPermissionGuidePresented = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                permissionStatusCard

                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    sectionTitle("알림 종류")
                    VStack(spacing: 0) {
                        preferenceToggle(
                            title: "운동 리마인더",
                            subtitle: "선택한 요일과 시간에 운동을 알려드려요.",
                            isOn: $preferences.workoutReminderEnabled
                        )
                        separator
                        preferenceToggle(
                            title: "휴식 종료 알림",
                            subtitle: "세트 간 휴식이 끝나면 알려드려요.",
                            isOn: $preferences.restTimerEnabled
                        )
                        separator
                        preferenceToggle(
                            title: "주간 운동 요약",
                            subtitle: "한 주의 운동 기록을 모아 알려드려요.",
                            isOn: $preferences.weeklySummaryEnabled
                        )
                    }
                    .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
                }

                VStack(alignment: .leading, spacing: GymupSpacing.small) {
                    sectionTitle("운동 리마인더 일정")
                    Button { isReminderSchedulePresented = true } label: {
                        HStack(spacing: GymupSpacing.medium) {
                            Image(systemName: "calendar")
                                .foregroundStyle(GymupColors.primaryText)
                                .frame(width: 36, height: 36)
                                .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                                Text("요일과 시간")
                                    .font(GymupTypography.uiStrong)
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
                    .accessibilityLabel("운동 리마인더 일정, \(schedule.summary)")
                    .accessibilityHint("요일과 시간을 선택합니다")
                }
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
        .alert("알림 권한 안내", isPresented: $isPermissionGuidePresented) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(
                "현재 화면은 앱 안의 알림 설정을 보여주는 샘플입니다. "
                    + "기기 알림 권한이나 iPhone 설정은 변경하지 않습니다."
            )
        }
    }

    private var permissionStatusCard: some View {
        HStack(alignment: .top, spacing: GymupSpacing.medium) {
            Image(systemName: "bell.slash")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(GymupColors.accent)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                HStack {
                    Text("기기 알림 권한")
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Spacer()
                    Text("꺼짐")
                        .font(GymupTypography.label)
                        .foregroundStyle(GymupColors.accent)
                }
                Text("아래 설정은 화면 미리보기용이에요. 권한 상태는 바뀌지 않아요.")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Button("권한 상태 안내") { isPermissionGuidePresented = true }
                    .font(GymupTypography.uiBold)
                    .foregroundStyle(GymupColors.brandText)
                    .frame(minHeight: 44, alignment: .leading)
            }
        }
        .padding(GymupSpacing.medium)
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: GymupRadius.large)
                .strokeBorder(GymupColors.accent.opacity(0.55), lineWidth: 1)
        }
    }

    private func preferenceToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text(title)
                    .font(GymupTypography.uiStrong)
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
        .accessibilityHint("앱 화면의 샘플 알림 설정을 바꿉니다")
    }

    private var separator: some View {
        Rectangle()
            .fill(GymupColors.border)
            .frame(height: 1)
            .padding(.leading, GymupSpacing.large)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(GymupTypography.label)
            .foregroundStyle(GymupColors.secondaryText)
            .frame(minHeight: 20, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    NavigationStack {
        ProfileNotificationSettingsView(
            preferences: .constant(ProfileNotificationPreferences()),
            schedule: .constant(ProfileReminderSchedule())
        )
        .preferredColorScheme(.dark)
    }
}
