---
name: widget-extension-alarmkit
description: Widget extension structure, AlarmKit integration, and Live Activities implementation
---

# Overview

This skill covers the Widget extension implementation for iOS 26.0+ AlarmKit Live Activities, including structure, components, intents, and AlarmKitManager integration.

# When to use

Use this skill when:
- Working with the Widget extension
- Implementing or modifying Live Activities
- Working with AlarmKit framework
- Creating or modifying widget intents
- Understanding Dynamic Island and Lock Screen widgets

# Instructions

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

## Key Components

**LiveActivityWidget.swift**:
- `AlarmAttributes<StudyAlarmMetadata>`: Live Activity attributes
- **Dynamic Island**: Compact (countdown + progress), expanded (title, subtitle, countdown, controls)
- **Lock Screen**: Full-width view with countdown timer and alarm controls
- `AlarmProgressView`: Circular progress with book icon, handles countdown/paused states
- `AlarmControls`: Resume button (paused state) + Stop button with `LiveActivityIntent`

**Widget Intents** (all use `LiveActivityIntent`):
- `PauseIntent`: Calls `AlarmManager.shared.pause()`
- `ResumeIntent`: Calls `AlarmManager.shared.resume()`
- `StopIntent`: Calls `AlarmManager.shared.stop()`

**AlarmKitManager** (App target only, iOS 26.0+):
- **Authorization**: `requestAuthorization()`, `isAlarmKitAvailable`
- **Scheduling**: Converts SwiftData `Alarm` → AlarmKit configuration
  - Schedule: One-time or weekly recurring based on weekdays
  - Countdown: 5min pre-alert, 15min postpone (30s in DEBUG)
  - Presentation: Alert with stop/secondary buttons (countdown behavior)
  - Tint: Yellow color
- **Fallback**: Uses `UserNotificationManager` for iOS 18-25 when AlarmKit unavailable

## References

- AlarmKit.AlarmManager - https://developer.apple.com/documentation/alarmkit/alarmmanager
