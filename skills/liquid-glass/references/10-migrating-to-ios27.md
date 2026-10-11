# Migrating to iOS 27, and supporting older targets

This file is procedural: what to do when you move a project to Xcode 27 and the iOS 27 SDK, how to gate the new APIs, and how to handle deployment targets below 26. For *what* changed, see [09-whats-new-ios27.md](09-whats-new-ios27.md).

## Contents

1. [Choose the deployment target](#1-choose-the-deployment-target)
2. [Rebuild checklist](#2-rebuild-checklist)
3. [Gating iOS 27 APIs](#3-gating-ios-27-apis)
4. [Replace deprecated calls](#4-replace-deprecated-calls)
5. [Optional upgrades to iOS 27 chrome](#5-optional-upgrades-to-ios-27-chrome)
6. [Deployment targets below 26](#6-deployment-targets-below-26)
7. [Bringing a pre-Liquid Glass screen up to date](#7-bringing-a-pre-liquid-glass-screen-up-to-date)

---

## 1. Choose the deployment target

| Target | Glass APIs | iOS 27 APIs | Notes |
|---|---|---|---|
| **27.0** | Use directly | Use directly | Simplest code. Users still on iOS 26 can't install. iOS 27 runs on the same iPhones as iOS 26, so no hardware is dropped. |
| **26.x** | Use directly | Gate with `#available(iOS 27.0, *)` | The common case in late 2026, and what this skill's examples use (26.0). |
| **Below 26** | Gate with `#available(iOS 26.0, *)` and provide a fallback | Gate | System components still adopt Liquid Glass on devices running 26+, as long as you build with the 26/27 SDK. See [§6](#6-deployment-targets-below-26). |

Whatever the target, **the SDK decides the look**. Building with Xcode 27 always produces the Liquid Glass design on iOS 26+ devices, because `UIDesignRequiresCompatibility` is ignored. From April 2027, App Store uploads must use the iOS 27 SDK.

---

## 2. Rebuild checklist

Copy this and work through it:

```
- [ ] Build with Xcode 27 (Swift 6.4). Fix any @State-macro / ContentBuilder source breaks (TN3211).
- [ ] Delete UIDesignRequiresCompatibility from Info.plist (ignored for 27-SDK builds).
- [ ] Confirm a launch screen exists and the app uses the scene life cycle (SwiftUI App: yes).
- [ ] Sheets/popovers: move .controlSize / .buttonBorderShape / .buttonSizing inside the presented content.
- [ ] TabView(selection:) never points at a hidden or conditional tab.
- [ ] .searchable(placement: .toolbarPrincipal)? The nav bar now auto-minimizes. Keep it, or opt out with .never.
- [ ] Any .scrollEdgeEffectStyle(.soft, …) override: re-evaluate against the new .automatic look.
- [ ] Custom glass visuals (dimming layers, overlays, tints): re-check with the darker edge and brighter highlights.
- [ ] Liquid Glass slider: test at ultra clear and at fully tinted.
- [ ] iPad: inactive-window dimming (appearsActive), edge-to-edge sidebars, hidden menu-item icons.
- [ ] iPhone Duo (27.1): check vertical bars and custom floating glass in Device Hub.
- [ ] Run: python3 <skill-dir>/scripts/check_glass.py <sources> --target <deployment target>
- [ ] Walk checklists/pre-ship-checklist.md.
```

---

## 3. Gating iOS 27 APIs

Three techniques cover every case. Full code is in [08-system-chrome.md § 9](08-system-chrome.md#9-gating-ios-27-chrome-apis-on-a-26-target).

| The new thing is… | Gate with | Example |
|---|---|---|
| A new **member** of an existing type | A computed value with `if #available` | `TabRole.prominent`, `.topBarPinnedTrailing` |
| A new **view modifier** | A `@ViewBuilder` extension that returns `self` on older OSes | `toolbarMinimizationBehavior`, `presentationPlacement`, `textInputBorderShape` |
| A new **`ToolbarContent` modifier or type** | A `ViewModifier` that applies one of two `.toolbar { }` blocks | `visibilityPriority`, `contentMarginsRemoved`, `ToolbarOverflowMenu` |
| A new **transition** | A `@ViewBuilder` extension on the sheet content | `.navigationTransition(.crossFade)` |

```swift
extension View {
    @ViewBuilder
    func crossFadePresentation() -> some View {
        if #available(iOS 27.0, *) {
            navigationTransition(.crossFade)
        } else {
            self
        }
    }
}
```

Rules:
- List every platform you ship: `#available(iOS 27.0, macOS 27.0, *)`. Some APIs don't exist on every platform. For example, `ToolbarOverflowMenu` has no macOS version and `crossFade` has none either. Wrap those in `#if os(iOS)` for multiplatform code.
- Don't gate the *glass* APIs on a 26 target. They are all 26.0.
- If the target is 27, delete the gates.

---

## 4. Replace deprecated calls

These carry `deprecatedAt: 27.2`. They compile today and start warning when the target reaches 27.2. Replace them while you're in the file.

```swift
// Before                                              // After
.toolbarBackground(.hidden, for: .navigationBar)       .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
.toolbar(.hidden, for: .tabBar)                        .toolbarVisibility(.hidden, for: .tabBar)
.statusBarHidden(true)                                 .toolbarVisibility(.hidden, for: .statusBar)   // 27.0+
ScrollView(.horizontal, showsIndicators: false) { }    ScrollView(.horizontal) { }.scrollIndicators(.hidden)
.overlay(Badge(), alignment: .topTrailing)             .overlay(alignment: .topTrailing) { Badge() }
.background(Card(), alignment: .top)                   .background(alignment: .top) { Card() }
.textFieldStyle(.roundedBorder)                        .textFieldStyle(.bordered).textInputBorderShape(.roundedRectangle)  // 27.0+
@Environment(\.accessibilityShowButtonShapes)          @Environment(\.accessibilityShowBorders)
```

The replacements for `toolbarBackground`, `toolbar(_:for:)`, `ScrollView`, `overlay`, and `background` are available on iOS 18 or earlier, so they need no gate. `toolbarVisibility(_:for: .statusBar)` and `textInputBorderShape` are 27.0, so gate them on a 26 target, or keep the old call until your target moves.

---

## 5. Optional upgrades to iOS 27 chrome

| If the code has… | On iOS 27, consider… |
|---|---|
| A custom "…" `Menu` in the navigation bar | `toolbarOverflowMenu { … }` / `ToolbarOverflowMenu` |
| Key toolbar items vanishing into overflow | `.visibilityPriority(.high)` on that `ToolbarItem` or `ToolbarItemGroup` |
| A compose or share item that shifts position | `ToolbarItem(placement: .topBarPinnedTrailing)` |
| A custom scroll handler that hides the navigation bar | `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)` |
| A floating glass button imitating a separate tab | `Tab(…, role: .prominent)` |
| A custom fade-in sheet | `.navigationTransition(.crossFade)` on the sheet content |
| Sheet offsets to dock a panel on iPad | `.presentationPlacement(.leading)` |
| Border hacks to match text fields to capsule buttons | `.textFieldStyle(.bordered).textInputBorderShape(.capsule)` |
| A segmented `Picker` that switches content views | `.pickerStyle(.tabs)` |
| `statusBarHidden` or `preferredStatusBarStyle` bridging | `toolbarVisibility` / `toolbarColorScheme(_:for: .statusBar)` |
| `GeometryReader` math to match container corners | `GeometryProxy.concentricCornerRadii` |
| Negative padding to make a toolbar avatar fill its item | `.contentMarginsRemoved()` on the `ToolbarItem` |

---

## 6. Deployment targets below 26

Most shipping apps still support iOS 17 or 18. Built with the 26/27 SDK, their standard components (bars, tab bars, sheets, menus) render Liquid Glass on iOS 26+ devices and keep the old look on earlier OS versions. Only *custom* glass needs gating:

```swift
extension View {
    /// Liquid Glass on 26+, a standard material on earlier systems.
    @ViewBuilder
    func glassOrMaterial(in shape: some Shape = Capsule()) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }

    @ViewBuilder
    func glassButtonStyleIfAvailable() -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}

/// GlassEffectContainer on 26+, plain content earlier.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat? = nil
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
```

- Gate only the glass-specific modifiers, not whole screens.
- A material is the right *fallback* for a floating control before iOS 26. From 26 on, use glass for the functional layer and materials for content.
- Custom bar backgrounds you still need for iOS 17/18 should be skipped on 26+, where Apple asks you to remove them. Wrap them in `if #unavailable(iOS 26.0)` inside a `@ViewBuilder` helper.
- `glassEffectID` and `glassEffectTransition` need the same gate. Keep morphing code inside the `#available(iOS 26.0, *)` branch.

---

## 7. Bringing a pre-Liquid Glass screen up to date

1. **Remove custom bar styling.** Delete `UINavigationBarAppearance` backgrounds and `toolbarBackground(Color…)`. Remove tinted bar items that are only decorative.
2. **Use system components.** Replace a custom tab bar with `TabView` and `Tab`, a custom search field with `.searchable`, and custom sheet chrome with `.sheet` and detents. Remove `presentationBackground`.
3. **Floating controls.** Replace `.background(.ultraThinMaterial)` or blur-and-stroke "glass" on *floating controls* with `.buttonStyle(.glass)`, `.glassProminent`, or `glassEffect`. Group neighbors in a `GlassEffectContainer`.
4. **Content stays content.** Cards, rows, and backgrounds keep solid fills or standard materials. Remove any glass you find on them.
5. **Corners.** Replace hard-coded inner radii with `ConcentricRectangle` / `.rect(corners: .concentric)` plus `.containerShape(_:)` on the parent.
6. **Tint.** Tint one primary action per view (prominent style). Move brand color into the content layer.
7. **Verify.** Run the linter, then walk [checklists/pre-ship-checklist.md](../checklists/pre-ship-checklist.md).

The ❌/✅ pairs for each of these are in [07-anti-patterns.md](07-anti-patterns.md).

---

## Sources

- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) · [`UIDesignRequiresCompatibility`](https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility) · [iOS & iPadOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes) · [Xcode support](https://developer.apple.com/support/xcode/)
- Technote TN3211 *Resolving SwiftUI source incompatibilities for State and ContentBuilder*
