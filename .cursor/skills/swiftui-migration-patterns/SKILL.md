---
name: swiftui-migration-patterns
description: SwiftUI migration guidelines, naming conventions, and component patterns
---

# Overview

This skill covers the SwiftUI migration patterns, naming conventions, migrated screens, reusable components, and key implementation patterns for the hybrid UIKit/SwiftUI codebase.

# When to use

Use this skill when:
- Creating new SwiftUI screens or components
- Migrating UIKit code to SwiftUI
- Understanding naming conventions for screens and view models
- Working with search functionality
- Implementing notifications in SwiftUI

# Instructions

## Naming Conventions

- **Screens**: End with `Screen` (e.g., `MainScreen`, not `MainView`)
- **ViewModels**: End with `ScreenModel` (located in `ViewModels/`, not `Screens/`)

## Migrated Screens

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

## App Intents (iOS 26.0+)

**Location**: `Projects/App/Sources/Intents/`

- `OpenStudyAppIntent`: Opens app and triggers alarm countdown via `AlarmManager.shared.countdown()`
  - Used as secondary action from alarm notifications
  - Implements `LiveActivityIntent` protocol

## Reusable Components (`Projects/App/Sources/Controls/`)

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

## Key Patterns

**UIKit → SwiftUI**:
- `UITabBarController` → `TabView`
- `UINavigationController` → `NavigationStack`
- `@IBOutlet/@IBAction` → `@State/@Binding`
- `RNModelController.shared` → `@Query` / `@Environment(\.modelContext)`
- `UISearchBar` → Custom `SearchBar` component (works inside TabView)

**Search Implementation** (PartScreen):
- Regex-based search (case-insensitive) like UIKit `RNPartViewController`
- NSAttributedString for highlighting (green = current, yellow for others)
- Keyboard management via `@FocusState`
- Previous/Next navigation with wrapping (first ↔ last)
- Return key cycles to next match and hides keyboard

**Notifications** (`Alarm+.swift`):
- `toNotification()` creates `LSUserNotification` from SwiftData Alarm
- Registration via `UserNotificationManager.shared` (matches UIKit pattern)
