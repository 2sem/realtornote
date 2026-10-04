// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        // Everything links statically (Tuist default): source-built dynamic
        // frameworks ship unsigned and App Store Connect rejects them with
        // ITMS-91065 (missing signature for GoogleUtilities etc.).
        baseSettings: .settings(
            // Release already defaults to dwarf-with-dsym; pin it so an xcconfig
            // or Xcode default can't drop it silently. Debug stays on plain
            // `dwarf` - local builds don't need dSYMs and generating them is not free.
            configurations: [
                .debug(
                    name: .debug
                ),
                .release(
                    name: .release,
                    settings: ["DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym"]
                ),
            ]
        ),
    )
#endif

let package = Package(
    name: "realtornote",
    dependencies: [
        // Resolved by URL rather than the Tuist Registry: Tuist's own SPM
        // integration (this manifest) doesn't need the registry entry that the
        // old Xcode-level `.package(id: "firebase.firebase-ios-sdk", ...)`
        // used - a plain GitHub URL resolves reliably here.
        .package(url: "https://github.com/firebase/firebase-ios-sdk", .upToNextMinor(from: "12.18.0")),
        .package(url: "https://github.com/CoreOffice/CoreXLSX", from: "0.14.2"),
        .package(url: "https://github.com/2sem/LSExtensions", from: "0.1.24"),
        .package(url: "https://github.com/2sem/StringLogger", from: "0.7.0"),
        .package(url: "https://github.com/2sem/GADManager", from: "1.4.0"),
    ]
)
