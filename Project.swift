import ProjectDescription

let project = Project(
    name: "GYMUP",
    targets: [
        .target(
            name: "GYMUP",
            destinations: .iOS,
            product: .app,
            bundleId: "com.teamnative.gymup",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "NSSupportsLiveActivities": true,
                    "UIAppFonts": [
                        "NotoSansKR[wght].ttf",
                        "GothicA1-Medium.ttf",
                        "GothicA1-SemiBold.ttf",
                        "GothicA1-Bold.ttf",
                        "GothicA1-ExtraBold.ttf",
                        "BarlowCondensed-Black.ttf",
                        "BarlowCondensed-Bold.ttf",
                        "BarlowCondensed-ExtraBold.ttf",
                        "Archivo[wdth,wght].ttf",
                    ],
                ]
            ),
            sources: ["GYMUP/Sources/**"],
            resources: ["GYMUP/Resources/**"],
            dependencies: [.target(name: "GYMUPWidgetExtension")],
            settings: .settings(base: ["ASSETCATALOG_COMPILER_APPICON_NAME": ""])
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
                        "BarlowCondensed-Black.ttf",
                        "BarlowCondensed-Bold.ttf",
                        "BarlowCondensed-ExtraBold.ttf",
                        "GothicA1-Medium.ttf",
                        "GothicA1-SemiBold.ttf",
                        "GothicA1-Bold.ttf",
                        "GothicA1-ExtraBold.ttf",
                        "Archivo[wdth,wght].ttf",
                    ],
                ]
            ),
            sources: [
                "GYMUPWidgetExtension/Sources/**",
                "GYMUP/Sources/Features/WorkoutSession/WorkoutRestActivityAttributes.swift",
            ],
            resources: ["GYMUP/Resources/Fonts/**"],
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
    ],
    schemes: [
        .scheme(
            name: "GYMUP",
            buildAction: .buildAction(targets: ["GYMUP"]),
            testAction: .targets([.testableTarget(target: "GYMUPTests")]),
            runAction: .runAction(executable: .target("GYMUP"))
        ),
    ]
)
