import SwiftUI

struct MyProfileView: View {
    @State private var isAlertPresented = false
    @State private var alertMessage = ""

    private let profile = ProfileSampleData.summary

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GymupSpacing.xLarge) {
                Text("마이")
                    .font(GymupTypography.homeTitle)
                    .foregroundStyle(GymupColors.primaryText)
                    .accessibilityAddTraits(.isHeader)

                levelCard

                if !profile.notificationPermissionEnabled {
                    notificationPermissionBanner
                }

                goalAndWorkoutSection
                permissionSection
                playlistSection
            }
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.large)
            .padding(.bottom, GymupSpacing.xxLarge)
        }
        .background(GymupColors.canvas)
        .alert("화면 안내", isPresented: $isAlertPresented) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var levelCard: some View {
        actionButton(.level) {
            HStack(spacing: GymupSpacing.medium) {
                Image("H2EquipmentHeavy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 40)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    HStack(alignment: .firstTextBaseline, spacing: GymupSpacing.small) {
                        Text("LV.\(profile.level)")
                            .font(GymupTypography.metric)
                            .foregroundStyle(GymupColors.primaryText)
                        Text(profile.stage)
                            .font(GymupTypography.label)
                            .foregroundStyle(GymupColors.brandText)
                    }
                    Text("\(profile.focus) · 주 \(profile.workoutsPerWeek)회")
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                chevron
            }
            .padding(.horizontal, GymupSpacing.large)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
        }
        .accessibilityLabel("레벨 \(profile.level), \(profile.stage), 프로필 상세 보기")
        .accessibilityHint("레벨 정보를 확인합니다")
    }

    private var notificationPermissionBanner: some View {
        HStack(spacing: GymupSpacing.medium) {
            Image(systemName: "bell.badge")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(GymupColors.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                Text("알림 권한이 꺼져 있어요")
                    .font(GymupTypography.uiStrong)
                    .foregroundStyle(GymupColors.primaryText)
                Text("휴식 종료 알림을 받을 수 없어요")
                    .font(GymupTypography.caption)
                    .foregroundStyle(GymupColors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("켜기") { showPlaceholder(for: .notifications) }
                .font(GymupTypography.uiBold)
                .foregroundStyle(.white)
                .frame(minWidth: 56, minHeight: 44)
                .background(GymupColors.accent, in: Capsule())
                .buttonStyle(.plain)
                .accessibilityHint("알림 설정 화면을 엽니다")
        }
        .padding(GymupSpacing.medium)
        .background(GymupColors.canvas, in: RoundedRectangle(cornerRadius: GymupRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: GymupRadius.medium)
                .strokeBorder(GymupColors.accent, lineWidth: 1)
        }
    }

    private var goalAndWorkoutSection: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            sectionLabel("목표 · 운동")
            VStack(spacing: 0) {
                settingRow(
                    icon: "target",
                    title: "운동 목표",
                    subtitle: "\(profile.currentGoal) · \(profile.goalDurationWeeks)주 · 주 \(profile.workoutsPerWeek)회",
                    action: .goals
                )
                rowSeparator
                settingRow(
                    icon: "timer",
                    title: "기본 휴식 시간",
                    subtitle: "운동별 설정이 없을 때 사용",
                    value: profile.restTimeSummary,
                    action: .restTime
                )
            }
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
        }
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            sectionLabel("알림 · 권한")
            VStack(spacing: 0) {
                settingRow(
                    icon: "bell",
                    title: "알림 설정",
                    subtitle: profile.notificationSummary,
                    action: .notifications
                )
                rowSeparator
                settingRow(
                    icon: "camera",
                    title: "카메라 · 사진 권한",
                    subtitle: profile.photoPermissionSummary,
                    action: .photoAccess
                )
            }
            .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
        }
    }

    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: GymupSpacing.small) {
            sectionLabel("V2")
            settingRow(
                icon: "music.note",
                title: "루틴별 플레이리스트",
                subtitle: "Apple Music · Spotify 연결",
                value: "V2",
                action: .playlist
            )
            .padding(.horizontal, GymupSpacing.medium)
            .overlay(alignment: .bottom) { rowSeparator }
        }
    }

    private var rowSeparator: some View {
        Rectangle()
            .fill(GymupColors.border)
            .frame(height: 1)
            .padding(.leading, 56)
    }

    private var chevron: some View {
        Image("H1IconChevronRight")
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .accessibilityHidden(true)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(GymupTypography.label)
            .foregroundStyle(GymupColors.secondaryText)
            .frame(minHeight: 20, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private func settingRow(
        icon: String,
        title: String,
        subtitle: String,
        value: String? = nil,
        action: ProfileAction
    ) -> some View {
        actionButton(action) {
            HStack(spacing: GymupSpacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(GymupColors.elevatedSurface, in: RoundedRectangle(cornerRadius: GymupRadius.small))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: GymupSpacing.xSmall) {
                    Text(title)
                        .font(GymupTypography.uiStrong)
                        .foregroundStyle(GymupColors.primaryText)
                    Text(subtitle)
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let value {
                    Text(value)
                        .font(GymupTypography.metric)
                        .foregroundStyle(GymupColors.brandText)
                        .lineLimit(1)
                }

                chevron
            }
            .padding(.horizontal, GymupSpacing.medium)
            .padding(.vertical, GymupSpacing.small)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("\(title), \(subtitle)\(value.map { ", \($0)" } ?? "")")
        .accessibilityHint("설정을 엽니다")
    }

    private func actionButton<Label: View>(
        _ action: ProfileAction,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button { showPlaceholder(for: action) } label: {
            label()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func showPlaceholder(for action: ProfileAction) {
        alertMessage = action.message
        isAlertPresented = true
    }
}

#Preview {
    MyProfileView()
        .preferredColorScheme(.dark)
}
