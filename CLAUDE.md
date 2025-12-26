# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS educational app (공인중개사요약집) for Korean real estate agent certification exam preparation.
- **Target**: iOS 18.0+ (Widget extension requires iOS 26.0+)
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
mise x -- tuist generate --no-open

# Generate and open in Xcode
mise x -- tuist generate --open

# Build project
tuist build

# Test compilation (use generic iOS destination)
xcodebuild build -scheme App -workspace realtornote.xcworkspace -destination 'generic/platform=iOS'

# Clean build artifacts
tuist clean
```

**IMPORTANT**: Always regenerate after file changes:
- ✅ Created new file → `mise x -- tuist generate --no-open`
- ✅ Deleted file → `mise x -- tuist generate --no-open`
- ✅ Renamed file → `mise x -- tuist generate --no-open`
- ❌ Skip regeneration → Build errors ("cannot find in scope")

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
   - **Widget** extension: AlarmKit Live Activities (iOS 26.0+)
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
- **PartScreen**: Content viewer with search, favorites, and scroll position tracking
  - Custom SearchBar component (regex-based, live highlighting)
  - Green highlight for current match, yellow for others
  - Previous/Next navigation buttons
  - Keyboard auto-hides on Return key
  - Uses SwiftUITextView wrapper for performance
- **AlarmListScreen**: Alarm management with notification/AlarmKit registration
- **AlarmSettingsScreen**: Create/edit alarms with weekday/time pickers

### App Intents (iOS 26.0+)

**Location**: `Projects/App/Sources/Intents/`

- `OpenStudyAppIntent`: Opens app and triggers alarm countdown via `AlarmManager.shared.countdown()`
  - Used as secondary action from alarm notifications
  - Implements `LiveActivityIntent` protocol

### Reusable Components (`Projects/App/Sources/Controls/`)

**SearchBar.swift**:
- Custom search bar with semi-transparent background (iOS-style)
- TextField with clear button (X), Previous/Next navigation (chevrons)
- Auto-hides keyboard on Return key submission
- Shows navigation buttons only when results exist
- Used in PartScreen (can be reused elsewhere)

**SwiftUITextView.swift**:
- UIViewRepresentable wrapper around UITextView
- Performance optimization for large text content
- Supports plain text and attributed text (for search highlighting)
- Scroll position tracking and programmatic scrolling to ranges
- Used in PartScreen for content display

### Key Patterns

**UIKit → SwiftUI**:
- `UITabBarController` → `TabView`
- `UINavigationController` → `NavigationStack`
- `@IBOutlet/@IBAction` → `@State/@Binding`
- `RNModelController.shared` → `@Query` / `@Environment(\.modelContext)`
- `UISearchBar` → Custom `SearchBar` component (works inside TabView)

**Search Implementation** (PartScreen):
- Regex-based search (case-insensitive) like UIKit `RNPartViewController`
- NSAttributedString for highlighting (green = current, yellow = others)
- Keyboard management via `@FocusState`
- Previous/Next navigation with wrapping (first ↔ last)
- Return key cycles to next match and hides keyboard

**Notifications** (`Alarm+.swift`):
- `toNotification()` creates `LSUserNotification` from SwiftData Alarm
- Registration via `UserNotificationManager.shared` (matches UIKit pattern)

## Widget Extension (iOS 26.0+)

### AlarmKit Integration

Live Activity support for study alarms using iOS 26's AlarmKit framework.

**Location**: `Projects/App/Extensions/Widget/`

**Structure**:
```
Widget/
├── Sources/
│   ├── LiveActivityWidget.swift      # Main widget with Dynamic Island + Lock Screen
│   ├── AppWidgetBundle.swift         # Widget bundle
│   ├── StudyAlarmMetadata.swift      # Shared metadata model
│   └── Intents/
│       ├── PauseIntent.swift         # Pause alarm (LiveActivityIntent)
│       ├── ResumeIntent.swift        # Resume alarm (LiveActivityIntent)
│       └── StopIntent.swift          # Stop alarm (LiveActivityIntent)
├── Resources/
│   └── Assets.xcassets/
└── Configs/
    ├── debug.xcconfig                # IPHONEOS_DEPLOYMENT_TARGET=26.0
    └── release.xcconfig              # IPHONEOS_DEPLOYMENT_TARGET=26.0
```

**Shared Code Pattern**:
- `StudyAlarmMetadata.swift` lives in Widget's sources
- App target explicitly includes it via `Project.swift` sources array
- Single source of truth, no duplication
- Future refactor: move to shared AlarmFeature module

**Key Components**:

*LiveActivityWidget.swift*:
- `AlarmAttributes<StudyAlarmMetadata>`: Live Activity attributes
- **Dynamic Island**: Compact (countdown + progress), expanded (title, subtitle, countdown, controls)
- **Lock Screen**: Full-width view with countdown timer and alarm controls
- `AlarmProgressView`: Circular progress with book icon, handles countdown/paused states
- `AlarmControls`: Resume button (paused state) + Stop button with `LiveActivityIntent`

*Widget Intents* (all use `LiveActivityIntent`):
- `PauseIntent`: Calls `AlarmManager.shared.pause()`
- `ResumeIntent`: Calls `AlarmManager.shared.resume()`
- `StopIntent`: Calls `AlarmManager.shared.stop()`

*AlarmKitManager* (App target only, iOS 26.0+):
- **Authorization**: `requestAuthorization()`, `isAlarmKitAvailable`
- **Scheduling**: Converts SwiftData `Alarm` → AlarmKit configuration
  - Schedule: One-time or weekly recurring based on weekdays
  - Countdown: 5min pre-alert, 15min postpone (30s in DEBUG)
  - Presentation: Alert with stop/secondary buttons (countdown behavior)
  - Tint: Yellow color
- **Fallback**: Uses `UserNotificationManager` for iOS 18-25 when AlarmKit unavailable

## Configuration & Integrations

### Build Configs
- Debug/Release: `Projects/App/Configs/{debug,release}.xcconfig`
- Version: `MARKETING_VERSION` (user-facing), `CURRENT_PROJECT_VERSION` (build number)

### Tuist Helpers (`Tuist/ProjectDescriptionHelpers/`)
- `String+.swift`: `.appBundleId`
- `Path+.swift`: `.projects()`, `.extensions.widget` (path to Widget extension)
- `SourceFileGlob+.swift`: `.extensions.widget` (for source file globs)
- `TargetDependency+.swift`: `.Projects.ThirdParty`, `.Projects.DynamicThirdParty`

### Third-Party Services
- **Google AdMob**: 3 ad units (Donate, FullAd, Launch)
- **KakaoTalk**: App key d3be13c89a776659651eef478d4e4268
- **Firebase**: 11.8.1 SDK (Crashlytics, Analytics, Messaging, RemoteConfig)
- **AlarmKit**: iOS 26.0+ framework for Live Activities and alarm scheduling (Widget extension only)

### Code Style
- Mix of Korean (UI strings) and English (technical comments)
- No automated linting (follow existing style)
- Dark mode enforced in `Info.plist`
- AlarmKit.AlarmManager - https://developer.apple.com/documentation/alarmkit/alarmmanager
- generate project if you insert new file or rename using tuist