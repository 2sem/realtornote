# Fix UI Issue Workflow

A systematic approach to debugging and testing UI issues using XCUITest and snapshot comparisons.

## Overview

This workflow uses `UIIssueTests.swift` as a temporary test file for investigating UI issues with real app interactions. It captures element state before/after changes to verify fixes.

## When to Use This Workflow

- ✅ Testing gesture interactions (pinch, swipe, tap, etc.)
- ✅ Verifying UI state changes that require full app launch
- ✅ Debugging complex navigation flows
- ✅ Testing features that modify UI based on user interaction
- ❌ Unit testing SwiftUI views in isolation (use regular unit tests)
- ❌ Snapshot testing static UI layouts (use SnapshotTesting framework)

## Step-by-Step Guide

### 1. Create a Temporary Test

Open `Projects/App/Tests/UI/UIIssueTests.swift` and add your test method:

```swift
func testYourUIIssue() throws {
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    app.launch()

    // Wait for your element
    let element = app.textViews["YourAccessibilityID"]
    XCTAssertTrue(element.waitForExistence(timeout: 10))

    // Capture BEFORE state (no children)
    saveSnapshot(element, named: "before")

    // Perform your interaction
    element.tap() // or .swipeUp(), .pinch(), etc.
    sleep(1)

    // Capture AFTER state (with direct children for debugging)
    saveSnapshot(element, named: "after", depth: 1)

    // Verify the change
    XCTAssertTrue(element.exists)
}
```

### 2. Add Accessibility Identifiers (if needed)

If your element doesn't have an accessibility identifier:

```swift
// In your SwiftUI view
MyView()
    .accessibilityIdentifier("YourAccessibilityID")
```

**Important:** Remove test-only accessibility identifiers after fixing the issue.

### 3. Run the Test

```bash
xcodebuild test -scheme App \
  -workspace realtornote.xcworkspace \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  -only-testing:AppTests/UIIssueTests/testYourUIIssue
```

### 4. Review Snapshots

Snapshots are saved to `Projects/App/Tests/UI/__Snapshots__/UIIssueTests/`:

```
__Snapshots__/
└── UIIssueTests/
    ├── before.json
    └── after.json
```

### 5. Analyze Snapshot Contents

#### What You CAN See in Snapshots (JSON Format):

- ✅ **`elementType`**: Element type numeric value (Int)
- ✅ **`elementTypeString`**: Human-readable type (e.g., "TextView", "Button", "Image")
- ✅ **`frame`**: Position and size with `x`, `y`, `width`, `height` (Dictionary)
- ✅ **Accessibility Properties**:
  - **`label`**: Accessibility label (String)
  - **`identifier`**: Accessibility identifier (String)
  - **`value`**: Current value or null (String or NSNull)
- ✅ **State Flags**:
  - **`exists`**: Element exists in hierarchy (Bool)
  - **`isHittable`**: Can be interacted with (Bool)
  - **`isEnabled`**: Is enabled/disabled (Bool)
  - **`isSelected`**: Is selected (Bool)
- ✅ **`children`**: Child elements array (when `depth` > 0)

#### What You CANNOT See in Snapshots:

- ❌ **Visual Appearance**: Colors, fonts, gradients
- ❌ **Images**: Actual image content or pixels
- ❌ **Rendered Output**: How it looks visually
- ❌ **Text Formatting**: Bold, italic, font size (unless exposed via accessibility)
- ❌ **Animations**: Mid-animation states

#### Example Snapshot Output (JSON):

```json
{
  "elementType": 47,
  "elementTypeString": "TextView",
  "exists": true,
  "frame": {
    "height": 744.0,
    "width": 390.0,
    "x": 0.0,
    "y": 100.0
  },
  "identifier": "PartContentTextView",
  "isEnabled": true,
  "isHittable": true,
  "isSelected": false,
  "label": "Font size: 17",
  "value": null
}
```

**Note:** Use the `depth` parameter to include child elements:
```swift
// No children (default)
saveSnapshot(element, named: "before")

// With direct children
saveSnapshot(element, named: "with-children", depth: 1)

// Recursive children (2 levels deep)
saveSnapshot(element, named: "full-hierarchy", depth: 2)
```

### 6. Clean Up

After fixing the issue:

1. **Remove the test method** from `UIIssueTests.swift`
2. **Remove test-only accessibility identifiers** from production code
3. **Delete snapshots** (they're gitignored automatically)
4. **Regenerate project** if you modified files: `mise x -- tuist generate --no-open`

## Real Example: Pinch-to-Zoom Font Size

See `testing-pinch-gesture-automation-journey.md` for a complete example of using this workflow to test the pinch-to-zoom feature.

### Problem
Test pinch gesture that adjusts font size in PartScreen.

### Solution
1. Added temporary accessibility label to expose font size: `.accessibilityLabel("Font size: \(Int(fontSize))")`
2. Created test in UIIssueTests.swift
3. Used `saveSnapshot()` to capture before/after state
4. Parsed font size from accessibility label
5. Verified font size changed correctly
6. Cleaned up: removed accessibility label, deleted test

### Key Insights
- XCUITest can perform real gestures (pinch, swipe, etc.)
- Use `saveSnapshot()` to inspect element state
- Expose testable data via accessibility properties
- Always clean up test-only code after fixing

## Tips & Best Practices

### 1. Use Descriptive Snapshot Names
```swift
saveSnapshot(textView, named: "before-pinch")
saveSnapshot(textView, named: "after-pinch-zoom-in", depth: 1)
saveSnapshot(textView, named: "after-pinch-zoom-out", depth: 1)
```

### 2. Wait for Elements
```swift
// Good: Wait with timeout
XCTAssertTrue(element.waitForExistence(timeout: 10))

// Bad: Assume element exists immediately
element.tap() // Might fail if element not loaded
```

### 3. Add Sleep After Interactions
```swift
textView.pinch(withScale: 2.0, velocity: 1.0)
sleep(1) // Wait for animation/update to complete
```

### 4. Test Edge Cases
```swift
// Test at boundaries
if fontSize >= 30 {
    // Test pinch in at max
} else {
    // Test pinch out normally
}
```

### 5. Print Debug Info
```swift
print("Initial font size: \(initialFontSize)")
print("Final font size: \(finalFontSize)")
print("📸 Saved snapshot to: \(snapshotFile.path)")
```

## Common Pitfalls

### ❌ Forgetting to Remove Test Code
```swift
// DON'T COMMIT THIS
.accessibilityLabel("Font size: \(fontSize)") // Only for testing!
```

### ❌ Not Waiting for Elements
```swift
// DON'T DO THIS
let element = app.buttons["MyButton"]
element.tap() // Might not exist yet!

// DO THIS
XCTAssertTrue(element.waitForExistence(timeout: 10))
element.tap()
```

### ❌ Expecting Visual Information in Snapshots
Snapshots show element metadata, not visual appearance. If you need to verify colors/fonts, expose them via accessibility properties.

## Related Documentation

- `testing-pinch-gesture-automation-journey.md` - Complete testing journey example
- `UIIssueTests.swift` - Test template with examples
- Apple's [XCUIElement Documentation](https://developer.apple.com/documentation/xctest/xcuielement)

## Summary

1. Create test in `UIIssueTests.swift`
2. Use `saveSnapshot()` before/after interaction
3. Review snapshots in `__Snapshots__/` directory
4. Verify changes using assertions
5. Clean up test code and snapshots
6. Move on to next issue

This workflow enables rapid UI debugging with real app interactions while keeping test code temporary and isolated.
