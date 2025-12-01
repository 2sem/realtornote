# SwiftUI Migration Progress

## Overview
The realtornote app is being migrated from UIKit to SwiftUI. The migration includes:
- SwiftUI app structure
- Core Data to SwiftData migration
- Excel data sync to SwiftData
- SwiftUI screens replacing UIKit view controllers

## Completed Components

### 1. App Structure
**File**: `Projects/App/Sources/App.swift`
- Main entry point with `@main` attribute
- Uses `@UIApplicationDelegateAdaptor` to keep existing AppDelegate
- Creates ModelContainer for SwiftData models
- Implements splash screen overlay pattern (ZStack with transition)
- NavigationStack wraps MainScreen

### 2. SwiftData Models
All models in `Projects/App/Sources/Models/`:

**Subject.swift**
- `@Model` class with id, name, detail
- Cascade relationship to chapters
- Convenience init from RNExcelSubject

**Chapter.swift**
- Belongs to Subject (inverse relationship)
- Cascade relationship to parts
- Convenience init from RNExcelChapter

**Part.swift**
- Belongs to Chapter (inverse relationship)
- Properties: seq, title, content
- Convenience init from RNExcelPart

**Favorite.swift**
- SwiftData model for favorites
- Relationship to Part
- Migrated from RNFavoriteInfo

**Alarm.swift**
- SwiftData model for alarms
- Properties: id, enabled, time, title, weekdays
- Relationship to Subject
- Migrated from RNAlarmInfo

### 3. Data Migration System

**ExcelSyncService.swift** (`Projects/App/Sources/Services/`)
- Syncs Excel data to SwiftData
- Detects first sync vs update sync
- First sync: direct creation (optimized)
- Update sync: find-or-create pattern
- Checks `LSDefaults.DataVersion` and SwiftData emptiness
- Force parameter to force sync even when Excel version is latest
- Comprehensive trace logging

**DataMigrationManager.swift** (`Projects/App/Sources/Managers/`)
- Manages entire migration from Core Data to SwiftData
- Migration flow:
  1. Check if migration already completed (LSDefaults)
  2. Check if Core Data has data
  3. Sync Excel to SwiftData first
  4. Migrate favorites (RNFavoriteInfo → Favorite)
  5. Migrate alarms (RNAlarmInfo → Alarm)
  6. Cleanup Core Data files
- Published properties for UI binding: migrationProgress, migrationStatus, currentStep
- Thread-safe Core Data access using context.perform()
- Comprehensive trace logging

### 4. SwiftUI Screens

**SplashScreen.swift** (`Projects/App/Sources/Screens/`)
- Displays during app initialization
- Shows migration progress with different states
- Binds to DataMigrationManager
- Sets `isDone` binding when complete (triggers fade transition)
- Korean text for status messages

**MainScreen.swift** (`Projects/App/Sources/Screens/`)
- TabView for subjects from SwiftData
- @Query to fetch subjects sorted by id
- Remembers last selected subject tab (@AppStorage)
- isFirstAppear flag to prevent re-selection on subsequent appears

**SubjectScreen.swift** (`Projects/App/Sources/Screens/`)
- Displays subject content with chapter picker
- ChapterPicker: SwiftUI Menu component
  - Shows chapters as "I. Chapter Name" (Roman numerals)
  - Checkmark on selected chapter
  - Blue theme matching UIKit design
- Saves/restores last chapter per subject (LSDefaults.LastChapter)
- References PartListScreen for displaying parts
- Int.roman extension for Roman numeral conversion

## Architecture Patterns

### ModelContainer Creation
- Created once in App.swift init
- Shared via `.modelContainer()` modifier on WindowGroup
- Configuration: not in memory, autosave disabled, undo enabled
- Models: Subject, Chapter, Part, Favorite, Alarm

### Navigation Pattern
- NavigationStack at root level
- TabView for subjects (MainScreen)
- Menu for chapter selection (ChapterPicker)
- TabView for parts (PartListScreen - to be created)

### Data Persistence
- SwiftData: New data (subjects, chapters, parts, favorites, alarms)
- LSDefaults: User preferences (last subject, last chapter, migration status, data version)
- Core Data: Legacy data (will be cleaned up after migration)

### Migration Strategy
1. First launch: Excel sync → SwiftData (no migration needed)
2. Existing users: Excel sync → SwiftData → Core Data migration → Cleanup
3. Migration state tracked in LSDefaults.dataMigrationCompleted

## Key Differences from UIKit

### RNTabBarController → MainScreen
- UITabBarController → TabView
- viewControllers array → @Query subjects array
- selectedIndex → selectedTab @State
- Custom tab bar styling → .tabItem modifier

### RNSubjectViewController → SubjectScreen
- UIPageViewController → TabView with .page style
- DropDown library → Menu component
- chapterDropDown → ChapterPicker (Menu)
- UIButton with ▼ → Menu label with chevron.down

### Data Access
- RNModelController.shared → @Query / @Environment(\.modelContext)
- Core Data fetch requests → FetchDescriptor with #Predicate
- NSManagedObject → @Model classes

## Next Steps
- Create PartListScreen (TabView for parts within a chapter)
- Add navigation bar items (share, alarm, favorite, quiz buttons)
- Implement part detail view with content rendering
- Add quiz functionality
- Add favorite/bookmark functionality
- Add alarm/notification screens
