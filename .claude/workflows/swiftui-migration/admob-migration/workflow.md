# UI Issue Fix Workflow
Workflow to fix and confirm UI Issues

## Pathes
- **Log**: .claude/workflow/progress/log.md
- **Plan**: .claude/workflow/progress/plan.md
- **TODO**: .claude/workflow/progress/todo.md
- **Samples**: .claude/workflow/swiftui-migration/admob-migration/

## Rules
- **Avoid Duplication**: Before performing any modification or addition, always check if code is already same to the result. If it exists or is already in the desired state, skip the corresponding step and proceed to the next, logging the skipped action.
- **Error Reporting**: If any step encounters an unrecoverable error or an unexpected state, report the issue clearly and suggest manual intervention.
- **Logging**: Log all actions taken, files modified, and any skips or errors encountered.
- **TODO**: Create TODO List and update

## Prerequisites (One-time setup)
Before using this workflow for the first time, ensure:

1. **Install GADManager 1.3.6+**
    - Purpose: Install GADManager package to use GADManager helper
    - Result: App Project Manifest has `swift-snapshot-testing` as package
    - Open `Projects/App/Project.swift`
    - Add to `packages` array:
     ```swift
     .remote(url: "https://github.com/pointfreeco/swift-snapshot-testing",
             requirement: .upToNextMajor(from: "1.3.6")),
     ```

## Ensure User Defaults Definition

Open `Projects/App/Sources/Add/Datas/LSDefaults.swift` or `Data/LSDefaults.swift`
Refer `LSDefaults.swift` in Samples

1. **Add User Defaults for Ad Permission**:
    - Purpose: Define User Defaults Names for checking whether to show Ads and to request tracking permission
    - Result: `Keys` enum contains `LaunchCount` and `AdsTrackingRequested`
    - Add to `Keys` names: LaunchCount, AdsTrackingRequested
    - Add Static Computed Properties: `AdsTrackingRequested`, `LaunchCount`

2. **Add User Defaults for Opening Ad**:
    - Purpose: Define User Defaults Names for checking whether to show Opening Ads
    - Result: `Keys` enum contains `LastOpeningAdPrepared`
    - Add to `Keys` name: LastOpeningAdPrepared
    - Add Static Computed `LastOpeningAdPrepared` Property

## Create AdManager for SwiftUI

1. **Create SwiftUIAdManager.swift**:
    - Purpose: Create AdManager for SwiftUI 
    - Result: `SwiftUIAdManager` class exists
    - Create `Projects/App/Sources/Managers/SwiftUIAdManager.swift`
    - Refer `SwiftUIAdManager.swift` in Samples

## Migrate Google Ad Unit Names for SwiftUI

1. **Create GADUnitName.swift**:
    - Purpose: Define Enum for accessing Google Ad Units
    - Result: `GADUnitName.swift` file exists
    - Create `Projects/App/Sources/Extensions/Ad/GADUnitName.swift`
    - Refer `GADUnitName.swift` in Samples
    - Add GADUnitName `cases` from `GADUnitIdentifiers` of `Projects/App/Project.swift`

## Migrate Admob Manager Intialization

Open `Projects/App/Sources/App.swift`
Refer `.claude/workflows/swiftui-migration/sameples/App.swift`

1. **Import Google Mobile Ads Framework**
    - Purpose: Import Google Ads framework to access Ads classes
    - Result: `GoogleMobileAds` imported
    - Add `import` GoogleMobileAds framework
2. **Add isSetupDone State**
    - Purpose: Define state to check Google Ads is ready
    - Result: `App.swift` as `isSetupDone` state
    - Add `isSetupDone` state as `false`
3. **Add setupAds method**
    - Purpose: Define method to ready Google Ads
    - Result: `App.swift` as `setupAds` method
    - Add `setupAds` method
4. **Add handleScenePhaseChange method**
    - Purpose: Define method to detect app life cycle
    - Result: `App.swift` as `handleScenePhaseChange` method
    - Add `handleScenePhaseChange` method
5. **Add handleAppDidBecomeActive method**
    - Purpose: Define method to handle when app become active
    - Result: `App.swift` as `handleAppDidBecomeActive` method
    - Add `handleAppDidBecomeActive` method

## Migrate Interstial Ad

1. **Find Which ViewController and Button showing Full Ad**
    - Find calling show method of sharedGADManager
    - example: "sharedGADManager?.show(unit: .full)"

2. **Find Which SwiftUI Screen is migrated from the ViewController**
    - Find {Name}Screen if the view controller's name is {Name}ViewController

3. **Add SwiftUIAdManager as EnvironmentObject**
    - Purpose: Enable adManager in the screeen
    - Result: The screen has `adManager` EnvironmentObject
    - Open the screen file `Projects/App/Sources/.../...Screen.swift`
    - Add EnvironmentObject `adManager`
    - Refer `MigratedScreen.swift` in Samples

4. **Add LaunchCount User Defaults Property**
    - Purpose: To request Ads permission and Ads since second Launch 
    - Result: The screen has `LaunchCount` AppStorage property
    - Open the screen file `Projects/App/Sources/.../...Screen.swift`
    - Refer `MigratedScreen.swift` in Samples

5. **Add a Method to wrap the behavior with Ads**
    - Purpose: Extract the code invoking Ads as a method
    - Result: The screen has `presentFullAdThen` method
    - Open the screen file `Projects/App/Sources/.../...Screen.swift`
    - Add Method `presentFullAdThen`
    - Refer `MigratedScreen.swift` in Samples

6. **Find the Code migrated from ViewController**
    - Purpose: To determine where to wrap with Ads
    - Find Which Button or Gesture migrated from the view controller
    - examples: MainViewController.onDonate to MainScreen's Button("Donate") {}

7. **Wrap the code with presentFullAdThen**
    - Purpose: To show Ads before the action
    - Result: The code wrapped with `presentFullAdThen`
    - Wrap the code found in Step 6 with `presentFullAdThen`
