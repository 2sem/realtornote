# Codebase Structure

## Workspace Organization
The project uses Tuist to manage a multi-project workspace with the following structure:

```
realtornote/
├── Workspace.swift          # Defines workspace with 3 projects
├── Tuist.swift              # Tuist configuration
├── .mise.toml               # Tool version management (tuist 4.109.0)
├── Tuist/
│   ├── ProjectDescriptionHelpers/
│   │   ├── String+.swift           # App bundle ID helper
│   │   ├── Path+.swift             # Path helpers for projects
│   │   └── TargetDependency+.swift # Dependency helpers
│   └── Package.swift
├── Projects/
│   ├── App/                 # Main application target
│   ├── ThirdParty/          # Static framework for dependencies
│   └── DynamicThirdParty/   # Dynamic framework for Firebase
├── fastlane/
│   └── Fastfile             # Fastlane automation scripts
└── .github/
    └── workflows/
        └── deploy-ios.yml   # GitHub Actions CI/CD workflow
```

## Projects

### App Project
Main application target with the following structure:

```
Projects/App/
├── Project.swift            # Tuist project manifest
├── app.entitlements         # App entitlements
├── Configs/
│   ├── debug.xcconfig       # Debug configuration
│   └── release.xcconfig     # Release configuration
├── Sources/
│   ├── AppDelegate.swift
│   ├── MainViewController.swift
│   ├── Database/            # Database layer
│   ├── ViewModels/          # MVVM view models
│   ├── Managers/            # Manager classes
│   ├── Excel/               # Excel file handling
│   ├── Document/            # Document handling
│   ├── Extensions/          # Swift extensions
│   ├── Controls/            # Custom UI controls
│   ├── ViewControllers/     # View controllers
│   ├── Controllers/         # Controllers
│   └── Data/                # Data models
└── Resources/               # Images, storyboards, assets
```

### ThirdParty Project
Static framework containing most third-party dependencies.

### DynamicThirdParty Project
Dynamic framework specifically for Firebase dependencies.

## Key Files

- **Workspace.swift**: Defines the workspace and included projects
- **Tuist.swift**: Tuist configuration (Xcode compatibility)
- **Project.swift** (in each project): Defines targets, dependencies, and configurations
- **Fastfile**: CI/CD automation for iOS deployment
- **.gitignore**: Ignores Xcode user data, derived data, generated projects

## Configuration Management
- Debug and Release configurations defined via xcconfig files
- Bundle ID centralized in `String+.swift` helper: `com.y2k.realtornote`
- Project paths managed via `Path+.swift` helper
- Dependencies managed via `TargetDependency+.swift` helper
