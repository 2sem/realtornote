# Suggested Commands

## Tool Version Management

### Install mise (if not already installed)
```bash
brew install mise
```

### Install Tuist via mise
```bash
mise install tuist
```

## Dependency Management

### Install project dependencies
```bash
mise x -- tuist install
```

### Update dependencies
```bash
mise x -- tuist install --update
```

## Project Generation

### Generate Xcode workspace and projects
```bash
mise x -- tuist generate
```

### Generate and open in Xcode
```bash
mise x -- tuist generate --open
```

## Build Commands

### Build the project
```bash
mise x -- tuist build
```

### Build specific scheme
```bash
mise x -- tuist build App
```

### Clean build artifacts
```bash
mise x -- tuist clean
```

## Testing

### Run tests
```bash
mise x -- tuist test
```

Note: The AppTests target is currently empty (sources: [])

## Secret Management

### Install git-secret (if not already installed)
```bash
brew install git-secret
```

### Reveal encrypted secrets
```bash
git secret reveal -p <password>
```

### Hide/encrypt secrets
```bash
git secret hide
```

## CI/CD with Fastlane

### Install/Update Fastlane
```bash
sudo gem install fastlane
```

### Deploy to TestFlight
```bash
fastlane ios release description:'Your changelog' isReleasing:false
```

### Deploy to App Store for review
```bash
fastlane ios release description:'Your changelog' isReleasing:true
```

## Git Commands (macOS/Darwin)

Standard git commands work as expected on macOS:
```bash
git status
git add .
git commit -m "message"
git push
git pull
```

## Useful Tuist Commands

### Graph project dependencies
```bash
mise x -- tuist graph
```

### Edit Tuist manifests in Xcode
```bash
mise x -- tuist edit
```

### Migration commands (when upgrading Tuist)
```bash
mise x -- tuist migration
```
