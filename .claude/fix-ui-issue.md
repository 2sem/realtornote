# UI Issue Fix Workflow

## Prerequisites (One-time setup)
Before using this workflow for the first time, ensure:

1. **Install snapshot testing library to packages**:
   - Open `Projects/App/Project.swift`
   - Add to `packages` array:
     ```swift
     .remote(url: "https://github.com/pointfreeco/swift-snapshot-testing",
             requirement: .upToNextMajor(from: "1.12.0")),
     ```

2. **Add SnapshotTesting framework to AppTests dependencies**:
   - In the same file, find the `AppTests` target
   - Update dependencies:
     ```swift
     dependencies: [
         .target(name: "App"),
         .package(product: "SnapshotTesting", type: .runtime)
     ]
     ```

3. **Set Path for Test Code in Project.swift**:
   - Open `Projects/App/Project.swift`
   - Change `sources: []` to `sources: "Tests/**",` in AppTests target

4. **Regenerate project**: `mise x -- tuist generate --no-open`

## Initial Setup
1. **Analyze the issue**: Understand the UI problem and expected behavior

2. **Find available simulators**:
   ```bash
   xcrun simctl list devices available | grep "iPhone 17 Pro"
   ```
   Note the exact device name and OS version (e.g., iPhone 17 Pro)

3. **Create UI test** in temporary test file:
   - File: `Projects/App/Tests/UIIssueTests.swift` (already exists as template)
   - Add a new test method for your specific issue:
     ```swift
     // In UIIssueTests class
     func testPartScreen_SearchBarAlignment() throws {
         let view = PartScreen(...)
         let hostingController = UIHostingController(rootView: view)
         hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)

         assertSnapshot(
             matching: hostingController,
             as: .recursiveDescription,
             record: true  // Set to true for first run, false afterwards
         )
     }
     ```
   - **Naming convention**: `test<ScreenName>_<IssueDescription>()`
     - Examples: `testAlarmList_CellSpacing()`, `testMainScreen_TabBarHeight()`
   - **After fixing**: Delete the test method or keep for regression testing

4. **No regeneration needed** - UIIssueTests.swift already exists in the project

## Snapshot Strategy Guide

**Recommended: `.recursiveDescription`**
- **Size**: ~1-2KB (vs 500KB for images)
- **Captures**: Full UIKit view hierarchy, frames, colors, transforms, layers
- **Best for**: Layout bugs, styling issues, view hierarchy changes
- **Diff-friendly**: Easy to review in code reviews and git

**Alternative: `.dump`**
- **Size**: ~700B
- **Captures**: Swift structure, @State, @Binding, @Environment values
- **Best for**: SwiftUI state/data flow debugging
- **When to use**: When debugging state management, not UI layout

**Avoid: `.image`**
- ❌ 400x larger than text snapshots
- ❌ Slow to diff and review
- ❌ Not git-friendly (binary files)
- ❌ Same as manual simulator screenshots

## Iteration Loop

### First Run (Record Snapshot)
5. **Run test with record mode enabled** (`record: true` in test code):
   ```bash
   # Find your device
   xcrun simctl list devices available | grep "iPhone 17 Pro"

   # Run specific test to create initial snapshot
   tuist xcodebuild test --no-selective-testing -scheme App -workspace realtornote.xcworkspace \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
     -only-testing:AppTests/UIIssueTests/testPartScreen_SearchBarAlignment
   ```
   - Test will "fail" with message "Record mode is on"
   - Snapshot saved to: `Projects/App/Tests/__Snapshots__/UIIssueTests/testMethodName.1.txt`

6. **Review recorded snapshot**:
   ```bash
   open Projects/App/Tests/__Snapshots__/UIIssueTests/
   cat Projects/App/Tests/__Snapshots__/UIIssueTests/testPartScreen_SearchBarAlignment.1.txt
   ```
   - Verify snapshot captured the UI structure
   - Check frames, colors, view hierarchy

7. **Set record mode to false**:
   - Change `record: true` to `record: false` in test code

### Subsequent Runs (Compare Mode)
8. **Run test in compare mode**:
   ```bash
   xcodebuild test -scheme App -workspace realtornote.xcworkspace \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
     -only-testing:AppTests/UIIssueTests/testPartScreen_SearchBarAlignment
   ```

9. **Analyze results**:
   - Test passes: UI matches snapshot (no changes detected)
   - Test fails: UI differs from snapshot
     - Error shows text diff with exact changes
     - Review diff to see what changed in view hierarchy
   - Review snapshots in `Projects/App/Tests/__Snapshots__/`

10. **Find the root cause**:
    - Identify why the issue occurs from the diff
    - Check frame changes, color changes, missing/extra views
    - Use debugger or print statements if needed

11. **Fix the issue**:
    - Edit code (SwiftUI Screens/, ViewModels/, or legacy UIKit Controllers/)
    - If new files created/deleted/renamed: `mise x -- tuist generate --no-open`

12. **Re-run test and iterate**:
    - Go to Step 8 to run the test again
    - **Maximum 3 iterations**: If not fixed after 3 attempts, STOP and reassess
    - If stuck after 3 tries:
      - Re-analyze the snapshot diff carefully
      - Check if you're fixing the right issue
      - Consider if the approach is correct
      - Ask for help or take a break
    - Continue until test passes OR you hit the 3-iteration limit

## Final Verification
13. **Confirm fix**:
    - All tests pass
    - Snapshot diff shows only intended changes
    - Manual testing in simulator confirms fix

14. **Clean up**:
    - Remove debug code and print statements
    - Ensure `record: false` in all tests (don't commit with record mode on)
    - Review snapshot changes in git diff before committing
    - Commit snapshot text files to git as reference

15. **Document**: Add code comments if the fix is non-obvious

## Notes
- **Temporary test file**: `Projects/App/Tests/UIIssueTests.swift` is a template for debugging UI issues
- **Test method naming**: `test<ScreenName>_<IssueDescription>()` (e.g., `testAlarmList_CellSpacing()`)
- **After fixing**: Delete the test method or keep for regression testing
- **Snapshot location**: `Projects/App/Tests/__Snapshots__/UIIssueTests/` (auto-created, **gitignored**)
- **Snapshot format**: Text files (.txt), not images (.png)
- **Record mode**: First run needs `record: true`, then change to `false` for comparison
- **No regeneration needed**: UIIssueTests.swift already exists in project
- **Device specification**: Must include both device name AND OS version in xcodebuild command
- **Run specific tests only**: Use `-only-testing:AppTests/UIIssueTests/testMethod` for faster iteration
- **Snapshots NOT committed** - They're temporary debugging artifacts (automatically gitignored)
- **For regression tests**: Create a separate test file (not UIIssueTests) and commit those snapshots
- **Text diffs**: Changes show up as clear text diffs in code reviews (much better than images)
- **⚠️ Infinite loop prevention**: Max 3 iterations on Step 12 - if not fixed, stop and reassess your approach
