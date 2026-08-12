# Gallery

A host app for running the nine example screens on a simulator. It exists so the
examples can be checked against a real SDK instead of taken on faith — every
screenshot in the repo README was captured from this app.

## Run it

Requires Xcode 26 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
```

Then, from this directory:

```sh
xcodegen generate
open Gallery.xcodeproj
```

Pick an iPhone simulator running iOS 26 and hit Run. The app opens on the
Settings screen.

## Switching screens

The app reads a `screen` launch argument, so you can jump straight to any of the
nine without touching the code. `NSUserDefaults` picks up `-key value` launch
arguments automatically.

In Xcode: **Product → Scheme → Edit Scheme → Run → Arguments**, add `-screen 4`.

From the command line:

```sh
xcodebuild -project Gallery.xcodeproj -scheme Gallery -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build build

xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Gallery.app
xcrun simctl launch booted dev.heyparsa.liquidglassgallery -screen 9
```

| `-screen` | Screen | Type |
|---|---|---|
| 1 | Settings | `SettingsScreen` |
| 2 | Music Player | `MusicPlayerScreen` |
| 3 | Onboarding | `OnboardingFlow` |
| 4 | Photo Detail | `PhotoDetailScreen` |
| 5 | Dashboard | `DashboardScreen` |
| 6 | Chat | `ChatScreen` |
| 7 | Profile | `ProfileScreen` |
| 8 | Login | `LoginScreen` |
| 9 | Health (full TabView shell) | `HealthAppShell` |

## How it's wired

`project.yml` points at `../skills/liquid-glass/examples` rather than keeping a
copy, so the app and the skill cannot drift apart — editing an example here
edits the skill. The generated `Gallery.xcodeproj` is gitignored; regenerate it
with `xcodegen generate`.

## Capturing screenshots

```sh
for i in $(seq 1 9); do
  xcrun simctl terminate booted dev.heyparsa.liquidglassgallery 2>/dev/null
  xcrun simctl launch booted dev.heyparsa.liquidglassgallery -screen "$i"
  sleep 3
  xcrun simctl io booted screenshot --type=png "screen-$i.png"
done
```
