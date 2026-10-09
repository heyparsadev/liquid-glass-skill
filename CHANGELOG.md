# Changelog

## 2.0.0 (2026-10)

A full revision for iOS 27, checked against Apple's documentation. The research and verification notes behind it are in [docs/research/ios27](docs/research/ios27).

### Breaking changes to what the skill teaches
- **Removed APIs that don't exist:**
  - `glassEffect(_:in:isEnabled:)` and `glassEffectTransition(_:isEnabled:)`
  - `.rect(cornerRadius: .containerConcentric)`
  - `scrollExtensionMode(_:)`
  - `TabViewBottomAccessoryPlacement.collapsed` (it's `.inline`)
  - `Glass.opacity`
  - `GlassEffectTransition` as an enum (it's a struct)
- **Fixed misuse:**
  - `DefaultToolbarItem` nested in `ToolbarItem`
  - `sharedBackgroundVisibility` applied to a button instead of the item
- **Dropped visionOS.** `Glass`, `glassEffect`, and `GlassEffectContainer` aren't available there.
- **Rules now follow Apple's guidance:**
  - No glass on glass (the old "two layers max" is gone).
  - Standard materials belong in the content layer instead of being banned.
  - Tint is about hierarchy, and brand color lives in the content.
  - Clear glass needs its three conditions and a dimming layer.
  - Reduce Transparency needs no `.identity` swap.
  - Contrast targets match the HIG table.
- **Removed unsourced numbers:** performance multipliers, millisecond budgets, Instruments phase names, and "95% of issues".

### Added
- `references/08-system-chrome.md`: toolbars, tab bars, search, sheets, and scroll edge effects, with iOS 26 and iOS 27 APIs and gating techniques.
- `references/09-whats-new-ios27.md`:
  - automatic material refinements and the Liquid Glass slider
  - `UIDesignRequiresCompatibility` ignored for 27-SDK builds
  - the new APIs, behavior changes, deprecations, iPhone Duo, and 2026 HIG updates
- `references/10-migrating-to-ios27.md`: deployment-target choice, a rebuild checklist, gating, deprecations, targets below 26, and updating pre-26 screens.
- An availability matrix and a "names that do not exist" table in the API reference.
- `scripts/check_glass.py`, a read-only linter, with tests in `tests/`.
- `examples/10-StoreScreen.swift`, an iOS 27 store shell that shows:
  - a prominent tab
  - navigation bar minimization
  - pinned and prioritized toolbar items
  - the overflow menu
  - a cross-fade sheet
- A copyable workflow, a glossary, and a full file index in `SKILL.md`.

### Changed
- `SKILL.md` frontmatter uses only spec keys. `version` and `platforms` moved under `metadata`, and `license` and `compatibility` were added. The description is in the third person and adds iOS 27, Xcode 27, and WWDC26 triggers.
- **All seven references and six patterns** were rewritten. Each long file has a table of contents, quotes Apple with its source, and labels values as *Apple* or *suggested*.
- **Examples 01–09** were reworked so they follow the skill's own rules:
  - Glass appears only on controls and navigation.
  - Content uses materials or fills.
  - Destructive actions aren't prominent primaries.
  - Dialogs are attached to their buttons.
  - Sign in with Apple uses `SignInWithAppleButton`.
  - Accessibility labels were added, and motion follows Reduce Motion.
  - Calls deprecated in 27.2 were replaced.
  - The random values computed in `body` were removed.
  - Personal data was replaced with placeholders.
- The Gallery app adds screen 10 and now needs Xcode 27. The deployment target is still iOS 26.0.
- The plugin version is now 2.0.0. Version 1.0.0 had been pinned since May, so marketplace installs never received the August fixes.

## 1.0.0 (2026-05)

Initial release: a Liquid Glass SwiftUI skill for iOS 26 with references, patterns, nine examples, and a checklist.
