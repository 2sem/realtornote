---
name: project-setup-and-commands
description: Essential development commands for Tuist setup, build, and deployment
---

# Overview

This skill covers all essential development commands for working with this Tuist-based iOS project, including tool setup, project generation, building, and deployment workflows.

# When to use

Use this skill when:
- Setting up the development environment for the first time
- Generating Xcode workspace after file changes (create, delete, rename)
- Building or testing the project
- Deploying to TestFlight or App Store
- Working with encrypted secrets

# Instructions

## Project Overview

iOS educational app (공인중개사요약집) for Korean real estate agent certification exam preparation.
- **Target**: iOS 18.0+ (Widget extension requires iOS 26.0+)
- **Swift**: 5
- **Project**: Tuist-generated workspace

## Setup Tools

```bash
# Install mise and Tuist
brew install mise
mise install tuist

# Use tuist without mise prefix (optional)
eval "$(mise activate bash)"
```

## Generate & Build

```bash
# Generate Xcode workspace (without opening)
mise x -- tuist generate --no-open

# Generate and open in Xcode
mise x -- tuist generate --open

# Build project
tuist build

# Test compilation (use generic iOS destination)
xcodebuild build -scheme App -workspace realtornote.xcworkspace -destination 'generic/platform=iOS'

# Clean build artifacts
tuist clean
```

**IMPORTANT**: Always regenerate after file changes:
- ✅ Created new file → `mise x -- tuist generate --no-open`
- ✅ Deleted file → `mise x -- tuist generate --no-open`
- ✅ Renamed file → `mise x -- tuist generate --no-open`
- ❌ Skip regeneration → Build errors ("cannot find in scope")

## Secrets & Deployment

```bash
# Decrypt secrets (git-secret)
git secret reveal -p <password>

# Deploy to TestFlight
fastlane ios release description:'변경사항 설명' isReleasing:false

# Deploy to App Store
fastlane ios release description:'변경사항 설명' isReleasing:true
```

## Key Reminders

- **Always regenerate Tuist project** after creating, deleting, or renaming files
- Use `mise x --` prefix for Tuist commands if mise is not activated in shell
- Generate project if you insert new file or rename using tuist
