---
name: architecture-overview
description: Workspace structure, data flow, and project organization patterns
---

# Overview

This skill explains the project's architecture, including the three-project Tuist workspace structure, data flow patterns (both legacy UIKit and new SwiftUI), and how different components are organized.

# When to use

Use this skill when:
- Understanding the overall project structure
- Working with data persistence (Core Data vs SwiftData)
- Navigating between UIKit and SwiftUI code
- Understanding how Excel content flows into the app
- Working with managers and controllers

# Instructions

## Workspace Structure

Three Tuist projects for clean dependency management:
1. **App**: Main application (business logic & UI)
   - **Widget** extension: AlarmKit Live Activities (iOS 26.0+)
2. **ThirdParty**: Static framework (RxSwift, KakaoSDK, CoreXLSX)
3. **DynamicThirdParty**: Dynamic framework (Firebase)

## Data Flow (Legacy UIKit)

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

## Key Patterns

**UIKit → SwiftUI**:
- `UITabBarController` → `TabView`
- `UINavigationController` → `NavigationStack`
- `@IBOutlet/@IBAction` → `@State/@Binding`
- `RNModelController.shared` → `@Query` / `@Environment(\.modelContext)`
- `UISearchBar` → Custom `SearchBar` component (works inside TabView)
