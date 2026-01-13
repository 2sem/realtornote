---
name: configuration-integrations
description: Build configurations, Tuist helpers, and third-party service integrations
---

# Overview

This skill covers build configurations, Tuist helper utilities, and integration details for third-party services like Google AdMob, KakaoTalk, Firebase, and AlarmKit.

# When to use

Use this skill when:
- Modifying build configurations
- Working with Tuist project description helpers
- Integrating or updating third-party services
- Understanding version management
- Working with ad units or SDK configurations

# Instructions

## Build Configs

- Debug/Release: `Projects/App/Configs/{debug,release}.xcconfig`
- Version: `MARKETING_VERSION` (user-facing), `CURRENT_PROJECT_VERSION` (build number)

## Tuist Helpers (`Tuist/ProjectDescriptionHelpers/`)

- `String+.swift`: `.appBundleId`
- `Path+.swift`: `.projects()`, `.extensions.widget` (path to Widget extension)
- `SourceFileGlob+.swift`: `.extensions.widget` (for source file globs)
- `TargetDependency+.swift`: `.Projects.ThirdParty`, `.Projects.DynamicThirdParty`

## Third-Party Services

- **Google AdMob**: 3 ad units (Donate, FullAd, Launch)
- **KakaoTalk**: App key d3be13c89a776659651eef478d4e4268
- **Firebase**: 11.8.1 SDK (Crashlytics, Analytics, Messaging, RemoteConfig)
- **AlarmKit**: iOS 26.0+ framework for Live Activities and alarm scheduling (Widget extension only)

## Code Style

- Mix of Korean (UI strings) and English (technical comments)
- No automated linting (follow existing style)
- Dark mode enforced in `Info.plist`
