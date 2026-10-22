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
                    "UIAppFonts": ["NotoSansKR[wght].ttf"],
                ]
            ),
            sources: ["GYMUP/Sources/**"],
            resources: ["GYMUP/Resources/**"],
            dependencies: [],
            settings: .settings(base: ["ASSETCATALOG_COMPILER_APPICON_NAME": ""])
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
