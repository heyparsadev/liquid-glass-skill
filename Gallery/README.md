# Gallery

A host app for running the ten example screens on a simulator. It lets you check the examples against a real SDK instead of taking them on faith. The screenshots in the repo README were captured from this app.

## Run it

Requires **Xcode 27** and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
```

Xcode 27 is needed because a few examples use iOS 27 APIs behind `#available` checks. The deployment target stays at iOS 26.0, so screens 1–9 run on iOS 26 and iOS 27 simulators. Screen 10 needs iOS 27.

Then, from this directory:

```sh
xcodegen generate
open Gallery.xcodeproj
```

Pick an iPhone simulator running iOS 27 (or iOS 26 for screens 1–9) and hit Run. The app opens on the Settings screen.

## Switching screens

The app reads a `screen` launch argument, so you can jump straight to any screen without touching the code. `NSUserDefaults` picks up `-key value` launch arguments automatically.

In Xcode: **Product → Scheme → Edit Scheme → Run → Arguments**, add `-screen 4`.

From the command line:

```sh
xcodebuild -project Gallery.xcodeproj -scheme Gallery -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build build

xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Gallery.app
xcrun simctl launch booted dev.heyparsa.liquidglassgallery -screen 9
```

| `-screen` | Screen | Type | Min iOS |
|---|---|---|---|
| 1 | Settings | `SettingsScreen` | 26 |
| 2 | Music Player | `MusicPlayerScreen` | 26 |
| 3 | Onboarding | `OnboardingFlow` | 26 |
| 4 | Photo Detail | `PhotoDetailScreen` | 26 |
| 5 | Dashboard | `DashboardScreen` | 26 |
| 6 | Chat | `ChatScreen` | 26 |
| 7 | Profile | `ProfileScreen` | 26 (uses `.tabs` on 27) |
| 8 | Login | `LoginScreen` | 26 |
| 9 | Health (full TabView shell) | `HealthAppShell` | 26 (nav bar minimizes on 27) |
| 10 | Store (iOS 27 chrome APIs) | `StoreAppShell` | 27 |

## How it's wired

`project.yml` points at `../skills/liquid-glass/examples` rather than keeping a copy. That way the app and the skill can't drift apart: editing an example here edits the skill. The generated `Gallery.xcodeproj` is gitignored; regenerate it with `xcodegen generate`.

## Checking the examples

Before a release:

```sh
# 1. The linter, from the repo root: no errors expected
python3 skills/liquid-glass/scripts/check_glass.py skills/liquid-glass/examples --target 26.0

# 2. A clean build with Xcode 27
xcodebuild -project Gallery.xcodeproj -scheme Gallery -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Then run each screen at both ends of the Liquid Glass slider (Settings, iOS 27), with Reduce Transparency, Increase Contrast and Reduce Motion on.

## Capturing screenshots

```sh
for i in $(seq 1 10); do
  xcrun simctl terminate booted dev.heyparsa.liquidglassgallery 2>/dev/null
  xcrun simctl launch booted dev.heyparsa.liquidglassgallery -screen "$i"
  sleep 3
  xcrun simctl io booted screenshot --type=png "screen-$i.png"
done
```
