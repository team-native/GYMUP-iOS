import ProjectDescription

let project = Project(
    name: "GYMUP",
    packages: [
        .remote(url: "https://github.com/spotify/ios-sdk.git", requirement: .exact("5.0.1")),
    ],
    targets: [
        .target(
            name: "GYMUP",
            destinations: .iOS,
            product: .app,
            bundleId: "com.teamnative.gymup",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    // Release builds inject this build setting. An unset value remains invalid and disables API services.
                    "GYMUP_API_BASE_URL": "$(GYMUP_API_BASE_URL)",
                    "GYMUP_SPOTIFY_CLIENT_ID": "$(GYMUP_SPOTIFY_CLIENT_ID)",
                    "GYMUP_SPOTIFY_REDIRECT_URI": "com.teamnative.gymup.spotify://oauth/callback",
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLName": "com.teamnative.gymup.spotify",
                            "CFBundleURLSchemes": ["com.teamnative.gymup.spotify"],
                        ],
                    ],
                    "UILaunchScreen": [:],
                    "NSSupportsLiveActivities": true,
                    "NSCameraUsageDescription": "운동 기록 사진을 촬영하기 위해 카메라 접근 권한이 필요합니다.",
                    "NSAppleMusicUsageDescription": "운동 중 선택한 Apple Music 플레이리스트를 재생하기 위해 음악 접근 권한이 필요합니다.",
                    "UIBackgroundModes": ["audio"],
                    "LSApplicationQueriesSchemes": ["spotify"],
                    "UIAppFonts": [
                        "NotoSansKR[wght].ttf",
                        "Fonts/GothicA1-Medium.ttf",
                        "Fonts/GothicA1-SemiBold.ttf",
                        "Fonts/GothicA1-Bold.ttf",
                        "Fonts/GothicA1-ExtraBold.ttf",
                        "Fonts/BarlowCondensed-Black.ttf",
                        "Fonts/BarlowCondensed-Bold.ttf",
                        "Fonts/BarlowCondensed-ExtraBold.ttf",
                        "Fonts/Archivo[wdth,wght].ttf",
                    ],
                ]
            ),
            sources: ["GYMUP/Sources/**"],
            resources: [
                "GYMUP/Resources/Assets.xcassets",
                .folderReference(path: "GYMUP/Resources/Fonts"),
                "GYMUP/Resources/*.ttf",
            ],
            dependencies: [
                .target(name: "GYMUPWidgetExtension"),
                .package(product: "SpotifyiOS"),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "",
                    "CODE_SIGN_ENTITLEMENTS": "GYMUP/GYMUP.entitlements",
                ],
                configurations: [
                    .debug(
                        name: "Debug",
                        // Preserve the ATS nested dictionary from a complete Debug-only plist.
                        settings: [
                            "GENERATE_INFOPLIST_FILE": "NO",
                            "INFOPLIST_FILE": "$(SRCROOT)/Config/Info-Debug.plist",
                        ]
                    ),
                    .release(name: "Release", settings: [:])
                ]
            )
        ),
        .target(
            name: "GYMUPWidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.teamnative.gymup.widgets",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                    ],
                    "NSSupportsLiveActivities": true,
                    "UIAppFonts": [
                        "Fonts/BarlowCondensed-Black.ttf",
                        "Fonts/BarlowCondensed-Bold.ttf",
                        "Fonts/BarlowCondensed-ExtraBold.ttf",
                        "Fonts/GothicA1-Medium.ttf",
                        "Fonts/GothicA1-SemiBold.ttf",
                        "Fonts/GothicA1-Bold.ttf",
                        "Fonts/GothicA1-ExtraBold.ttf",
                        "Fonts/Archivo[wdth,wght].ttf",
                    ],
                ]
            ),
            sources: [
                "GYMUPWidgetExtension/Sources/**",
                "GYMUP/Sources/Features/WorkoutSession/WorkoutRestActivityAttributes.swift",
            ],
            resources: [.folderReference(path: "GYMUP/Resources/Fonts")],
            dependencies: []
        ),
        .target(
            name: "GYMUPTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.teamnative.gymup.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["GYMUP/Tests/**"],
            dependencies: [.target(name: "GYMUP")]
        ),
        .target(
            name: "GYMUPUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.teamnative.gymup.uitests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["GYMUP/UITests/**"],
            dependencies: [.target(name: "GYMUP")]
        ),
    ],
    schemes: [
        .scheme(
            name: "GYMUP",
            buildAction: .buildAction(targets: ["GYMUP"]),
            testAction: .targets([.testableTarget(target: "GYMUPTests"), .testableTarget(target: "GYMUPUITests")]),
            runAction: .runAction(executable: .target("GYMUP"))
        ),
    ]
)
