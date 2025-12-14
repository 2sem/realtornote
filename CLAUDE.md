# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS educational app (공인중개사요약집) for Korean real estate agent certification exam preparation.
- **Target**: iOS 18.0+
- **Swift**: 5
- **Project**: Tuist-generated workspace

## Essential Development Commands

### Setup Tools

```bash
# Install mise and Tuist
brew install mise
mise install tuist

# Use tuist without mise prefix (optional)
eval "$(mise activate bash)"
```

### Generate & Build

```bash
# Generate Xcode workspace (without opening)
tuist generate --no-open

# Generate and open in Xcode
mise x -- tuist generate --open

# Build project
tuist build

# Test compilation (use generic iOS destination)
xcodebuild build -scheme App -workspace realtornote.xcworkspace -destination 'generic/platform=iOS'

# Clean build artifacts
tuist clean
```

### Secrets & Deployment

```bash
# Decrypt secrets (git-secret)
git secret reveal -p <password>

# Deploy to TestFlight
fastlane ios release description:'변경사항 설명' isReleasing:false

# Deploy to App Store
fastlane ios release description:'변경사항 설명' isReleasing:true
```

## Architecture

### Workspace Structure

Three Tuist projects for clean dependency management:
1. **App**: Main application (business logic & UI)
2. **ThirdParty**: Static framework (RxSwift, KakaoSDK, CoreXLSX)
3. **DynamicThirdParty**: Dynamic framework (Firebase)

### Data Flow (Legacy UIKit)

**Excel → Core Data → ViewModels → ViewControllers**

- **Content**: Excel files (CoreXLSX) → `RNExcelController` → versioned updates
- **Persistence**: `RNModelController` (Core Data wrapper with extensions per entity type)
  - Call `RNModelController.shared.waitInit()` before first use
  - Extension-based organization: `+RNSubjectInfo`, `+RNPartInfo`, `+RNChapterInfo`, `+RNAlarmInfo`, `+RNFavoriteInfo`
- **Managers**: `GADRewardManager`, `RNAlarmManager`, `ReviewManager`
- **Presentation**: Mix of MVVM and MVC patterns, RxSwift/RxCocoa for reactive bindings

## SwiftUI Migration (In Progress)

Hybrid approach migrating from UIKit to SwiftUI.

### Migration Flow

**Core Data → SwiftData** (one-time on first launch):
1. `ExcelSyncService` syncs Excel → SwiftData
2. `DataMigrationManager` migrates favorites/alarms
3. Tracked via `LSDefaults.dataMigrationCompleted`

### SwiftData Models (`Projects/App/Sources/Models/`)

- **Subject** → **Chapter** → **Part** (cascade relationships)
- **Favorite** (references Part), **Alarm** (references Subject)
- Property mapping: SwiftData uses `id`, Core Data uses `no`

### Naming Conventions

- Screens: End with `Screen` (e.g., `MainScreen`, not `MainView`)
- ViewModels: End with `ScreenModel` (located in `ViewModels/`, not `Screens/`)

### Migrated Screens

- **SplashScreen**: Migration progress display
- **MainScreen**: TabView with @Query for subjects
- **SubjectScreen**: Chapter picker (Menu), Roman numerals
- **AlarmListScreen**: Alarm management with notification registration
- **AlarmSettingsScreen**: Create/edit alarms with weekday/time pickers

### Key Patterns

**UIKit → SwiftUI**:
- `UITabBarController` → `TabView`
- `UINavigationController` → `NavigationStack`
- `@IBOutlet/@IBAction` → `@State/@Binding`
- `RNModelController.shared` → `@Query` / `@Environment(\.modelContext)`

**Notifications** (`Alarm+.swift`):
- `toNotification()` creates `LSUserNotification` from SwiftData Alarm
- Registration via `UserNotificationManager.shared` (matches UIKit pattern)

## Configuration & Integrations

### Build Configs
- Debug/Release: `Projects/App/Configs/{debug,release}.xcconfig`
- Version: `MARKETING_VERSION` (user-facing), `CURRENT_PROJECT_VERSION` (build number)

### Tuist Helpers (`Tuist/ProjectDescriptionHelpers/`)
- `String+.swift`: `.appBundleId`
- `Path+.swift`: `.projects()`
- `TargetDependency+.swift`: `.Projects.ThirdParty`, `.Projects.DynamicThirdParty`

### Third-Party Services
- **Google AdMob**: 3 ad units (Donate, FullAd, Launch)
- **KakaoTalk**: App key d3be13c89a776659651eef478d4e4268
- **Firebase**: 11.8.1 SDK (Crashlytics, Analytics, Messaging, RemoteConfig)

### Code Style
- Mix of Korean (UI strings) and English (technical comments)
- No automated linting (follow existing style)
- Dark mode enforced in `Info.plist`
