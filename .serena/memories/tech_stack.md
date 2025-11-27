# Tech Stack

## Core Technologies
- **Language**: Swift 4.2
- **Minimum iOS Version**: 13.0
- **Supported Platforms**: iPhone and iPad (iphoneos, iphonesimulator)
- **UI Framework**: UIKit (Storyboard-based with Main.storyboard and LaunchScreen)

## Build Tools
- **Tuist**: 4.109.0 - Xcode project generation and dependency management
- **mise**: Tool version manager
- **Fastlane**: CI/CD automation
- **Xcode**: Compatible versions up to next major of 26.0

## Third-Party Dependencies

### Static Framework (ThirdParty)
- **CoreXLSX** (0.14.1): Excel file parsing
- **DropDown** (master branch): Dropdown UI component
- **KakaoSDK** (^2.22.2): Kakao integration for sharing
- **LProgressWebViewController** (^3.1.0): Web view with progress
- **LSCountDownLabel** (^0.0.5): Countdown timer UI
- **Toast-Swift** (^5.1.0): Toast notifications
- **SwiftyGif** (^5.4.5): GIF support
- **LSExtensions** (0.1.22): Custom extensions library
- **RxSwift** (^5.1.0): Reactive programming
- **RxCocoa** (^5.1.0): RxSwift Cocoa bindings
- **StringLogger** (^0.7.0): String-based logging

### Dynamic Framework (DynamicThirdParty)
- **Firebase iOS SDK** (^11.8.1):
  - FirebaseCrashlytics: Crash reporting
  - FirebaseAnalytics: Analytics
  - FirebaseMessaging: Push notifications
  - FirebaseRemoteConfig: Remote configuration

### Runtime Dependencies
- **GADManager** (^1.3.3): Google AdMob wrapper

## Architecture Patterns
Based on the source code structure:
- **MVVM**: ViewModels folder suggests MVVM pattern usage
- **MVC**: ViewControllers and Controllers folders
- **Reactive Programming**: RxSwift/RxCocoa for data binding and async operations

## Secret Management
- **git-secret**: Used for encrypting sensitive files (certificates, provisioning profiles, API keys)
