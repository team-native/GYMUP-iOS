import SwiftUI
import UIKit
import UserNotifications

struct ProfileNotificationPermissionView: View {
    @Binding var permissionSnapshot: ProfileNotificationPermissionSnapshot?
    var refreshesPermissionOnAppear = true

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var isRequestingPermission = false
    @State private var requestFailed = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GymupSpacing.xLarge) {
                Image(systemName: statusIcon)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(GymupColors.secondaryText)
                    .frame(width: 64, height: 64)
                    .background(GymupColors.surface, in: Circle())
                    .accessibilityHidden(true)

                VStack(spacing: GymupSpacing.small) {
                    Text(title)
                        .font(GymupTypography.sectionTitle)
                        .foregroundStyle(GymupColors.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Text(description)
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                permissionStatusCard

                if requestFailed {
                    Text("알림 권한 요청을 완료하지 못했어요. 다시 시도해 주세요.")
                        .font(GymupTypography.caption)
                        .foregroundStyle(GymupColors.critical)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("notificationPermission.requestError")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, GymupSpacing.large)
            .padding(.top, GymupSpacing.xxLarge)
            .padding(.bottom, GymupSpacing.large)
        }
        .background(GymupColors.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            closeHeader
                .background(GymupColors.canvas)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ProfileNotificationPermissionActionPanel(
                title: primaryActionTitle,
                hint: primaryActionHint,
                isRequestingPermission: isRequestingPermission,
                isDisabled: permissionSnapshot == nil,
                onPrimaryAction: performPrimaryAction,
                onClose: dismiss.callAsFunction
            )
                .background(GymupColors.canvas)
        }
        .task {
            guard refreshesPermissionOnAppear else { return }
            await refreshPermissionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard refreshesPermissionOnAppear, newPhase == .active else { return }
            Task { await refreshPermissionStatus() }
        }
        .onChange(of: permissionSnapshot) { oldSnapshot, newSnapshot in
            guard let oldSnapshot, let newSnapshot, oldSnapshot != newSnapshot else { return }
            UIAccessibility.post(
                notification: .announcement,
                argument: accessibilityAnnouncement(for: newSnapshot)
            )
        }
    }

    private var closeHeader: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(GymupColors.primaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("알림 권한 안내 닫기")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, GymupSpacing.medium)
    }

    private var permissionStatusCard: some View {
        VStack(spacing: 0) {
            permissionStatusRow(title: "알림 허용", value: authorizationDisplayValue)
            permissionStatusSeparator
            permissionStatusRow(title: "잠금화면", value: permissionSnapshot?.lockScreen.displayValue ?? "—")
            permissionStatusSeparator
            permissionStatusRow(title: "배너", value: permissionSnapshot?.banner.displayValue ?? "—")
        }
        .background(GymupColors.surface, in: RoundedRectangle(cornerRadius: GymupRadius.large))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("notificationPermission.statusCard")
    }

    private var permissionStatusSeparator: some View {
        Rectangle()
            .fill(GymupColors.border)
            .frame(height: 1)
            .padding(.horizontal, GymupSpacing.large)
    }

    private var title: String {
        switch permissionSnapshot?.authorization {
        case .denied:
            "알림이 꺼져 있어요"
        case .notDetermined:
            "알림을 허용해 주세요"
        case .allowed:
            "알림이 켜져 있어요"
        case .unknown:
            "알림 상태를 확인할 수 없어요"
        case nil:
            "알림 상태를 확인하고 있어요"
        }
    }

    private var description: String {
        switch permissionSnapshot?.authorization {
        case .denied:
            "설정 > GYMUP > 알림을 켜면 휴식 종료와 리마인더를 받을 수 있어요."
        case .notDetermined:
            "알림을 허용하면 휴식 종료와 리마인더를 받을 수 있어요."
        case .allowed:
            "잠금화면과 배너 표시 방식은 설정 앱에서 관리할 수 있어요."
        case .unknown:
            "알림 권한 상태를 확인할 수 없어요. 다시 확인해 주세요."
        case nil:
            "현재 기기의 알림 권한 상태를 확인 중입니다."
        }
    }

    private var statusIcon: String {
        permissionSnapshot?.authorization == .allowed ? "bell.badge" : "bell"
    }

    private var authorizationDisplayValue: String {
        permissionSnapshot?.authorization.displayValue ?? "확인 중"
    }

    private var primaryActionTitle: String {
        switch permissionSnapshot?.authorization {
        case .denied, .allowed:
            "설정 열기"
        case .notDetermined:
            isRequestingPermission ? "알림 권한 요청 중" : "알림 허용"
        case .unknown:
            "다시 확인"
        case nil:
            "상태 확인 중"
        }
    }

    private var primaryActionHint: String {
        switch permissionSnapshot?.authorization {
        case .denied, .allowed:
            "GYMUP의 시스템 알림 설정을 엽니다"
        case .notDetermined:
            "휴식 종료와 리마인더 알림 권한을 요청합니다"
        case .unknown, nil:
            "현재 시스템 알림 권한 상태를 다시 확인합니다"
        }
    }

    private func permissionStatusRow(title: String, value: String) -> some View {
        HStack(spacing: GymupSpacing.medium) {
            Text(title)
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(GymupTypography.caption)
                .foregroundStyle(value == "켜짐" ? GymupColors.brandText : GymupColors.secondaryText)
        }
        .padding(.horizontal, GymupSpacing.large)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }

    private func performPrimaryAction() {
        switch permissionSnapshot?.authorization {
        case .denied, .allowed:
            openSystemNotificationSettings()
        case .notDetermined:
            Task { await requestNotificationPermission() }
        case .unknown, nil:
            Task { await refreshPermissionStatus() }
        }
    }

    private func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        Task { @MainActor in
            let didOpen = await UIApplication.shared.open(url)
            guard !didOpen, let fallbackURL = URL(string: UIApplication.openSettingsURLString) else { return }
            await UIApplication.shared.open(fallbackURL)
        }
    }

    private func requestNotificationPermission() async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        requestFailed = false
        defer { isRequestingPermission = false }

        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshPermissionStatus()
        } catch {
            requestFailed = true
            await refreshPermissionStatus()
        }
    }

    private func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionSnapshot = ProfileNotificationPermissionSnapshot(settings: settings)
    }

    private func accessibilityAnnouncement(for snapshot: ProfileNotificationPermissionSnapshot) -> String {
        "알림 허용 \(snapshot.authorization.displayValue), "
            + "잠금화면 \(snapshot.lockScreen.displayValue), "
            + "배너 \(snapshot.banner.displayValue)"
    }
}

private struct ProfileNotificationPermissionActionPanel: View {
    let title: String
    let hint: String
    let isRequestingPermission: Bool
    let isDisabled: Bool
    let onPrimaryAction: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: GymupSpacing.small) {
            Button(action: onPrimaryAction) {
                HStack(spacing: GymupSpacing.small) {
                    if isRequestingPermission {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(title)
                        .font(GymupTypography.uiStrong)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, GymupSpacing.medium)
                .background(GymupColors.accent, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isRequestingPermission || isDisabled)
            .opacity(isRequestingPermission || isDisabled ? 0.6 : 1)
            .accessibilityLabel(title)
            .accessibilityHint(hint)
            .accessibilityIdentifier("notificationPermission.primaryAction")

            Button("닫기", action: onClose)
                .font(GymupTypography.caption)
                .foregroundStyle(GymupColors.secondaryText)
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, GymupSpacing.large)
        .padding(.top, GymupSpacing.small)
        .padding(.bottom, GymupSpacing.small)
    }
}

#Preview("알림 꺼짐") {
    NavigationStack {
        ProfileNotificationPermissionView(
            permissionSnapshot: .constant(
                ProfileNotificationPermissionSnapshot(
                    authorization: .denied,
                    lockScreen: .unavailable,
                    banner: .unavailable
                )
            ),
            refreshesPermissionOnAppear: false
        )
            .preferredColorScheme(.dark)
    }
}
