# GYMUP-iOS

GYMUP-iOS is an iOS application built with SwiftUI and generated Xcode projects managed by Tuist. The starter screen is a small design-system showcase; product features and brand styling can be added when their requirements are available.

## Requirements

- Xcode with an iOS Simulator runtime
- [mise](https://mise.jdx.dev/) for pinned Tuist and SwiftLint versions

The repository pins Tuist `4.202.0` and SwiftLint `0.65.1` in `.tool-versions`.

## Setup

```sh
mise install
tuist generate --no-open
open GYMUP.xcodeproj
```

Select the `GYMUP` scheme and an iOS Simulator in Xcode.

## Build, test, and lint

```sh
tuist generate --no-open
swiftlint lint --strict
xcodebuild test \
  -project GYMUP.xcodeproj \
  -scheme GYMUP \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

## Project structure

```text
GYMUP/Sources/       SwiftUI app, feature views, and design-system components
GYMUP/Resources/     Asset catalog and bundled fonts
GYMUP/Tests/         XCTest unit tests
Tuist.swift          Tuist configuration entry point
Project.swift        App, test target, and scheme definitions
```

## Design foundation

`GYMUP/Sources/DesignSystem` contains adaptive semantic colors, spacing and typography tokens, and reusable button, card, text-field, section-header, and empty-state components. `GYMUP/Resources/NotoSansKR[wght].ttf` bundles the Korean-capable Noto Sans KR variable font under the SIL Open Font License; its license is in `LICENSES/`.

The starter uses system-adaptive colors and SF Symbols. No final brand palette, logo, or product imagery was supplied, so those remain open for the product design. The app's first screen demonstrates the reusable components and is not a finished product screen.

## GitHub workflow

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch, commit, review, and pull-request conventions. Pull requests targeting `dev` run Tuist generation, strict SwiftLint, and the XCTest suite on a macOS GitHub Actions runner.
