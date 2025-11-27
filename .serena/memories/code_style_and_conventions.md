# Code Style and Conventions

## Language and Localization
- **Primary Language**: Swift 4.2
- **Comments and Strings**: Korean and English mixed
  - UI-facing strings are in Korean (e.g., "공인중개사요약집")
  - Code comments may be in Korean or English
  - Console output in Fastfile uses Korean (e.g., "iOS 프로젝트", "앱 버전")

## Naming Conventions

### Files and Classes
- **Swift Files**: PascalCase (e.g., `AppDelegate.swift`, `MainViewController.swift`)
- **Classes**: PascalCase (e.g., `AppDelegate`, `MainViewController`)
- **Extensions**: Organized in separate files with `+` suffix (e.g., `String+.swift`, `Path+.swift`, `TargetDependency+.swift`)

### Variables and Constants
- **Variables**: camelCase
- **Constants**: camelCase for local, SCREAMING_SNAKE_CASE for environment variables
- **Private properties**: Prefixed with `@` in Fastfile (Ruby style)

### Bundle and Identifiers
- **Base Bundle ID**: `com.y2k.realtornote`
- **Sub-bundles**: Appending pattern (e.g., `.thirdparty`, `.thirdparty.dynamic`, `.tests`)

## Code Organization

### File Structure
- **Extensions**: Separate files in `Extensions/` folder
- **ViewModels**: Separate folder suggesting MVVM pattern
- **Managers**: Service/manager classes in `Managers/` folder
- **ViewControllers**: All view controllers in `ViewControllers/` folder
- **Data Models**: In `Data/` folder
- **Database**: Database-related code in `Database/` folder

### Project Manifests (Tuist)
- Clean, declarative style
- Use of helpers to reduce duplication
- Constants extracted to helper extensions

## Swift Conventions

### Type Annotations
- No strict enforcement (no SwiftLint configured)
- Appears to use type inference where possible

### Access Control
- Standard Swift access control (public, private, internal)
- Extensions marked `public` when in Tuist helpers

### Optionals
- Standard Swift optional handling

## Documentation
- **No formal documentation tool** configured (no jazzy, no DocC)
- **Comments**: Inline comments in Korean or English where needed
- **No strict docstring requirements**

## Linting and Formatting
- **No SwiftLint**: No `.swiftlint.yml` found
- **No SwiftFormat**: No `.swiftformat` file found
- Code style is manual/team-based rather than automated

## Dependencies Management
- **Tuist packages**: Specified in `Project.swift` files
- **Version pinning**: Mix of exact versions, upToNextMajor, and branch references
- **Local development**: Commented-out local path examples for development

## Storyboards vs Code
- **Storyboard-based**: Uses `Main.storyboard` and `LaunchScreen`
- **UIKit**: Not SwiftUI

## Error Handling
- Standard Swift error handling patterns expected

## Architectural Patterns
- **MVVM**: ViewModels folder suggests MVVM for some screens
- **MVC**: Traditional MVC for view controllers
- **Reactive**: RxSwift/RxCocoa for reactive patterns

## Best Practices Observed
1. Separation of concerns (Database, ViewModels, Managers separate)
2. Reusable helpers for Tuist manifests
3. Configuration separation (debug.xcconfig, release.xcconfig)
4. Secret management via git-secret
5. Multi-project workspace for dependency separation
