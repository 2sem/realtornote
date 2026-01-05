# Testing Pinch Gesture Automation: A Journey Through iOS Testing Tools

## Context
We needed to test a pinch-to-zoom font size adjustment feature in SwiftUI's PartScreen. The feature uses `.simultaneousGesture(MagnificationGesture())` to adjust font size from 14pt to 30pt while allowing scroll gestures to work normally.

## Attempt 1: IDB Companion (Meta's iOS Development Bridge)
**Goal**: Use Facebook's idb tool to simulate gestures programmatically

**What we tried**:
```bash
brew install idb-companion
idb ui tap --x 100 --y 200
```

**Result**: ❌ Failed

**Error**:
```
idb-companion requires Xcode 26.0 or later
Current Xcode version: 16.2
```

**Why it failed**:
- IDB companion has strict Xcode version requirements
- Our development environment uses Xcode 16.2
- Would require Xcode upgrade just for testing tool

**Lesson**: Check tool compatibility with your Xcode version before investing time in setup.

---

## Attempt 2: Snapshot Testing Framework (pointfreeco/swift-snapshot-testing)
**Goal**: Use snapshot testing to capture UI state before/after pinch gesture

**What we tried**:
1. Added swift-snapshot-testing dependency to Project.swift
2. Created unit test with UIHostingController
3. Attempted to simulate pinch gesture using UIKit gesture recognizer
4. Snapshot before and after gesture

**Code**:
```swift
func testPartScreen_FontSizeAdjustment() throws {
    // Create test data
    let testPart = Part(id: 1, seq: 1, name: "테스트 항목", content: "...")
    let viewModel = PartScreenModel(part: testPart, modelContext: modelContext)
    let keyboardState = KeyboardState()

    let partScreen = PartScreen(part: testPart, viewModel: viewModel)
        .environment(keyboardState)
    let hostingController = UIHostingController(rootView: partScreen)

    // Snapshot before
    assertSnapshot(matching: hostingController, as: .recursiveDescription, named: "before-pinch")

    // Try to simulate pinch
    simulatePinchGesture(on: textView, scale: 2.0, velocity: 1.0)

    // Snapshot after
    assertSnapshot(matching: hostingController, as: .recursiveDescription, named: "after-pinch")
}
```

**Result**: ❌ Failed

**Error**:
```
XCTAssertGreaterThan failed: ("17.0") is not greater than ("17.0")
Font size should have increased from default 17pt
```

**Why it failed**:
1. **SwiftUI gesture isolation**: SwiftUI's `.simultaneousGesture(MagnificationGesture())` operates at the SwiftUI layer
2. **UIKit simulation mismatch**: Our test tried to simulate at UIKit layer (UITextView) using `UIPinchGestureRecognizer`
3. **Layer disconnection**: In unit tests, SwiftUI gestures and UIKit gesture recognizers don't communicate
4. **No gesture bridge**: `UIHostingController` doesn't bridge programmatic UIKit gestures to SwiftUI gesture handlers

**What we learned**:
- ✅ Snapshot testing is excellent for **static UI verification** (layout, frames, hierarchy)
- ❌ Snapshot testing **cannot test gesture interactions**
- ❌ SwiftUI gestures in unit tests cannot be triggered programmatically
- ✅ Manual testing confirmed the feature works perfectly

**Snapshot output insights**:
```
// .recursiveDescription snapshot (1.3KB text file)
- Captures: Full UIKit view hierarchy, frames, colors, transforms
- Good for: Detecting layout regressions, structure changes
- Cannot capture: User interactions, gesture state, dynamic behavior
```

---

## Attempt 3: XCUITest (Planned, Not Executed)
**Goal**: Full end-to-end UI testing with real app launch

**Approach**:
```swift
func testPartScreen_PinchToZoomFontSize() throws {
    let app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    app.launch()

    // Navigate: Splash → Main → Subject → Chapter → Part
    let firstSubject = app.buttons.matching(identifier: "SubjectButton").firstMatch
    firstSubject.tap()

    let partContent = app.textViews.firstMatch

    // Snapshot before
    assertSnapshot(matching: partContent, as: .dump, named: "before-pinch")

    // Real gesture simulation
    partContent.pinch(withScale: 2.0, velocity: 1.0)

    // Snapshot after
    assertSnapshot(matching: partContent, as: .dump, named: "after-pinch")
}
```

**Status**: Not implemented yet

**Why it would work**:
- ✅ Launches full app with real runtime
- ✅ `XCUIElement.pinch()` performs actual gesture simulation
- ✅ Tests complete user journey from app launch
- ✅ Can snapshot XCUIElement hierarchy with `.dump`

**Trade-offs**:
- ⏱️ Slower (full app launch + navigation)
- 🏗️ Requires UI test target in Tuist project
- 🔧 More setup (launch arguments, navigation logic)
- ✅ Tests real user experience

---

## Final Solution: Manual Testing
**What we did**:
1. Ran app in simulator
2. Navigated to Part screen
3. Used trackpad pinch gesture (Option + drag)
4. Verified font size changed (14pt-30pt range)
5. Verified persistence across app restarts

**Result**: ✅ Success

**Why it worked**:
- Real device/simulator environment
- Actual gesture hardware simulation
- Full app context and state
- Immediate visual feedback

---

## Key Learnings

### 1. Choose the Right Tool for the Job
| Test Type | Best For | Not Good For |
|-----------|----------|--------------|
| **Unit Tests** | Logic, state, constraints | User interactions, gestures |
| **Snapshot Tests** | Static UI structure, layout | Dynamic behavior, animations |
| **XCUITest** | Full user flows, gestures | Fast iteration, isolated tests |
| **Manual Testing** | Quick validation, UX feel | Regression prevention, CI/CD |

### 2. SwiftUI Gesture Testing Limitations
- SwiftUI gestures **cannot** be simulated in unit tests
- UIKit gesture recognizer tricks **don't work** with SwiftUI gestures
- Need **XCUITest** for automated gesture testing
- Or use **UIKit gesture recognizers** directly (less SwiftUI-native)

### 3. Snapshot Testing Realities
```swift
// ✅ Good use case
func testLayout_SearchBarPosition() {
    assertSnapshot(matching: view, as: .recursiveDescription)
    // Captures: View hierarchy, frames, constraints
}

// ❌ Bad use case
func testGesture_PinchToZoom() {
    // Before pinch
    assertSnapshot(matching: view, as: .recursiveDescription)

    simulateGesture() // This won't work in unit tests!

    // After pinch (no change detected)
    assertSnapshot(matching: view, as: .recursiveDescription)
}
```

### 4. When to Use Each Approach

**Unit Tests + Snapshot Testing**:
- Static UI verification
- Layout regression detection
- Component structure testing
- Fast, isolated, CI-friendly

**XCUITest**:
- Gesture interactions
- Full user journeys
- Integration scenarios
- Navigation flows

**Manual Testing**:
- Initial feature validation
- UX exploration
- Edge cases
- Iterative development

---

## Recommendations

### For Gesture Testing
1. **Quick validation**: Manual testing
2. **Regression prevention**: XCUITest with full app launch
3. **Logic validation**: Unit test the constraints separately

```swift
// Unit test for logic (no gesture needed)
func testFontSizeConstraints() {
    var size: CGFloat = 17

    // Test max constraint
    size = min(30, max(14, size + 20))
    XCTAssertEqual(size, 30)

    // Test min constraint
    size = min(30, max(14, size - 20))
    XCTAssertEqual(size, 14)
}
```

### For UI Regression Testing
Use snapshot testing for **static** UI issues:
```swift
func testPartScreen_SearchBarAlignment() {
    // This works because it's testing layout, not interaction
    assertSnapshot(matching: hostingController, as: .recursiveDescription)
}
```

---

## Conclusion

Testing iOS gestures requires understanding the boundaries between:
- **SwiftUI layer** (where `.simultaneousGesture()` lives)
- **UIKit layer** (where unit tests can manipulate)
- **XCUITest layer** (where real gestures can be simulated)

For our pinch-to-zoom feature:
- ✅ Feature implemented with SwiftUI gestures (clean, idiomatic)
- ✅ Manually verified (quick validation)
- 📋 Future: Add XCUITest for regression testing if needed

**Bottom line**: Not everything needs automated testing. Sometimes manual testing is the most efficient path, especially when automation tools have limitations.
