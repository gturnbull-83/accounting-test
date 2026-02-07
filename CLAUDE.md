# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

This is an Xcode project. Use `xcodebuild` from the command line:

```bash
# Build for macOS
xcodebuild -project "Accounting test/Accounting test.xcodeproj" -scheme "Accounting test" -destination "platform=macOS" build

# Build for iOS Simulator
xcodebuild -project "Accounting test/Accounting test.xcodeproj" -scheme "Accounting test" -destination "platform=iOS Simulator,name=iPhone 16" build

# Run tests (when test targets are added)
xcodebuild -project "Accounting test/Accounting test.xcodeproj" -scheme "Accounting test" -destination "platform=macOS" test
```

## Architecture

- **Framework**: SwiftUI with Swift 5.0
- **Platforms**: iOS, macOS, visionOS (multi-platform app)
- **Entry Point**: `Accounting_testApp.swift` - main app structure using `@main`
- **UI**: `ContentView.swift` - root view

## Project Configuration

- Bundle ID: `Gary.Accounting-test`
- Deployment targets: iOS 26.2+, macOS 15.7+, visionOS 26.2+
- Swift concurrency: Uses `MainActor` default isolation with approachable concurrency enabled
