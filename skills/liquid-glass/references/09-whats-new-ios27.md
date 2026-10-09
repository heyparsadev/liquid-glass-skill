# What's new for Liquid Glass in iOS 27

This file covers iOS, iPadOS, macOS, tvOS, and watchOS 27, plus the iOS 26.x point releases. It records what changed for Liquid Glass after iOS 26.0, from Apple's documentation, release notes, the HIG change log, and WWDC26. Read it when a task names iOS 27, Xcode 27, or iPhone Duo, or when a user reports that something "looks different on 27".

**The short version.** The SwiftUI glass API (`Glass`, `glassEffect`, `GlassEffectContainer`, morphing, button styles) **did not change**. The material was refined automatically, the opt-out was removed, the user got a slider, and the new APIs are all in the chrome around the glass: toolbars, tabs, and presentations.

## Contents

1. [The material: automatic changes](#1-the-material-automatic-changes)
2. [The Liquid Glass look setting](#2-the-liquid-glass-look-setting)
3. [Compatibility mode removed and SDK requirements](#3-compatibility-mode-removed-and-sdk-requirements)
4. [New SwiftUI APIs](#4-new-swiftui-apis)
5. [Behavior changes when you build with the 27 SDK](#5-behavior-changes-when-you-build-with-the-27-sdk)
6. [Deprecations](#6-deprecations)
7. [Accessibility](#7-accessibility)
8. [iPhone Duo (iOS 27.1)](#8-iphone-duo-ios-271)
9. [HIG changes in 2026](#9-hig-changes-in-2026)
10. [Tooling](#10-tooling)
11. [iOS 26.x point releases](#11-ios-26x-point-releases)
12. [What did not change](#12-what-did-not-change)

---

## 1. The material: automatic changes

WWDC26 *Platforms State of the Union* describes three changes:

- "We tuned Liquid Glass so it more effectively diffuses complex content behind it."
- "To establish more depth and separation, we also introduced a darkened edge along with brighter specular highlights."
- "Apps already using Liquid Glass get these improvements automatically when they run on this year's releases without even needing to recompile."

What this means for code:
- Don't add custom borders, edge strokes, extra blur, or shadows to imitate depth. The system draws the edge.
- Re-check any custom glass visuals (dimming layers, tints, overlays) on iOS 27. What was tuned to look right on 26 may now look heavier.
- On macOS 27, `interactive()` glass also responds to pointer clicks (WWDC26 269).

---

## 2. The Liquid Glass look setting

| Release | What the user gets |
|---|---|
| iOS 26.0 | No choice |
| iOS 26.1 | A preferred look for Liquid Glass: **Clear** or **Tinted** |
| iOS 27 | A slider "anywhere from ultra clear to fully tinted" (WWDC26 Keynote) |

- Standard glass follows the setting automatically. "For developers who have already adopted Liquid Glass, these customizations apply in your apps right away." "Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint" (WWDC26 269).
- **There is no API to read the setting.** It is not in `EnvironmentValues` or `UITraitCollection`. Never invent one, such as `\.liquidGlassTint` or `\.glassIntensity`.
- **Test at both ends of the slider.** Legibility risk is greatest at *ultra clear*. At *fully tinted*, check that tinted and prominent controls stay distinct.
- It is a look preference, not an accessibility setting, and is separate from Reduce Transparency. The HIG: variants "can differ in response to certain system settings, like if people choose a preferred look for Liquid Glass in their device's settings, or turn on accessibility settings that reduce transparency or increase contrast."

---

## 3. Compatibility mode removed and SDK requirements

- **`UIDesignRequiresCompatibility` is ignored.** "The system ignores this key when you build for iOS 27 or later, iPadOS 27 or later, Mac Catalyst 27 or later, macOS 27 or later, or tvOS 27 or later." In WWDC26 *State of the Union*: "We'll be removing support for opting to use the old design. So once your app is recompiled with Xcode 27, it will automatically begin to use the new design with Liquid Glass." Don't suggest the key as an opt-out.
- **App Store deadline.** "Starting April 2027, apps and games uploaded to App Store Connect … iOS and iPadOS apps must be built with the iOS 27 & iPadOS 27 SDK or later." The same applies to tvOS, visionOS, and watchOS 27; macOS is not on the list. Since April 28, 2026, uploads have required the iOS 26 SDK.
- **Other 27-SDK requirements** (iOS & iPadOS 27 release notes):
  - Apps must use the scene-based life cycle. SwiftUI `App` apps already do.
  - Apps must include a launch screen.
  - Apps are automatically opted in to resizability, so test with Device Hub resize mode or the Resizable Canvas.
  - `PreviewProvider` is deprecated in favor of `#Preview`.
- **Deployment target.** Xcode 27 builds for iOS 15–27. You can keep a 26.0 target and gate the 27 APIs ([10-migrating-to-ios27.md](10-migrating-to-ios27.md)).

---

## 4. New SwiftUI APIs

None of these are glass APIs. All of them shape the glass chrome. Details and code are in [08-system-chrome.md](08-system-chrome.md).

| API | What it does | Availability |
|---|---|---|
| `toolbarMinimizationBehavior(_:for:)` | Minimizes the navigation bar on scroll. **Not** `toolbarMinimizeBehavior`, which is the WWDC26 video spelling. | 27.0, all platforms |
| `toolbarMinimizationRestoration(_:for:)` | `.atScrollEdge`: restore only at the scroll edge | 27.0 |
| `toolbarMinimizationSafeAreaAdjustment(_:for:)` | `.disabled`: content doesn't reflow (full-bleed media) | 27.0 |
| `ToolbarContent.visibilityPriority(_:)` | `.high` keeps an item out of the overflow menu | iOS 27.0; macOS 26.1 |
| `ToolbarOverflowMenu`, `toolbarOverflowMenu(content:)` | Actions that always live in the system overflow menu | iOS, iPadOS, Catalyst, visionOS 27.0 |
| `ToolbarItemPlacement.topBarPinnedTrailing` | A trailing item that doesn't overflow | iOS, iPadOS, Catalyst, visionOS 27.0 |
| `ToolbarContent.contentMarginsRemoved(_:)` | Edge-to-edge content in a toolbar item | 27.0 |
| `ToolbarPlacement.statusBar` | Status bar visibility and color scheme | iOS, iPadOS, Catalyst 27.0 |
| `TabRole.prominent` | One tab in a separate trailing position | 27.0, all platforms |
| `NavigationTransition.crossFade` | A sheet fades in over content instead of sliding up | 27.0 (not macOS) |
| `presentationPlacement(_:)` | Places a sheet `.leading`, `.trailing`, or `.center` | 27.0 |
| `textInputBorderShape(_:)`, `TextFieldStyle.bordered` | Text field borders that match capsule buttons | 27.0 |
| `PickerStyle.tabs` | A segmented look that VoiceOver announces as tabs, for content-switching pickers | 27.0 (not watchOS) |
| `GeometryProxy.concentricCornerRadii` | The resolved concentric radii, for custom drawing | 27.0 |
| `ContentBuilder` | `typealias` of `ViewBuilder`, the unified builder | Xcode 27, any target |
| `alert`/`confirmationDialog` with `item:` or `error:` | Data-driven dialogs | Xcode 27 SDK; most back-deploy to iOS 15 |
| `swipeActions(…onPresentationChanged:)`, `reorderable()`, `reorderContainer(…)` | Swipe and reorder in any container | 27.0 (not tvOS) |

**Beta (iOS/iPadOS 27.1).** For iPhone Duo there are `toolbarVerticalEdge`, `toolbarVerticalBehavior(_:)`, `axisBehavior(_:)`, `toolbarVerticalCompressionBehavior(_:)`, `ReservedRegion`, `onHingeChange`, and `ArrangementView`.

---

## 5. Behavior changes when you build with the 27 SDK

- **Navigation bars may minimize by themselves.** On iOS, `.searchable(…, placement: .toolbarPrincipal)` makes `ToolbarMinimizationBehavior.automatic` minimize the bar. Opt out with `.toolbarMinimizationBehavior(.never, for: .navigationBar)`.
- **Control styling resets in sheets and popovers.** `controlSize`, `buttonSizing`, `buttonRepeatBehavior`, `menuIndicatorVisibility`, and `ButtonBorderShape` reset to their defaults. Set them inside the presented content.
- **`TabView` selection must be a visible tab.** Otherwise it "might crash".
- **`@State` is a macro.** It "only initializes and stores your property once when it's a class". Apple's technote TN3211 lists the source incompatibilities. None of this skill's examples hit them.
- **Scroll edge effect `.automatic`** "no longer switches between the existing soft and hard styles but provides its own visuals". Re-evaluate `.soft` overrides.
- **Menu item images on iPadOS and macOS 27.** The menu bar (and context menus on macOS) hide most menu item symbol images by default. Use `.labelStyle(.titleAndIcon)` for items whose icon must show.
- **iPad and Mac.**
  - Sidebars extend to the window edges.
  - Sidebar icons regain color from the app's accent color; `List` and `Label` handle this automatically.
  - iPadOS 27 dims icons and text in inactive windows. WWDC26 shows custom elements following `@Environment(\.appearsActive)`, although the reference page still describes the value as macOS-only.

---

## 6. Deprecations

Each of these carries `deprecatedAt: 27.2`. They warn once your deployment target reaches 27.2, and they still compile today.

| Deprecated | Replacement |
|---|---|
| `toolbarBackground(_ visibility: Visibility, for:)` | `toolbarBackgroundVisibility(_:for:)` (iOS 18+) |
| `toolbar(_ visibility: Visibility, for:)` | `toolbarVisibility(_:for:)` (iOS 18+) |
| `statusBarHidden(_:)` | `toolbarVisibility(_:for: .statusBar)` (27.0) |
| `ScrollView(_:showsIndicators:content:)` | `ScrollView(_:content:)` + `.scrollIndicators(.hidden)` |
| `overlay(_:alignment:)`, `background(_:alignment:)` (view argument) | `overlay(alignment:content:)`, `background(alignment:content:)` |
| `TextFieldStyle.roundedBorder`, `.squareBorder` | `.textFieldStyle(.bordered)` + `textInputBorderShape(_:)` |
| `accessibilityShowButtonShapes` (renamed) | `accessibilityShowBorders` |

Not deprecated: `tabBarMinimizeBehavior(_:)`, `navigationBarTitleDisplayMode(_:)`, `ScrollViewReader`, and the ShapeStyle forms of `background`.

---

## 7. Accessibility

- **`accessibilityShowBorders`** replaces `accessibilityShowButtonShapes`. "When this value is true, draw interactive custom controls such as buttons with clearly visible edges." macOS 27 adds a dedicated Show Borders setting; earlier macOS versions tie it to Increase Contrast.
- **`accessibilityReduceHighlightingEffects`** (26.4) is the *Reduce Bright Effects* setting. When it is true, custom controls "should be drawn in such a way that minimizes highlighting and flashing". Suppress custom shimmer and glow on glass controls.
- **Xcode 27 previews** gained *Control Borders* and *Color Scheme Contrast* override groups.
- Liquid Glass "seamlessly adapts to a variety of accessibility settings users may choose, such as reducing transparency or increasing contrast." No code changes are needed for system glass. See [05-accessibility.md](05-accessibility.md).

---

## 8. iPhone Duo (iOS 27.1)

Apple announced iPhone Duo, the first folding iPhone, for October 23, 2026, running iOS 27.1. On it, toolbars, tab bars, and navigation controls move to a **vertical bar at the side**, except on the inner display in portrait. From April 2027, App Store submissions need iPhone Duo screenshots.

What matters for glass:
- Keep system bars in their default placement.
- Give every toolbar item both a title and a symbol.
- Group items instead of spacing them by hand.
- Keep custom floating glass away from the side bar and reserved regions.

APIs and the HIG rules are in [08-system-chrome.md § 8](08-system-chrome.md#8-iphone-duo-and-vertical-bars-ios-271).

---

## 9. HIG changes in 2026

| Page | Date | Change relevant to glass |
|---|---|---|
| Design principles | June 8, 2026 | Reintroduced as eight principles: Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, Delight |
| Search fields, Tab bars | June 8, 2026 | Search tab as a standard tab or a button appearance; `TabRole.prominent` |
| Scroll views | June 8, 2026 | Prefer the automatic scroll edge effect; one per view; only behind floating UI |
| Sidebars, App icons | June 8, 2026 | Sidebar icon color; refined Liquid Glass icon guidance (Icon Composer) |
| Sheets | March 24, 2026 | Cancel/Done/Back placement rules |
| Designing for iPhone Duo | Sept 9, 2026 | New page: vertical bars, reserved regions |
| Branding | Sept 9, 2026 | Move brand color into the content layer; use accent color for primary actions and status |
| Materials | Sept 9, 2025 (unchanged in 2026) | Glass is for the functional layer; standard materials for content |

---

## 10. Tooling

- **Xcode 27** includes Swift 6.4 and the 27 SDKs, and requires macOS Tahoe 26.6 or later.
- **Icon Composer 2.0** previews icons in the new rendering ("refractivity, outside specular, and deeper shadows") or the original design generation.
- **SF Symbols 8** ships with the 27 releases. SF Symbols 7 shipped with iOS 26.
- **Instruments and Organizer.** The Organizer's new *Hitches* metric replaces *Scrolling* and covers all animations. Use the SwiftUI and Animation Hitches instruments for glass-heavy screens.

---

## 11. iOS 26.x point releases

| Release | Change |
|---|---|
| 26.1 | `GlassButtonStyle.init(_:)` and `.buttonStyle(.glass(_:))` |
| 26.1 | `tabViewBottomAccessory(isEnabled:content:)` |
| 26.1 | The Clear/Tinted look setting |
| 26.1 | Fixed: buttons without an explicit label showed text instead of a symbol in toolbars |
| 26.1 | Known issue: `@FocusState` doesn't work in `safeAreaBar` |
| 26.4 | `ToolbarContent.hidden(_:)` |
| 26.4 | `accessibilityReduceHighlightingEffects` |
| 26.4 | Xcode 26.4–26.6 ship Swift 6.3 |

---

## 12. What did not change

- `Glass` still has only `.regular`, `.clear`, `.identity`, `tint(_:)`, and `interactive(_:)`. There are no new variants.
- `glassEffect(_:in:)` still has one overload, with no `isEnabled:` parameter.
- `GlassEffectContainer`, `glassEffectID`, `glassEffectUnion`, and `glassEffectTransition` are unchanged.
- The glass APIs are still not available on visionOS.
- iOS 27 supports the same iPhones as iOS 26, from iPhone 11 on.
- HIG Materials, the core "where does glass go" guidance, is unchanged.

---

## Sources

- [SwiftUI updates](https://developer.apple.com/documentation/updates/swiftui) (June 2026, September 2026) · [iOS & iPadOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes) · [`UIDesignRequiresCompatibility`](https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility) · [Apple Developer News](https://developer.apple.com/news/)
- [HIG What's new](https://developer.apple.com/design/whats-new/) · [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- WWDC26: 101 Keynote, 102 *Platforms State of the Union*, 251 *Communicate your brand identity on iOS*, 269 *What's new in SwiftUI*, 278 *Modernize your UIKit app*, 292 *Design intuitive search experiences*. Tech talk 111462 *Raise the bar with iPhone Duo*.
