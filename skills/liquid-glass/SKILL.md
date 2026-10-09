---
name: liquid-glass
description: Builds, reviews, and migrates SwiftUI interfaces that use Apple's Liquid Glass design on iOS and iPadOS 26 and 27, macOS 26 (Tahoe) and 27, watchOS 26-27, and tvOS 26-27, with Xcode 26 or 27. Covers glassEffect, Glass (regular, clear, identity, tint, interactive), GlassEffectContainer, glassEffectID and glassEffectUnion morphing, the glass and glassProminent button styles, concentric shapes, and the system glass chrome (toolbars, tab bars, search, sheets, scroll edge effects), plus the iOS 27 toolbar, tab bar and iPhone Duo changes, accessibility, and performance. Use when writing or editing SwiftUI for iOS 26 or iOS 27, when the user mentions Liquid Glass, glassEffect, GlassEffectContainer, glass buttons, iOS 26 or iOS 27 design, Xcode 27, or the WWDC25/WWDC26 design changes, or asks to redesign, modernize, audit, or migrate a SwiftUI screen to the current system look. Not for UIKit, AppKit, visionOS, React Native, or Flutter.
license: MIT
compatibility: SwiftUI projects built with Xcode 26 or later (Xcode 27 for the iOS 27 APIs). The Liquid Glass APIs require iOS, iPadOS, Mac Catalyst, macOS, tvOS, or watchOS 26 or later and are not available on visionOS. The optional linter needs Python 3.
metadata:
  version: "2.0.0"
  platforms: "iOS 26+, iPadOS 26+, Mac Catalyst 26+, macOS 26+, tvOS 26+, watchOS 26+"
  docs-verified: "Apple developer documentation as of October 2026 (iOS 27.0 SDK; iOS 27.1 APIs marked beta)"
---

# Liquid Glass for SwiftUI

Liquid Glass is the material Apple introduced in iOS 26 for the **functional layer**: the controls and navigation that float above an app's content. Standard SwiftUI components adopt it automatically when you build with the iOS 26 or 27 SDK. Custom views opt in with `glassEffect(_:in:)`.

This skill covers the API, the system chrome that already uses glass, the iOS 27 changes, Apple's design rules, accessibility, performance, and anti-patterns. It also includes copy-ready patterns and full-screen examples.

## Scope

- **In scope.** SwiftUI on iOS, iPadOS, Mac Catalyst, macOS, tvOS, and watchOS 26 and later, built with Xcode 26 or later. The iOS 27 APIs need Xcode 27.
- **visionOS.** `Glass`, `glassEffect`, `GlassEffectContainer`, and the glass button styles are not available there. visionOS uses its own system glass and `glassBackgroundEffect`.
- **Out of scope.** UIKit and AppKit (`UIGlassEffect`, `NSGlassEffectView`), React Native, Flutter, and app icons (made in Icon Composer).
- **Deployment targets below 26.** System components still get Liquid Glass when built with the 26 or 27 SDK. Custom glass needs `if #available(iOS 26.0, *)`. See [references/10-migrating-to-ios27.md](references/10-migrating-to-ios27.md#deployment-targets-below-26).

## Workflow

Copy this checklist into your response and tick items off as you go:

```
- [ ] 1. Find the deployment target and platforms (IPHONEOS_DEPLOYMENT_TARGET, Package.swift platforms).
         Target 26.x → gate every iOS 27 API with `if #available(iOS 27.0, *)`.
- [ ] 2. Classify every view: functional layer (controls and navigation floating above content) or content layer.
- [ ] 3. Choose APIs with the decision tree below. Prefer system components.
- [ ] 4. Write the code. Check each glass, toolbar, tab, or sheet signature against references/01 and 08.
- [ ] 5. Run the linter: python3 <skill-dir>/scripts/check_glass.py <files-or-folders> --target <deployment target>
         Fix what it reports and re-run until it is clean.
- [ ] 6. Walk checklists/pre-ship-checklist.md.
```

The linter catches the mistakes models make most often with this API. These include invented parameters (`glassEffect(…, isEnabled:)`, `.containerConcentric`), the WWDC26 pre-release name `toolbarMinimizeBehavior`, `DefaultToolbarItem` nested in `ToolbarItem`, ungated iOS 27 APIs, and modifiers deprecated in the 27 SDK.

## Decision tree

```
Is this a control or navigation element floating above content?
│
├─ No: a card, list row, hero, background, or body text
│     → No glass. Use a solid color or a standard material (.regularMaterial, …).
│
└─ Yes
   ├─ Is there a system component for it? (navigation bar, toolbar item, tab bar,
   │  search field, sheet, menu, alert, standard button)
   │     → Use it. It is already glass. Never add .glassEffect() on top.
   │       Buttons: .buttonStyle(.glass) for secondary, .buttonStyle(.glassProminent) for the primary action.
   │
   ├─ One custom element
   │     → .glassEffect(.regular, in: shape). Add .interactive() if a custom view responds to touch.
   │
   ├─ Several custom glass elements near each other
   │     → Wrap them in one GlassEffectContainer.
   │       ├─ They appear, disappear, or morph → add @Namespace, .glassEffectID(_:in:), and withAnimation.
   │       └─ Separate shapes should read as one → .glassEffectUnion(id:namespace:)
   │
   └─ Over photos or video, with bold, bright content on top
         → .clear, with a dimming layer behind it when the media is bright.
```

## Golden rules

1. **Glass is for the functional layer only.** Use it on controls and navigation that float above content. Never use it on cards, rows, heroes, or backgrounds. ([02](references/02-hig-principles.md#where-glass-belongs))
2. **Never put glass on glass.** Anything placed on a glass surface uses fills, transparency, or vibrant foreground styles, not another `glassEffect`.
3. **Prefer system components.** Bars, toolbar items, tab bars, search, sheets, and the glass button styles already render glass. Don't re-glass them, and remove custom bar backgrounds.
4. **Put nearby custom glass in one `GlassEffectContainer`.** Glass can't sample other glass, so a shared container keeps the result visually correct and lets the system render the shapes together. Keep the container's `spacing` smaller than the layout gap unless you want the shapes to merge.
5. **Use `.regular` by default.** Use `.clear` only over media-rich content, with bold content on top and a dimming layer when the media is bright. Never mix the two variants in one group.
6. **Tint signals prominence, not decoration.** Tint the one or two primary actions in a view. Put brand color in the content layer.
7. **Make nested corners concentric.** Use `ConcentricRectangle()` or `.rect(corners: .concentric)`, and declare the parent shape with `.containerShape(_:)`. There is no `.containerConcentric` in SwiftUI.
8. **Accessibility adapts automatically.** Don't swap glass for `.identity` under Reduce Transparency, because the system already frosts it. Your job is labels, contrast, custom backgrounds, and custom motion. ([05](references/05-accessibility.md))
9. **Standard materials are for the content layer.** Never use `Material` or blur to fake glass on controls. Never use glass to style content.
10. **Don't invent API.** `glassEffect` has no `isEnabled:` parameter. The iOS 27 navigation bar API is `toolbarMinimizationBehavior(_:for:)`. Gate iOS 27 APIs when the target is 26. When unsure, check [01](references/01-api-reference.md) and [08](references/08-system-chrome.md).

## Glossary

Use these terms consistently:

- **Functional layer.** Apple's term for the controls and navigation (bars, toolbars, tab bars, sidebars, floating buttons) that float above content in Liquid Glass.
- **Content layer.** Everything that scrolls or carries information underneath: lists, cards, media, backgrounds.
- **Spacing (blend distance).** The `GlassEffectContainer(spacing:)` value. Shapes closer than this blend together, and the larger the value, the sooner they merge.
- **Liquid Glass look setting.** The user's system preference: a Clear/Tinted choice in iOS 26.1, a slider "from ultra clear to fully tinted" in iOS 27. Apps can't read it, and standard glass follows it automatically.

## iOS 27 at a glance

- **No new glass APIs.** `Glass`, `glassEffect`, and `GlassEffectContainer` are unchanged since 26.0. The material itself was refined automatically, with more diffusion, a darkened edge, and brighter specular highlights.
- **The opt-out is gone.** `UIDesignRequiresCompatibility` is ignored when you build with the 27 SDKs. From April 2027, App Store uploads must be built with the iOS 27 SDK.
- **New chrome APIs.** These are all iOS 27.0+ and need gating on a 26 target:
  - `toolbarMinimizationBehavior(_:for:)`
  - `visibilityPriority(_:)`
  - `ToolbarOverflowMenu` and `toolbarOverflowMenu(content:)`
  - `.topBarPinnedTrailing`
  - `TabRole.prominent`
  - `NavigationTransition.crossFade`
  - `presentationPlacement(_:)`
  - `textInputBorderShape(_:)`
  - `PickerStyle.tabs`
- **Scroll edge effects.** The `.automatic` style has new visuals, so re-check any `.soft` override.
- **iPhone Duo (iOS 27.1).** Bars move to the side. The vertical-toolbar APIs are still beta.

Details are in [references/09-whats-new-ios27.md](references/09-whats-new-ios27.md). Migration steps are in [references/10-migrating-to-ios27.md](references/10-migrating-to-ios27.md).

## Files

### References: load the one the task needs

| File | Load when |
|---|---|
| [references/01-api-reference.md](references/01-api-reference.md) | Writing any custom glass: `glassEffect`, `Glass`, containers, morphing, button styles, concentric shapes, availability matrix |
| [references/02-hig-principles.md](references/02-hig-principles.md) | Deciding *where* glass goes, regular vs clear, tint and brand color, legibility |
| [references/03-design-tokens.md](references/03-design-tokens.md) | Picking shapes, spacing, dimming, tints, typography, animation curves |
| [references/04-motion-and-interaction.md](references/04-motion-and-interaction.md) | Morphing, transitions, interactive glass, zoom and cross-fade presentations |
| [references/05-accessibility.md](references/05-accessibility.md) | Reduce Transparency/Motion, Increase Contrast, Show Borders, the look setting, contrast, VoiceOver |
| [references/06-performance.md](references/06-performance.md) | Many glass elements, glass over video, profiling |
| [references/07-anti-patterns.md](references/07-anti-patterns.md) | Reviewing or fixing existing code (❌/✅ pairs) |
| [references/08-system-chrome.md](references/08-system-chrome.md) | Toolbars, navigation bars, tab bars, search, sheets, scroll edge effects (iOS 26 + 27 APIs) |
| [references/09-whats-new-ios27.md](references/09-whats-new-ios27.md) | Anything specific to iOS 27, iPadOS 27, macOS 27, or iPhone Duo |
| [references/10-migrating-to-ios27.md](references/10-migrating-to-ios27.md) | Moving an iOS 26 app to the 27 SDK, availability gating, deprecations, targets below 26 |

### Patterns: one surface each

| File | Shows |
|---|---|
| [patterns/glass-navigation-bar.md](patterns/glass-navigation-bar.md) | `NavigationStack` chrome, toolbar grouping, iOS 27 minimization, overflow, and pinned items |
| [patterns/glass-tab-bar.md](patterns/glass-tab-bar.md) | `TabView` with search tab, bottom accessory, minimize behavior, iOS 27 prominent tab |
| [patterns/glass-floating-toolbar.md](patterns/glass-floating-toolbar.md) | Custom floating glass controls with morphing, pinned with `safeAreaBar` |
| [patterns/glass-card-stack.md](patterns/glass-card-stack.md) | Content-layer cards (no glass) with glass controls over media |
| [patterns/glass-modal-sheet.md](patterns/glass-modal-sheet.md) | Sheets: detents, Close/Done placement, zoom from a toolbar item, iOS 27 cross-fade |
| [patterns/glass-search-field.md](patterns/glass-search-field.md) | `.searchable` placement, minimized search, search tab, scopes, suggestions |

### Examples: full screens

| File | Screen | Key APIs | Min OS |
|---|---|---|---|
| [examples/01-SettingsScreen.swift](examples/01-SettingsScreen.swift) | Settings list | `.searchable` + `.searchToolbarBehavior(.minimize)`, dialog anchored to its button | 26 |
| [examples/02-MusicPlayerScreen.swift](examples/02-MusicPlayerScreen.swift) | Now Playing | `.clear` glass over artwork with dimming, morphing transport controls | 26 |
| [examples/03-OnboardingFlow.swift](examples/03-OnboardingFlow.swift) | Onboarding | Page dots that morph, prominent CTA over a gradient | 26 |
| [examples/04-PhotoDetailScreen.swift](examples/04-PhotoDetailScreen.swift) | Photo viewer | Floating close button, expanding edit menu, `.materialize` | 26 |
| [examples/05-DashboardScreen.swift](examples/05-DashboardScreen.swift) | Health dashboard | Content cards (no glass), bottom-bar search, toolbar | 26 |
| [examples/06-ChatScreen.swift](examples/06-ChatScreen.swift) | Chat | Glass composer bar in `safeAreaBar`, scroll-to-bottom button | 26 |
| [examples/07-ProfileScreen.swift](examples/07-ProfileScreen.swift) | Profile | Morphing segmented switcher, zoom sheet from toolbar | 26 |
| [examples/08-LoginScreen.swift](examples/08-LoginScreen.swift) | Sign in | Glass controls over an animated backdrop, Sign in with Apple | 26 |
| [examples/09-HealthTodayScreen.swift](examples/09-HealthTodayScreen.swift) | App shell | `TabView`, bottom accessory, floating action menu, content cards | 26 |
| [examples/10-InboxScreen.swift](examples/10-InboxScreen.swift) | Mail inbox | iOS 27: nav bar minimization, overflow menu, pinned item, prominent tab, cross-fade sheet | 27 |

Every example marks which views are content layer and which are functional layer. They are written to build in the [Gallery](../../Gallery) host app (`cd Gallery && xcodegen generate`).

### Scripts

- `scripts/check_glass.py` is a read-only linter for Swift files, using only the Python standard library. Run `python3 scripts/check_glass.py --help` for options. It reports `error` (won't compile or is wrong), `warn` (design rule), and `info` (gate or migrate).

## Sources

These are Apple's primary sources. The skill quotes them where it states a rule.

- [Liquid Glass overview](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) · [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) · [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- HIG: [Materials](https://developer.apple.com/design/human-interface-guidelines/materials) · [Color](https://developer.apple.com/design/human-interface-guidelines/color) · [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) · [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) · [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields) · [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets) · [Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views) · [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [SwiftUI updates](https://developer.apple.com/documentation/updates/swiftui) · [iOS & iPadOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes)
- WWDC25: 219 *Meet Liquid Glass*, 323 *Build a SwiftUI app with the new design*, 356 *Get to know the new design system*. WWDC26: 102 *Platforms State of the Union*, 269 *What's new in SwiftUI*.
