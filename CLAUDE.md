# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS educational app (공인중개사요약집) for Korean real estate agent certification exam preparation. The app is built using Tuist for project management, targets iOS 13.0+, and uses Swift 4.2.

**Bundle ID**: `com.y2k.realtornote`
**Current Version**: 1.1.28

## Essential Development Commands

### Setup and Dependencies

```bash
# Install mise (if not installed)
brew install mise

# Install Tuist
mise install tuist

# Install project dependencies
mise x -- tuist install

# Generate Xcode workspace and projects
mise x -- tuist generate

# Generate and open in Xcode
mise x -- tuist generate --open
```

### Build and Clean

```bash
# Build the project
mise x -- tuist build

# Clean build artifacts
mise x -- tuist clean
```

### Secret Management

This project uses git-secret to encrypt sensitive files (certificates, provisioning profiles, API keys).

```bash
# Install git-secret (if not installed)
brew install git-secret

# Decrypt secrets (requires password)
git secret reveal -p <password>

# Encrypt secrets after modification
git secret hide
```

### Deployment

```bash
# Install/update Fastlane
sudo gem install fastlane

# Deploy to TestFlight
fastlane ios release description:'변경사항 설명' isReleasing:false

# Deploy to App Store for review
fastlane ios release description:'변경사항 설명' isReleasing:true
```

## High-Level Architecture

### Multi-Project Workspace Structure

The codebase is organized as a Tuist workspace with three separate projects:

1. **App** (`Projects/App/`): Main application target containing all business logic and UI
2. **ThirdParty** (`Projects/ThirdParty/`): Static framework bundling most third-party dependencies (RxSwift, KakaoSDK, CoreXLSX, etc.)
3. **DynamicThirdParty** (`Projects/DynamicThirdParty/`): Dynamic framework specifically for Firebase dependencies (Crashlytics, Analytics, Messaging, RemoteConfig)

This separation allows for cleaner dependency management and faster incremental builds.

### Data Flow Architecture

The app follows a unique content delivery architecture:

**Excel → Core Data-style Persistence → ViewModels → ViewControllers**

1. **Excel-Based Content System** (`RNExcelController`):
   - Study content is bundled as Excel files parsed using CoreXLSX
   - `RNExcelController` reads versioned content and checks for updates
   - Extensions handle different entity types: `+RNExcelSubject`, `+RNExcelPart`, `+RNExcelChapter`
   - Content includes: subjects (과목), parts (편), chapters (장)

2. **Persistence Layer** (`RNModelController`):
   - Singleton pattern with lazy initialization and dispatch groups
   - Acts as Core Data wrapper but uses a custom persistence mechanism
   - Extensions organize entity-specific operations: `+RNSubjectInfo`, `+RNPartInfo`, `+RNChapterInfo`, `+RNAlarmInfo`, `+RNFavoriteInfo`
   - Supports transactions, undo/rollback operations
   - Must call `waitInit()` before first use to ensure initialization completes

3. **Manager Layer**:
   - `GADRewardManager`: Google AdMob rewarded ad lifecycle
   - `RNAlarmManager`: Study alarm/notification scheduling
   - `ReviewManager`: App review prompt logic

4. **Presentation Layer**:
   - Mix of MVVM (some screens use ViewModels like `RNAlarmTableViewModel`) and traditional MVC
   - Main navigation: `RNTabBarController` → Subject → Part → Chapter → Question screens
   - Custom table view cells for different content types

### Key Patterns and Relationships

**Extension-Based Organization**: Both `RNModelController` and `RNExcelController` use Swift extensions in separate files to organize functionality by entity type. When modifying database operations for a specific entity (e.g., Chapters), look for the corresponding extension file.

**Singleton Pattern**: `RNModelController.shared` and `RNExcelController.Default` are singletons. Always use `RNModelController.shared.waitInit()` before accessing data to ensure initialization completes.

**Reactive Pattern**: RxSwift/RxCocoa are available for reactive programming patterns, particularly in ViewModels.

## Configuration Management

### Build Configurations

- **Debug**: `Projects/App/Configs/debug.xcconfig`
- **Release**: `Projects/App/Configs/release.xcconfig`

Version management:
- `MARKETING_VERSION`: User-facing version (currently 1.1.28)
- `CURRENT_PROJECT_VERSION`: Build number (auto-incremented by Fastlane during deployment)

### Tuist Helpers

Custom helpers in `Tuist/ProjectDescriptionHelpers/`:
- `String+.swift`: Defines `.appBundleId` constant
- `Path+.swift`: Defines `.projects()` helper for referencing project paths
- `TargetDependency+.swift`: Defines `.Projects.ThirdParty` and `.Projects.DynamicThirdParty` dependencies

When adding new shared projects, update these helpers to maintain consistency.

## Important Integration Details

### Google AdMob
Three ad unit types configured in `Info.plist`:
- Donate: ca-app-pub-9684378399371172/9105067669
- FullAd: ca-app-pub-9684378399371172/1235951829
- Launch: ca-app-pub-9684378399371172/8962601702

### KakaoTalk Integration
App key: d3be13c89a776659651eef478d4e4268 (configured in `Info.plist`)

### Firebase
Uses 11.8.1 SDK with Crashlytics, Analytics, Messaging, and RemoteConfig modules.

### Network Security
App allows arbitrary loads with specific domain exceptions for:
- andy1002.cafe24.com
- www.q-net.or.kr
- www.quizwin.co.kr

## Code Style Notes

- **Localization**: Mix of Korean and English. UI strings and comments often in Korean, technical code comments in English.
- **No automated linting**: No SwiftLint or SwiftFormat configured. Follow existing code style manually.
- **Swift 4.2**: Older Swift version due to project constraints. Use Swift 4.2 compatible syntax.
- **Dark Mode**: App forces dark mode (`UIUserInterfaceStyle: Dark` in `Info.plist`).

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/deploy-ios.yml`):
- Runs on macOS 15 with Xcode 16.2
- Decrypts secrets using GPG
- Installs Tuist via mise
- Runs `mise x -- tuist build` to verify compilation
- Uses Fastlane for signing and uploading to TestFlight/App Store

Manual trigger with options:
- `isReleasing`: Submit for App Store review (true) or just TestFlight (false)
- `body`: Changelog description
