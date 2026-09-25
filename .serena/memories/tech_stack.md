# Tech Stack

## Core Technologies
- **Language**: Swift 4.2
- **Minimum iOS Version**: 13.0
- **Supported Platforms**: iPhone and iPad (iphoneos, iphonesimulator)
- **UI Framework**: UIKit (Storyboard-based with Main.storyboard and LaunchScreen)

## Build Tools
- **Tuist**: 4.207.0 - Xcode project generation and dependency management
- **mise**: Tool version manager
- **Fastlane**: CI/CD automation
- **Xcode**: Compatible versions up to next major of 26.0

## Third-Party Dependencies

### Tuist-integrated packages (`Tuist/Package.swift`, `.external(name:)`)
- **CoreXLSX** (^0.14.2): Excel file parsing
- **LSExtensions** (^0.1.24): Custom extensions library
- **StringLogger** (^0.7.0): String-based logging
- **Firebase iOS SDK** (^12.17.0, linked dynamically):
  - FirebaseCrashlytics: Crash reporting
  - FirebaseAnalytics: Analytics
  - FirebaseMessaging: Push notifications
  - FirebaseRemoteConfig: Remote configuration
- **GADManager** (^1.4.0): Google AdMob wrapper

## Architecture Patterns
Based on the source code structure:
- **MVVM**: ViewModels folder suggests MVVM pattern usage
- **MVC**: ViewControllers and Controllers folders

## Secret Management
- **git-secret**: Used for encrypting sensitive files (certificates, provisioning profiles, API keys)
