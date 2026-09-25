import ProjectDescription
import ProjectDescriptionHelpers

let skAdNetworkIDs: [String] = [
    "cstr6suwn9", "4fzdc2evr5", "2fnua5tdw4", "ydx93a7ass", "p78axxw29g",
    "v72qych5uu", "ludvb6z3bs", "cp8zw746q7", "3sh42y64q3", "c6k4g5qg8m",
    "s39g8k73mm", "wg4vff78zm", "3qy4746246", "f38h382jlk", "hs6bdukanm",
    "mlmmfzh3r3", "v4nxqhlyqp", "wzmmz9fp6w", "su67r6k2v3", "yclnxrl5pm",
    "t38b2kh725", "7ug5zh24hu", "gta9lk7p23", "vutu7akeur", "y5ghdn5j9k",
    "v9wttpbfk9", "n38lu8286q", "47vhws6wlr", "kbd757ywx3", "9t245vhmpl",
    "a2p9lx4jpn", "22mmun2rn5", "44jx6755aq", "k674qkevps", "4468km3ulz",
    "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5", "ppxm28t8ap", "kbmxgpxpgc",
    "uw77j35x4d", "578prtvx9j", "4dzt52r2t5", "tl55sbb4fm", "c3frkrj4fj",
    "e5fvkxwrpn", "8c4e2ghe7u", "3rd42ekr43", "97r2b46745", "3qcr597p9d"
]

let skAdNetworks: [Plist.Value] = skAdNetworkIDs
    .map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }

let appTarget: Target = .target(
    name: "App",
    destinations: .iOS,
    product: .app,
    bundleId: .appBundleId,
    infoPlist: .extendingDefault(
        with: [
            "UILaunchStoryboardName": "LaunchScreen",
            "GADApplicationIdentifier": "ca-app-pub-9684378399371172~7124016405",
            "GADUnitIdentifiers": [
                                    "FullAd": "ca-app-pub-9684378399371172/1235951829",
                                    "QuizReward" : "ca-app-pub-9684378399371172/9328042795",
                                    "FavoriteNative" : "ca-app-pub-9684378399371172/5214599479",
                                    "AppLaunch" : "ca-app-pub-9684378399371172/8962601702"],
            "Itunes App Id": "1265759928",
            "NSUserTrackingUsageDescription": "맞춤형 광고 허용을 통해 개발자에게 더  많이 후원할 수 있습니다",
            "NSAlarmKitUsageDescription": "공부 시간 알림을 위해 알람 설정 권한이 필요합니다",
            "SKAdNetworkItems": .array(skAdNetworks),
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
        .extensions.widget + "/Sources/StudyAlarmMetadata.swift"
    ],
    buildableFolders: [
        "Sources",
        "Resources"
    ],
    scripts: [
        .post(
            script: """
                # Firebase is now a Tuist-integrated dependency (Tuist/Package.swift),
                # so its checkout lives under Tuist/.build, not Xcode's own
                # SourcePackages directory. Path is relative to $(SRCROOT)
                # (Projects/App).
                CRASHLYTICS_RUN_SCRIPT="${SRCROOT}/../../Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run"

                if [ ! -f "$CRASHLYTICS_RUN_SCRIPT" ]; then
                  echo "error: Firebase Crashlytics run script not found at $CRASHLYTICS_RUN_SCRIPT - run 'tuist install' first"
                  exit 1
                fi

                "$CRASHLYTICS_RUN_SCRIPT"
                """,
            name: "Firebase Crashlytics",
            inputPaths: [
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                "${INFOPLIST_PATH}"
            ],
            basedOnDependencyAnalysis: false
        )
    ],
    dependencies: [
        .Projects.ThirdParty,
        .package(product: "GADManager", type: .runtime),
        // Firebase links directly into App rather than through an intermediate
        // dynamic wrapper framework (the old DynamicThirdParty target): Tuist's
        // SPM integration doesn't reliably propagate the binary XCFrameworks
        // Firebase pulls in (GoogleAppMeasurement, nanopb, ...) through such a
        // wrapper, which shows up as undefined symbols at the *app* target's
        // link/archive step even though the wrapper itself builds fine.
        .external(name: "FirebaseCrashlytics"),
        .external(name: "FirebaseAnalytics"),
        .external(name: "FirebaseMessaging"),
        .external(name: "FirebaseRemoteConfig"),
        .target(name: "Widget")
    ],
    settings: .settings(
        base: [
            // The Crashlytics "run" tool lives under Tuist/.build/checkouts,
            // outside $(SRCROOT), and reads files (GoogleService-Info.plist,
            // dSYMs, its own sibling binary) that User Script Sandboxing
            // would otherwise block regardless of the phase's declared
            // Input Files. Disabling sandboxing for this target only (not
            // project-wide) is the reliable fix.
            "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
        ]
    )
)

let project = Project(
    name: "App",
    options: .options(defaultKnownRegions: ["ko"],
                         developmentRegion: "ko"),
    packages: [
        .remote(url: "https://github.com/2sem/GADManager",
                requirement: .upToNextMajor(from: "1.4.0")),
        // Firebase is now a Tuist-integrated dependency - see Tuist/Package.swift,
        // consumed here via `.external(name:)`.
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
        appTarget,
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
            buildableFolders: [
                .folder(.extensions.widget + "/Sources"),
                .folder(.extensions.widget + "/Resources")
            ],
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
