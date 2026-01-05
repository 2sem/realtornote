import XCTest
import SwiftUI
import SwiftData

/// Temporary test file for debugging UI issues
/// 
/// **How to use:**
/// 1. Create a test method for the UI issue you're investigating
/// 2. Launch XCUIApplication with `--uitesting` flag
/// 3. Use `saveSnapshot()` to capture XCUIElement state before/after changes
/// 4. Run test: `xcodebuild test -scheme App -only-testing:AppTests/UIIssueTests/testYourTest`
/// 5. Check snapshots in `Tests/UI/__Snapshots__/UIIssueTests/`
/// 6. Delete test method after fixing the issue
///
/// **Note:** This is for temporary debugging only. Don't commit long-lived tests here.
final class UIIssueTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    /// Save XCUIElement properties to a JSON snapshot file
    ///
    /// Creates JSON snapshots in `Tests/UI/__Snapshots__/<TestClass>/` for inspecting
    /// XCUIElement state. Useful for debugging UI tests and comparing before/after states.
    ///
    /// **JSON Structure Example:**
    /// ```json
    /// {
    ///   "identifier": "PartContentTextView",
    ///   "label": "Font size: 17",
    ///   "elementType": 47,
    ///   "elementTypeString": "TextView",
    ///   "frame": {"x": 0.0, "y": 100.0, "width": 390.0, "height": 744.0},
    ///   "isEnabled": true,
    ///   "isSelected": false,
    ///   "isHittable": true,
    ///   "exists": true,
    ///   "value": null,
    ///   "children": []  // Optional - controlled by depth parameter
    /// }
    /// ```
    ///
    /// **What's in the snapshot:**
    /// - ✅ `identifier` - Accessibility identifier
    /// - ✅ `label` - Accessibility label
    /// - ✅ `elementType` - Element type raw value (Int)
    /// - ✅ `elementTypeString` - Human-readable type (e.g., "Button", "TextView")
    /// - ✅ `frame` - Position and size (x, y, width, height)
    /// - ✅ `isEnabled` - Enabled state
    /// - ✅ `isSelected` - Selected state
    /// - ✅ `isHittable` - Can be interacted with
    /// - ✅ `exists` - Exists in hierarchy
    /// - ✅ `value` - Element value or null
    /// - ✅ `children` - Child elements (when depth > 0)
    /// - ❌ Visual appearance (colors, fonts, images)
    /// - ❌ Rendered pixels
    ///
    /// - Parameters:
    ///   - element: XCUIElement to snapshot
    ///   - name: Filename without extension (e.g., "before-pinch")
    ///   - depth: Recursion depth for children (0 = no children, 1 = direct children, 2+ = recursive)
    ///   - file: Source file location (auto-populated via #file)
    ///
    /// **Example Usage:**
    /// ```swift
    /// // Snapshot without children
    /// saveSnapshot(textView, named: "before-pinch")
    ///
    /// // Snapshot with direct children only
    /// saveSnapshot(textView, named: "after-pinch", depth: 1)
    ///
    /// // Snapshot with full hierarchy (2 levels deep)
    /// saveSnapshot(scrollView, named: "full-hierarchy", depth: 2)
    /// ```
    private func saveSnapshot(
        _ element: XCUIElement,
        named name: String,
        depth: Int = 0,
        file: StaticString = #file
    ) {
        let testName = String(describing: type(of: self))
        let fileURL = URL(fileURLWithPath: "\(file)")
        let testsDir = fileURL.deletingLastPathComponent()
        let snapshotsDir = testsDir.appendingPathComponent("__Snapshots__").appendingPathComponent(testName)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: snapshotsDir, withIntermediateDirectories: true)

        let snapshotFile = snapshotsDir.appendingPathComponent("\(name).json")
        let elementInfo = extractElementInfo(element, depth: depth)

        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: elementInfo,
                options: [.prettyPrinted, .sortedKeys]
            )
            try jsonData.write(to: snapshotFile, options: .atomic)
            print("📸 Saved JSON snapshot to: \(snapshotFile.path)")
        } catch {
            print("⚠️ Failed to save snapshot: \(error)")
        }
    }

    /// Convert XCUIElement.ElementType to human-readable string
    ///
    /// Maps element type enum to descriptive string for JSON snapshots.
    ///
    /// - Parameter type: The element type to convert
    /// - Returns: Human-readable string (e.g., "Button", "TextView", "StaticText")
    private func elementTypeToString(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .any: return "Any"
        case .other: return "Other"
        case .application: return "Application"
        case .group: return "Group"
        case .window: return "Window"
        case .sheet: return "Sheet"
        case .drawer: return "Drawer"
        case .alert: return "Alert"
        case .dialog: return "Dialog"
        case .button: return "Button"
        case .radioButton: return "RadioButton"
        case .radioGroup: return "RadioGroup"
        case .checkBox: return "CheckBox"
        case .disclosureTriangle: return "DisclosureTriangle"
        case .popUpButton: return "PopUpButton"
        case .comboBox: return "ComboBox"
        case .menuButton: return "MenuButton"
        case .toolbarButton: return "ToolbarButton"
        case .popover: return "Popover"
        case .keyboard: return "Keyboard"
        case .key: return "Key"
        case .navigationBar: return "NavigationBar"
        case .tabBar: return "TabBar"
        case .tabGroup: return "TabGroup"
        case .toolbar: return "Toolbar"
        case .statusBar: return "StatusBar"
        case .table: return "Table"
        case .tableRow: return "TableRow"
        case .tableColumn: return "TableColumn"
        case .outline: return "Outline"
        case .outlineRow: return "OutlineRow"
        case .browser: return "Browser"
        case .collectionView: return "CollectionView"
        case .slider: return "Slider"
        case .pageIndicator: return "PageIndicator"
        case .progressIndicator: return "ProgressIndicator"
        case .activityIndicator: return "ActivityIndicator"
        case .segmentedControl: return "SegmentedControl"
        case .picker: return "Picker"
        case .pickerWheel: return "PickerWheel"
        case .switch: return "Switch"
        case .toggle: return "Toggle"
        case .link: return "Link"
        case .image: return "Image"
        case .icon: return "Icon"
        case .searchField: return "SearchField"
        case .scrollView: return "ScrollView"
        case .scrollBar: return "ScrollBar"
        case .staticText: return "StaticText"
        case .textField: return "TextField"
        case .secureTextField: return "SecureTextField"
        case .datePicker: return "DatePicker"
        case .textView: return "TextView"
        case .menu: return "Menu"
        case .menuItem: return "MenuItem"
        case .menuBar: return "MenuBar"
        case .menuBarItem: return "MenuBarItem"
        case .map: return "Map"
        case .webView: return "WebView"
        case .incrementArrow: return "IncrementArrow"
        case .decrementArrow: return "DecrementArrow"
        case .timeline: return "Timeline"
        case .ratingIndicator: return "RatingIndicator"
        case .valueIndicator: return "ValueIndicator"
        case .splitGroup: return "SplitGroup"
        case .splitter: return "Splitter"
        case .relevanceIndicator: return "RelevanceIndicator"
        case .colorWell: return "ColorWell"
        case .helpTag: return "HelpTag"
        case .matte: return "Matte"
        case .dockItem: return "DockItem"
        case .ruler: return "Ruler"
        case .rulerMarker: return "RulerMarker"
        case .grid: return "Grid"
        case .levelIndicator: return "LevelIndicator"
        case .cell: return "Cell"
        case .layoutArea: return "LayoutArea"
        case .layoutItem: return "LayoutItem"
        case .handle: return "Handle"
        case .stepper: return "Stepper"
        case .tab: return "Tab"
        case .touchBar: return "TouchBar"
        case .statusItem: return "StatusItem"
        @unknown default: return "Unknown(\(type.rawValue))"
        }
    }

    /// Extract XCUIElement properties into a dictionary for JSON serialization
    ///
    /// Recursively captures element properties with optional child hierarchy traversal.
    ///
    /// - Parameters:
    ///   - element: The element to extract information from
    ///   - depth: Recursion depth for children (0 = no children, 1+ = recursive)
    /// - Returns: Dictionary with element properties ready for JSON serialization
    private func extractElementInfo(_ element: XCUIElement, depth: Int) -> [String: Any] {
        var info: [String: Any] = [
            "identifier": element.identifier,
            "label": element.label,
            "elementType": element.elementType.rawValue,
            "elementTypeString": elementTypeToString(element.elementType),
            "frame": [
                "x": element.frame.origin.x,
                "y": element.frame.origin.y,
                "width": element.frame.size.width,
                "height": element.frame.size.height
            ],
            "isEnabled": element.isEnabled,
            "isSelected": element.isSelected,
            "isHittable": element.isHittable,
            "exists": element.exists
        ]

        // Add value if it exists
        if let value = element.value as? String {
            info["value"] = value
        } else {
            info["value"] = NSNull()
        }

        // Include children if depth > 0
        if depth > 0 {
            let childrenQuery = element.children(matching: .any)
            let childrenArray = (0..<childrenQuery.count).map { index in
                extractElementInfo(childrenQuery.element(boundBy: index), depth: depth - 1)
            }
            info["children"] = childrenArray
        }

        return info
    }

    // EXAMPLE: Test gesture interaction with XCUIApplication
    // Uncomment and modify for your UI issue
    /*
    func testExample_GestureInteraction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        // Wait for element
        let element = app.buttons["MyButton"]
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        
        // Capture before state (no children)
        saveSnapshot(element, named: "before-tap")
        
        // Perform interaction
        element.tap()
        sleep(1)
        
        // Capture after state (with direct children)
        saveSnapshot(element, named: "after-tap", depth: 1)
        
        // Verify change
        XCTAssertTrue(element.isSelected)
    }
    */
    
    // TODO: Add your UI issue test here
    // Example naming: testPartScreen_SearchBarAlignment()
    // Example naming: testAlarmList_CellSpacing()
    // Example naming: testMainScreen_TabBarHeight()
}
