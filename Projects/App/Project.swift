import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    options: .options(defaultKnownRegions: ["ko"],
                         developmentRegion: "ko"),
    packages: [
        .remote(url: "https://github.com/2sem/GADManager",
                requirement: .upToNextMajor(from: "1.3.8")),
        // .local(path: "../../../../../pods/GADManager/src/GADManager"),
        // .remote(url: "https://github.com/pointfreeco/swift-snapshot-testing",
        //         requirement: .upToNextMajor(from:"1.18.5")),
        // .remote(url: "https://github.com/swiftlang/swift-testing",
        //         requirement: .upToNextMajor(from: "6.2.3")),
    ],
    settings: .settings(configurations: [
        .debug(
            name: "Debug",
            xcconfig: "Configs/debug.xcconfig"),
        .release(
            name: "Release",
            xcconfig: "Configs/release.xcconfig")
    ]),
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: .appBundleId,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen",
                    "UIUserInterfaceStyle": "Dark",
                    "GADApplicationIdentifier": "ca-app-pub-9684378399371172~7124016405",
                    "GADUnitIdentifiers": [
                                            "FullAd": "ca-app-pub-9684378399371172/1235951829",
                                            "QuizReward" : "ca-app-pub-9684378399371172/9328042795",
                                            "FavoriteNative" : "ca-app-pub-9684378399371172/5214599479",
                                            "AppLaunch" : "ca-app-pub-9684378399371172/8962601702"],
                    "Itunes App Id": "1265759928",
                    "NSUserTrackingUsageDescription": "맞춤형 광고 허용을 통해 개발자에게 더  많이 후원할 수 있습니다",
                    "NSAlarmKitUsageDescription": "공부 시간 알림을 위해 알람 설정 권한이 필요합니다",
                    "SKAdNetworkItems": [],
                    "ITSAppUsesNonExemptEncryption": "NO",
                    "CFBundleShortVersionString": "${MARKETING_VERSION}",
                    "CFBundleDisplayName": "공인중개사요약집",
                    "NSAppTransportSecurity": [
                        "NSAllowsArbitraryLoads": true,
                        "NSExceptionDomains": [
                            "andy1002.cafe24.com" : "",
                            "www.q-net.or.kr" : "",
                            "www.quizwin.co.kr" : "",
                        ]
                    ],
                    "UIViewControllerBasedStatusBarAppearance": true,
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait"
                    ]
                ]
            ),
            sources: [
                "Sources/**",
                "Extensions/Widget/Sources/StudyAlarmMetadata.swift"
            ],
            resources: [
                .glob(
                    pattern: "Resources/**",
                    excluding: ["Resources/Databases/realtornote.xcdatamodeld/**"]
                )
            ],
            dependencies: [
                .Projects.ThirdParty,
                .Projects.DynamicThirdParty,
                .package(product: "GADManager", type: .runtime),
                .target(name: "Widget")
            ],
            scripts: [.post(script: "/bin/sh \"${SRCROOT}/Scripts/merge_skadnetworks.sh\"",
                            name: "Merge SKAdNetworkItems",
                            inputPaths: ["$(SRCROOT)/Resources/Plists/skNetworks.plist"],
                            outputPaths: [])]
        ),
        .target(
            name: "Widget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: .appBundleId.appending(".widget"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "공인중개사요약집 타이머",
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                    ]
                ]
            ),
            sources: .extensions.widget + "/Sources/**",
            resources: .extensions.widget + "/Resources/**",
            dependencies: [],
            settings: .settings(configurations: [
                .debug(
                    name: "Debug",
                    xcconfig: .extensions.widget + "/Configs/debug.xcconfig"),
                .release(
                    name: "Release",
                    xcconfig: .extensions.widget + "/Configs/release.xcconfig")
            ])
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: .appBundleId.appending(".tests"),
            infoPlist: .default,
            sources: "Tests/Unit/**",
            resources: [],
            dependencies: [
                .target(name: "App"),
                // .package(product: "SnapshotTesting", type: .runtime),
                // .package(product: "Testing", type: .runtime),
                // .package(product: "TestingMacros", type: .macro, condition: .when([.macos]))
                // .package(product: "TestingMacros", type: .macro)
                // .package(product: "TestingMacros", type: .plugin)

            ]
        )
        // .target(
        //     name: "AppUITests",
        //     destinations: .iOS,
        //     product: .uiTests,
        //     bundleId: .appBundleId.appending(".uitests"),
        //     infoPlist: .default,
        //     sources: "Tests/UI/**",
        //     resources: [],
        //     dependencies: [
        //         .target(name: "App"),
        //         // .package(product: "SnapshotTesting", type: .runtime)
        //         // .package(product: "Testing", type: .runtime)
        //     ]
        // ),
    ]
)
