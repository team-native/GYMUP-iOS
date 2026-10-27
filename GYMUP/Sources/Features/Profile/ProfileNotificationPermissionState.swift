import UserNotifications

enum ProfileNotificationAuthorizationState: Equatable {
    case notDetermined
    case denied
    case allowed
    case unknown

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized, .provisional, .ephemeral:
            self = .allowed
        @unknown default:
            self = .unknown
        }
    }

    var shouldShowPermissionBanner: Bool {
        self != .allowed
    }

    var displayValue: String {
        switch self {
        case .notDetermined: "미결정"
        case .denied: "꺼짐"
        case .allowed: "켜짐"
        case .unknown: "확인 중"
        }
    }
}

enum ProfileNotificationSettingState: Equatable {
    case enabled
    case disabled
    case unavailable

    init(_ setting: UNNotificationSetting) {
        switch setting {
        case .enabled:
            self = .enabled
        case .disabled:
            self = .disabled
        case .notSupported:
            self = .unavailable
        @unknown default:
            self = .unavailable
        }
    }

    var displayValue: String {
        switch self {
        case .enabled: "켜짐"
        case .disabled: "꺼짐"
        case .unavailable: "—"
        }
    }
}

struct ProfileNotificationPermissionSnapshot: Equatable {
    let authorization: ProfileNotificationAuthorizationState
    let lockScreen: ProfileNotificationSettingState
    let banner: ProfileNotificationSettingState

    init(settings: UNNotificationSettings) {
        let authorization = ProfileNotificationAuthorizationState(settings.authorizationStatus)
        self.authorization = authorization

        guard authorization == .allowed else {
            lockScreen = .unavailable
            banner = .unavailable
            return
        }

        lockScreen = ProfileNotificationSettingState(settings.lockScreenSetting)
        banner = ProfileNotificationSettingState(settings.bannerSetting)
    }

    init(
        authorization: ProfileNotificationAuthorizationState,
        lockScreen: ProfileNotificationSettingState,
        banner: ProfileNotificationSettingState
    ) {
        self.authorization = authorization
        self.lockScreen = lockScreen
        self.banner = banner
    }

    var shouldShowPermissionBanner: Bool {
        authorization.shouldShowPermissionBanner
    }
}
