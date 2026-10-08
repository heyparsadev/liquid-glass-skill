# truth-glass-core

_Phase: Research_

## Summary

I checked the core Liquid Glass, shape and layout API that the skill teaches against Apple's DocC JSON (SwiftUI docs as of Oct 2026, Xcode 27 SDK), the HIG Materials page and WWDC26 sessions 102 and 269.

**Bugs that stop the skill's own code from compiling:**
1. `glassEffect(_:in:isEnabled:)` does not exist. The real declaration is `nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View`. The skill uses `isEnabled:` in 01 (lines 19/29/51), 07:127, 06:63/162 and 02:133/166.
2. `glassEffectTransition(_:isEnabled:)` does not exist, and `GlassEffectTransition` is a struct with static vars (identity, matchedGeometry, materialize), not an enum.
3. `.rect(cornerRadius: .containerConcentric)` is invalid. `rect(cornerRadius:)` takes a CGFloat, and the name `containerConcentric` does not exist anywhere. The real API is `ConcentricRectangle`, `.rect(corners: .concentric, isUniform:)` and `Edge.Corner.Style` (concentric, concentric(minimum:), fixed(_:)). The parent must set `.containerShape(...)`, otherwise concentricity does not resolve against the card. This mistake is in 12+ places, including a SKILL.md golden rule.
4. `scrollExtensionMode(.underSidebar)` does not exist.
5. `.sharedBackgroundVisibility` is a `ToolbarContent` modifier, but the skill applies it to a Button.
6. `TabViewBottomAccessoryPlacement` has `.expanded` and `.inline`; there is no `.collapsed`.
7. `DefaultToolbarItem` is `ToolbarContent`, so it cannot sit inside a `ToolbarItem` (01 and the search-field pattern both do this).
8. Smaller ones: `Glass` has no `.opacity`, and `.glassProminent.tint(.blue)` is not a valid expression.

**Wrong availability or platform claims:**
- `Glass`, `glassEffect`, `GlassEffectContainer` and the glass button styles are **not available on visionOS**. The docs list only iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS 26.0; visionOS uses `glassBackgroundEffect`. SKILL.md frontmatter and the API reference claim visionOS 26.
- `ControlSize.extraLarge` dates from iOS 17, not iOS 26. Apple's docs say it "Resolves to `large` on platforms other than visionOS", so the skill's examples are really getting `.large`.
- "Tinted Mode (iOS 26.1+), an opacity multiplier under Accessibility → Display" is wrong:
  - In iOS 26.1 it was a Clear / Tinted choice under Display & Brightness. This comes only from news coverage.
  - In the 27 releases it becomes a slider "anywhere from ultra clear to fully tinted" (Platforms State of the Union, WWDC26).
  - I found no public API that reads this setting.

**Guidance that contradicts Apple:**
- The rule "never use legacy Material" goes against the HIG, which says to use standard materials in the content layer.
- Using `.identity` when Reduce Transparency is on removes the glass entirely. Liquid Glass already adapts to Reduce Transparency on its own.
- The `.clear` variant needs a dimming layer (the HIG says about 35% for bright content). The skill doesn't mention this.
- GlassEffectContainer spacing is described incompletely. If it is larger than the spacing of the HStack/VStack inside it, the glass shapes blend even when nothing is animating.
- The skill puts `.glassEffect(.regular.interactive())` on Buttons in several places, which contradicts its own advice to use the glass button styles.

**Missing APIs that exist and are relevant:**
- `scrollEdgeEffectStyle(_:for:)` with `.automatic`, `.hard` and `.soft`
- `scrollEdgeEffectHidden(_:for:)`
- `safeAreaBar(edge:alignment:spacing:content:)`, which the skill's `safeAreaInset` bars should use instead
- `backgroundExtensionEffect(isEnabled:)`
- `PrimitiveButtonStyle.glass(_:)`, documented as 26.0, and `GlassButtonStyle.init(_:)`, documented as 26.1. The two dates conflict, so it is safest to treat it as 26.1.
- `accessibilityReduceHighlightingEffects` (26.4, "Reduce Bright Effects")
- `accessibilityShowBorders`, which gets a dedicated setting on macOS 27

**What iOS 27 changes:**
- The SwiftUI updates pages for June and September 2026 list **no new Glass or glassEffect symbols**. The skill should not invent any.
- The 27 changes are automatic: a darkened edge, brighter specular highlights and the tint slider. Apple is "removing support for opting to use the old design" once an app is recompiled with Xcode 27.
- Xcode 27 adds `@ContentBuilder` (a typealias of ViewBuilder), which now appears in the `GlassEffectContainer` and `safeAreaBar` declarations.

**Correct as written:** `Glass` (regular / clear / identity / tint / interactive), the default capsule shape, the parameter labels of `glassEffectID` and `glassEffectUnion`, `.glass` and `.glassProminent`, `ButtonBorderShape` members, and the four accessibility environment values the skill uses.

## Findings (43)

### 0. `nonexistent-api` — Section 1 is titled `.glassEffect(_:in:isEnabled:)` and declares `func glassEffect() -> some View` plus `func glassEffect<S: Shape>(_ glass: Glass = .regular, in shape: S = DefaultGlassEffectShape, isEnabled: Bool = true)`; param table row (line 29) documents isEnabled; example line 51 `.glassEffect(.regular, in: .circle, isEnabled: highlighted)`.  
_references/01-api-reference.md:19_

- **Correct / new info:** Exactly one declaration exists, with no isEnabled parameter (the DocC path glasseffect(_:in:isenabled:) returns 404). `.glassEffect()` is the same method using defaults. Default shape is an instance `DefaultGlassEffectShape()` — 'The default shape applied by glass effects, a capsule.' Doc: 'SwiftUI uses the regular variant by default along with a Capsule shape.' Line 51 will not compile.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (no visionOS)
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Rename heading to `.glassEffect(_:in:)`, replace the signature block with the verbatim declaration, delete the separate `glassEffect()` overload and the isEnabled table row, and rewrite line 51 as `.glassEffect(highlighted ? .regular : .identity, in: .circle)`.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 1. `nonexistent-api` — Anti-pattern #5 'Right' block: `.glassEffect(.regular, isEnabled: visible)` (line 124 says 'use `isEnabled` or `.identity`').  
_references/07-anti-patterns.md:127_

- **Correct / new info:** glassEffect has no isEnabled parameter; the recommended 'correct' code does not compile. To toggle glass without changing the view tree use the identity variant (`Glass.identity`: 'your content remains unaffected as if no glass effect was applied'); to animate appearance/removal use GlassEffectContainer + glassEffectID + glassEffectTransition(.materialize).
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Replace with `.glassEffect(visible ? .regular : .identity)` and fix the line-124 prose to drop 'isEnabled'.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 2. `nonexistent-api` — Energy section: `.glassEffect(.regular, isEnabled: !isIdle)`; line 63 also says 'Hide the overlay during heavy moments (`isEnabled: false`)'.  
_references/06-performance.md:162_

- **Correct / new info:** No isEnabled parameter exists on glassEffect(_:in:); code does not compile.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Use `.glassEffect(isIdle ? .identity : .regular)` at line 162 and reword line 63 to 'switch to `.identity`'.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 3. `nonexistent-api` — 'Don't animate opacity on glass elements — use `.glassEffect(... isEnabled: false)` or swap to `.identity`'; line 166 'Animate glass opacity (animate `isEnabled` or swap variants)'.  
_references/02-hig-principles.md:133_

- **Correct / new info:** isEnabled is not a parameter of glassEffect(_:in:) or glassEffectTransition(_:). Only the `.identity` swap (or insertion/removal with glassEffectTransition) is valid.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Remove the isEnabled references at lines 133 and 166; keep only the `.identity` swap / `.glassEffectTransition(.materialize)` advice.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 4. `wrong-signature` — Section 6 '`.glassEffectTransition(_:isEnabled:)`' declares `func glassEffectTransition(_ transition: GlassEffectTransition, isEnabled: Bool = true)` and `enum GlassEffectTransition { case identity; case matchedGeometry; case materialize }`.  
_references/01-api-reference.md:231_

- **Correct / new info:** No isEnabled parameter (DocC path glasseffecttransition(_:isenabled:) is 404). GlassEffectTransition is `struct GlassEffectTransition` (Sendable) with type properties `static var identity`, `static var matchedGeometry`, `static var materialize` — not enum cases (cannot be switched over exhaustively). Abstracts: identity 'The identity transition specifying no changes.'; materialize 'will fade in content and animate in or out the glass material but will not attempt to match the geometry of any other glass effects.'
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/glasseffecttransition (apple-doc, confidence high)
- **Action:** Retitle to `.glassEffectTransition(_:)`, use the verbatim declaration, and rewrite the type as `struct GlassEffectTransition { static var identity/matchedGeometry/materialize: GlassEffectTransition }`.

```swift
@MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View
```

### 5. `nonexistent-api` — Section 12 lists `.rect(cornerRadius: .containerConcentric)` as a shape primitive (line 466) and recommends `.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))` (lines 473-475).  
_references/01-api-reference.md:475_

- **Correct / new info:** `Shape.rect(cornerRadius:style:)` takes `CGFloat` (`static func rect(cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) -> Self`); no symbol named `containerConcentric` exists in Shape, RoundedRectangle or anywhere in the docs. The real iOS 26 API is `ConcentricRectangle` / `Shape.rect(corners:isUniform:)` with `Edge.Corner.Style` (`.concentric`, `.concentric(minimum:)`, `.fixed(_:)`). Concentricity resolves against the nearest container shape — system views provide one; custom parents must call `.containerShape(_:)`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/concentricrectangle (apple-doc, confidence high)
- **Action:** Replace with `.glassEffect(.regular, in: .rect(corners: .concentric, isUniform: true))` (or `ConcentricRectangle(corners: .concentric(minimum: 12), isUniform: true)`), and document that the parent needs `.containerShape(RoundedRectangle(cornerRadius: 28))` for concentricity to resolve.

```swift
@export(implementation) static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self
```

### 6. `nonexistent-api` — Anti-pattern #6 'Right' block: `.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))` inside a VStack whose outer shape is only `.background(RoundedRectangle(cornerRadius: 28).fill(.background))`.  
_references/07-anti-patterns.md:154_

- **Correct / new info:** `.containerConcentric` does not exist (compile error). Even with the correct `.rect(corners: .concentric)`, a `.background(RoundedRectangle…)` does not establish a container shape; ConcentricRectangle docs: 'To allow ConcentricRectangle to resolve corner radii based on concentricity in your custom view, use containerShape(_:) to specify a container shape that implements RoundedRectangularShape'.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/containershape(_:) (apple-doc, confidence high)
- **Action:** Rewrite as `.glassEffect(.regular, in: .rect(corners: .concentric, isUniform: true))` and add `.containerShape(RoundedRectangle(cornerRadius: 28))` on the outer VStack (alongside the background).

```swift
nonisolated func containerShape(_ shape: some RoundedRectangularShape) -> some View
```

### 7. `nonexistent-api` — Concentricity section code `.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))`; also lines 20, 27, 154 tell users to use `.containerConcentric`.  
_references/02-hig-principles.md:82_

- **Correct / new info:** No `containerConcentric` symbol exists. Use `ConcentricRectangle` / `.rect(corners: .concentric, isUniform:)` with a parent `.containerShape(_:)`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/concentricrectangle (apple-doc, confidence high)
- **Action:** Replace all four mentions with `.rect(corners: .concentric)` / `ConcentricRectangle`, and add `.containerShape(RoundedRectangle(cornerRadius: 28))` to the outer-card snippet.

```swift
init(corners: Edge.Corner.Style, isUniform: Bool = false)
```

### 8. `nonexistent-api` — Corner-radii table: 'Card inside a sheet | `.containerConcentric` | `.rect(cornerRadius: .containerConcentric)`'; line 18 rule 'prefer `.containerConcentric`'; line 152 'Concentric corner trick | `.rect(cornerRadius: .containerConcentric)`'.  
_references/03-design-tokens.md:13_

- **Correct / new info:** Nonexistent spelling. Correct: `.rect(corners: .concentric, isUniform: true)` or `ConcentricRectangle(corners: .concentric(minimum: 12), isUniform: true)`; `Edge.Corner.Style` members are `static var concentric`, `static func concentric(minimum: Edge.Corner.Style?)`, `static func fixed(CGFloat)`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/edge/corner/style (apple-doc, confidence high)
- **Action:** Fix lines 13, 18 and 152 to the real API.

```swift
struct ConcentricRectangle
```

### 9. `nonexistent-api` — Golden rule 4: 'Use `.containerConcentric` corners for nested glass shapes'.  
_SKILL.md:87_

- **Correct / new info:** No such symbol. The concentric API is `ConcentricRectangle` / `Shape.rect(corners: .concentric, isUniform:)` resolving against the container shape set by system containers or `.containerShape(_:)`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/shape/rect(corners:isuniform:) (apple-doc, confidence high)
- **Action:** Reword rule 4: 'Use `ConcentricRectangle` / `.rect(corners: .concentric)` for nested shapes; give custom parents a `.containerShape(_:)`'.

```swift
@export(implementation) static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self
```

### 10. `nonexistent-api` — 'If the chip wraps to two lines, switch to `.rect(cornerRadius: .containerConcentric)`.'  
_patterns/glass-card-stack.md:92_

- **Correct / new info:** Nonexistent spelling; use `.rect(corners: .concentric(minimum: 8), isUniform: true)` or a fixed `.rect(cornerRadius: 12)`. The card in this pattern uses `.clipShape(RoundedRectangle(...))`, which does not set a container shape, so a concentric chip would need `.containerShape(RoundedRectangle(cornerRadius: 24, style: .continuous))` on the card.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/concentricrectangle (apple-doc, confidence high)
- **Action:** Replace with the real API and mention `.containerShape` on the card.

```swift
init(corners: Edge.Corner.Style, isUniform: Bool = false)
```

### 11. `nonexistent-api` — 'Inner glass shapes inside rounded containers use `.containerConcentric` radii'.  
_checklists/pre-ship-checklist.md:26_

- **Correct / new info:** No such symbol; concentric corners come from `ConcentricRectangle` / `.rect(corners: .concentric)` plus a container shape.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/concentricrectangle (apple-doc, confidence high)
- **Action:** Reword: 'Inner shapes use `ConcentricRectangle` / `.rect(corners: .concentric)` and custom parents declare `.containerShape(_:)`'.

```swift
struct ConcentricRectangle
```

### 12. `nonexistent-api` — 'Scroll extension' snippet: `ScrollView(.horizontal) { … }.scrollExtensionMode(.underSidebar)`.  
_references/01-api-reference.md:519_

- **Correct / new info:** No `scrollExtensionMode`, `extensionMode` or `underSidebar` symbol exists (DocC path view/scrollextensionmode(_:) is 404; absent from the Scroll views topic). Extending content under a sidebar/inspector is done with `backgroundExtensionEffect()` on the background content; scroll-edge treatment is configured with `scrollEdgeEffectStyle(_:for:)` / `scrollEdgeEffectHidden(_:for:)`.
- **Evidence:** https://developer.apple.com/documentation/swiftui/scroll-views (apple-doc, confidence high)
- **Action:** Delete the 'Scroll extension' subsection and replace it with the scroll edge effect APIs (scrollEdgeEffectStyle / scrollEdgeEffectHidden / safeAreaBar).

### 13. `platform-requirement` — Frontmatter `platforms: [..., visionOS 26+]` and description line 3 'visionOS 26' list visionOS as a Liquid Glass target.  
_SKILL.md:5_

- **Correct / new info:** Glass, View.glassEffect(_:in:), GlassEffectContainer, glassEffectID/Union/Transition, GlassButtonStyle, GlassProminentButtonStyle and PrimitiveButtonStyle.glass/glassProminent list ONLY iOS, iPadOS, Mac Catalyst, macOS, tvOS, watchOS (raw platforms array has no visionOS entry). visionOS uses its own `glassBackgroundEffect` family (e.g. `glassBackgroundEffect(_:displayMode:)`, visionOS 2.4+). Note: ConcentricRectangle, containerShape(_:), backgroundExtensionEffect(), safeAreaBar, ScrollEdgeEffectStyle ARE available on visionOS 26.0.
- **Availability:** Glass/glassEffect: iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (not visionOS)
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass (apple-doc, confidence high)
- **Action:** Remove visionOS from the frontmatter platforms and description (or state that glassEffect APIs are unavailable on visionOS and point to glassBackgroundEffect).

```swift
nonisolated func glassBackgroundEffect<S>(_ effect: S, displayMode: GlassBackgroundDisplayMode = .always) -> some View where S : GlassBackgroundEffect
```

### 14. `platform-requirement` — Minimum-requirements table: 'visionOS | 26.0+'.  
_references/01-api-reference.md:532_

- **Correct / new info:** The Liquid Glass SwiftUI API (Glass, glassEffect, GlassEffectContainer, glass button styles) is not available on visionOS per DocC platform lists.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Replace the visionOS row with 'not available (use glassBackgroundEffect)'; also add Mac Catalyst 26.0+.

```swift
struct Glass
```

### 15. `compile-risk` — `.sharedBackgroundVisibility(.hidden)` is applied to the `Button` inside `ToolbarItem { … }`.  
_references/01-api-reference.md:349_

- **Correct / new info:** It is a ToolbarContent modifier returning `some ToolbarContent`; it must be applied to the ToolbarItem, e.g. `ToolbarItem { … }.sharedBackgroundVisibility(.hidden)`. Applying it to a Button (a View) does not compile. Available iOS/iPadOS/Mac Catalyst/macOS only.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:) (apple-doc, confidence high)
- **Action:** Move `.sharedBackgroundVisibility(.hidden)` after the closing brace of `ToolbarItem`.

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
```

### 16. `nonexistent-api` — `@Environment(\.tabViewBottomAccessoryPlacement)` values: `// .expanded | .collapsed`.  
_references/01-api-reference.md:396_

- **Correct / new info:** `enum TabViewBottomAccessoryPlacement` has cases `expanded` ('The bar is expanded on top of the bottom tab bar…') and `inline` ('The view is displayed in line with the bottom tab bar.'). There is no `.collapsed`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement (apple-doc, confidence high)
- **Action:** Change the comment to `// .expanded | .inline`.

```swift
enum TabViewBottomAccessoryPlacement
```

### 17. `compile-risk` — `ToolbarItem(placement: .bottomBar) { DefaultToolbarItem(kind: .search, placement: .bottomBar) }`.  
_references/01-api-reference.md:422_

- **Correct / new info:** `DefaultToolbarItem` conforms to ToolbarContent (not View), so it cannot be the content of a ToolbarItem; place it directly in the toolbar builder.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem (apple-doc, confidence high)
- **Action:** Rewrite as `.toolbar { DefaultToolbarItem(kind: .search, placement: .bottomBar) }`.

```swift
nonisolated struct DefaultToolbarItem — init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement)
```

### 18. `compile-risk` — Same nesting: `ToolbarItem(placement: .bottomBar) { DefaultToolbarItem(kind: .search, placement: .bottomBar) }`.  
_patterns/glass-search-field.md:60_

- **Correct / new info:** DefaultToolbarItem is ToolbarContent, not a View; it goes directly inside `.toolbar { }`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem (apple-doc, confidence high)
- **Action:** Remove the wrapping ToolbarItem.

```swift
nonisolated struct DefaultToolbarItem
```

### 19. `wrong-availability` — `.controlSize(.extraLarge)  // new in iOS 26 — for floating CTAs` (also used at line 283).  
_references/01-api-reference.md:268_

- **Correct / new info:** `case extraLarge` was introduced in iOS 17.0 / macOS 14.0 / tvOS 17.0 / watchOS 10.0 / visionOS 1.0, not iOS 26. Its doc abstract says: 'A control version that is substantially sized. The largest control size. Resolves to `ControlSize.large` on platforms other than visionOS.'
- **Availability:** iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/controlsize/extralarge (apple-doc, confidence high)
- **Action:** Remove 'new in iOS 26' and note that, per Apple docs, it resolves to `.large` outside visionOS; use `.large` for iOS CTAs.

```swift
case extraLarge
```

### 20. `behavior-change` — 'Floating FAB recipe | `.buttonStyle(.glassProminent).buttonBorderShape(.circle).controlSize(.extraLarge)`'; line 40 gives distinct padding tokens for `.extraLarge` label buttons.  
_references/03-design-tokens.md:154_

- **Correct / new info:** Per Apple docs, ControlSize.extraLarge 'Resolves to ControlSize.large on platforms other than visionOS', so on iOS it is not a distinct size and the separate padding token is meaningless.
- **Availability:** iOS 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/controlsize/extralarge (apple-doc, confidence medium)
- **Action:** Use `.controlSize(.large)` in the FAB recipe and drop the `.extraLarge` padding row (or label it visionOS-only).

```swift
case extraLarge
```

### 21. `behavior-change` — Primary CTA uses `.controlSize(.extraLarge)` (also examples/08-LoginScreen.swift:367).  
_examples/03-OnboardingFlow.swift:75_

- **Correct / new info:** On iOS, extraLarge resolves to `.large` per Apple docs; the examples imply a larger size that iOS does not render.
- **Availability:** iOS 17.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/controlsize/extralarge (apple-doc, confidence medium)
- **Action:** Change to `.controlSize(.large)` in both examples (or comment that it resolves to .large on iOS).

```swift
case extraLarge
```

### 22. `factually-wrong` — 'Tinted Mode (iOS 26.1+): Users can globally reduce app glassiness via Settings → Accessibility → Display. The system applies the chosen opacity to all .glassEffect'; table line 17 'User-controlled opacity multiplier applied globally'; same claim at 01-api-reference.md:497 and patterns/glass-search-field.md:83.  
_references/05-accessibility.md:163_

- **Correct / new info:** iOS 26.1 added a Clear / Tinted choice under Settings > Display & Brightness > Liquid Glass (secondary sources). In the 27 releases Apple replaced it with a slider: 'a new slider in settings to adjust Liquid Glass anywhere from ultra clear to fully tinted' and 'Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint' (WWDC26 102/269). HIG: variant appearance 'can differ in response to certain system settings, like if people choose a preferred look for Liquid Glass in their device's settings'. No public API/EnvironmentValue to read this preference was found in SwiftUI docs.
- **Availability:** Setting: iOS 26.1 (Clear/Tinted toggle); slider in 27 releases
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/102/ (apple-video, confidence medium)
- **Action:** Rewrite as 'Liquid Glass look preference (Clear/Tinted in 26.1; clear-to-tinted slider in 27)': lives in Display & Brightness, not Accessibility, is not an opacity multiplier, has no API, and is honored automatically by system glass; test both extremes. Update 05:17, 01:497 and the search-field gotcha.

### 23. `bad-practice` — Golden rule 7: 'Respect accessibilityReduceTransparency — pass `.identity` to `glassEffect` to opt out' (code at 01-api-reference.md:490 and :574).  
_SKILL.md:90_

- **Correct / new info:** `Glass.identity`: 'When applied, your content remains unaffected as if no glass effect was applied' — i.e. it removes the backing entirely. Liquid Glass already adapts to Reduce Transparency ('Liquid Glass seamlessly adapts to a variety of accessibility settings users may choose, such as reducing transparency or increasing contrast' — WWDC26 Platforms State of the Union; HIG says variant appearance changes with these settings). Swapping to `.identity` removes the opaque fallback the system would draw, typically lowering legibility.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass/identity (apple-doc, confidence medium)
- **Action:** Change rule 7 to: keep `.regular` and let the system adapt under Reduce Transparency; use `accessibilityReduceTransparency` only to make custom backgrounds behind glass opaque. Reserve `.identity` for conditionally disabling glass for design reasons, and update the 01-api-reference.md 490/574 snippets.

```swift
static var identity: Glass { get }
```

### 24. `inconsistency` — 'Opting out of glass entirely: `view.glassEffect(reduceTransparency ? .identity : .regular)`', right after stating the system densifies glass automatically under Reduce Transparency (line 13).  
_references/05-accessibility.md:37_

- **Correct / new info:** `.identity` means no glass at all; under Reduce Transparency the system already replaces glass with a denser appearance, so the opt-out removes that accessible backing. The file contradicts its own line 13/20.
- **Availability:** iOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass/identity (apple-doc, confidence medium)
- **Action:** Remove this as a recommendation, or present it only for custom renderings with an explicit opaque replacement background.

```swift
static var identity: Glass { get }
```

### 25. `design-guidance` — Golden rule 5: 'Never use `.ultraThinMaterial` or other legacy `Material` values in iOS 26+'; scope line 12 'No legacy Material fallbacks'; repeated at 02-hig-principles.md:162 and checklists/pre-ship-checklist.md:9.  
_SKILL.md:88_

- **Correct / new info:** HIG Materials: 'Don't use Liquid Glass in the content layer… Instead, use standard materials for elements in the content layer, such as app backgrounds.' Standard materials remain the recommended choice for content-layer surfaces.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Reword to 'Don't use Material to imitate Liquid Glass on controls/chrome; standard materials remain correct for content-layer surfaces'. Adjust the checklist item and the HIG Don't list to match.

### 26. `design-guidance` — Variants table: '.clear | Over photos, video, vivid imagery | high | limited', with no legibility requirement.  
_references/01-api-reference.md:81_

- **Correct / new info:** Glass.clear doc: 'When using clear glass, ensure content remains legible by adding a dimming layer or other treatment beneath the glass' (example `.glassEffect(.clear).background(.black.opacity(0.3))`). HIG: 'Only use clear Liquid Glass for components that appear over visually rich backgrounds… If the underlying content is bright, consider adding a dark dimming layer of 35% opacity'; none needed over dark content or AVKit controls.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass/clear (apple-doc, confidence high)
- **Action:** Add the dimming-layer rule and Apple's snippet to the `.clear` row, and to 03-design-tokens 'Background materials'.

```swift
static var clear: Glass { get }
```

### 27. `factually-wrong` — 'Glass elements within `spacing` points of each other visually blend into a single fluid blob during transitions'; 04-motion-and-interaction.md:118 `GlassEffectContainer(spacing: 80) // distant siblings still attract during transitions`.  
_references/01-api-reference.md:122_

- **Correct / new info:** Apple: 'The larger the spacing value on the container, the sooner the Liquid Glass effects behind views blend together and merge the shapes during a transition. A spacing value on the container that's larger than the spacing of an interior HStack, VStack, or other layout container causes Liquid Glass effects to blend together at rest because the views are too close to each other.' Also: 'Creating too many Liquid Glass effect containers… can degrade performance.'
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence high)
- **Action:** Add the at-rest blending rule (container spacing should be ≤ the inner stack spacing unless merging is intended) to 01 §3, 03 spacing tokens and the 04 spacing example.

```swift
@MainActor @preconcurrency init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)
```

### 28. `wrong-signature` — `func glassEffectID<ID: Hashable>(_ id: ID, in namespace: Namespace.ID)` and (line 199) `func glassEffectUnion<ID: Hashable>(id: ID, namespace: Namespace.ID)`; union described as 'Forces two non-adjacent glass views to render as a single unified glass shape'.  
_references/01-api-reference.md:158_

- **Correct / new info:** Both IDs are `(some Hashable & Sendable)?`: Sendable is required (custom ID types must be Sendable), and Optional allows passing nil to conditionally drop the ID or union. Union semantics: 'All Liquid Glass effects with the same shape and Liquid Glass variant will be combined into a single shape' (article: 'similar shape, Liquid Glass effect, and ID'). Labels in the skill are correct.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffectunion(id:namespace:) (apple-doc, confidence high)
- **Action:** Paste the verbatim declarations, and note the Sendable requirement, the optional-ID trick and the same-shape/same-variant requirement for unions.

```swift
nonisolated func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View; @MainActor @preconcurrency func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View
```

### 29. `wrong-signature` — `func tint(_ color: Color) -> Glass` and `func interactive(_ isInteractive: Bool = true) -> Glass`.  
_references/01-api-reference.md:72_

- **Correct / new info:** `func tint(_ color: Color?) -> Glass` (optional, so nil clears the tint, e.g. `.regular.tint(isOn ? .blue : nil)`) and `func interactive(_ isEnabled: Bool = true) -> Glass`. Glass conforms to Equatable and Sendable. Its only members are regular, clear, identity, tint(_:) and interactive(_:); no new members in 27.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass (apple-doc, confidence high)
- **Action:** Update the Glass declaration block to the verbatim signatures and add the Equatable/Sendable conformances.

```swift
func tint(_ color: Color?) -> Glass; func interactive(_ isEnabled: Bool = true) -> Glass
```

### 30. `wrong-signature` — GlassEffectContainer has two inits: `init(@ViewBuilder content:)` and `init(spacing: CGFloat? = nil, @ViewBuilder content:)`.  
_references/01-api-reference.md:116_

- **Correct / new info:** Only one initializer is documented, with spacing defaulting to nil. The Xcode 27 docs spell the builder `@ContentBuilder` (`typealias ContentBuilder = ViewBuilder`, Xcode 27's unified builder), so `@ViewBuilder` remains source-compatible. The type is `@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/glasseffectcontainer/init(spacing:content:) (apple-doc, confidence high)
- **Action:** Show the single verbatim initializer.

```swift
@MainActor @preconcurrency init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)
```

### 31. `other` — Section 14 'Layout helpers introduced alongside' covers only backgroundExtensionEffect and the nonexistent scrollExtensionMode; scroll edge effects and safeAreaBar are never taught anywhere in the skill.  
_references/01-api-reference.md:503_

- **Correct / new info:** Real iOS 26 layout APIs that pair with Liquid Glass: `scrollEdgeEffectStyle(_:for:)` with `ScrollEdgeEffectStyle` (.automatic, .hard, .soft), `scrollEdgeEffectHidden(_:for:)`, and `safeAreaBar(edge:alignment:spacing:content:)`, which 'extends the edge effect of any scroll views affected by the inset safe area'. WWDC26: 'When content scrolls under floating bars, a uniform toolbar appears across the top… This effect is applied automatically for standard toolbars and can be customized using the existing scroll edge effect APIs.'
- **Availability:** scrollEdgeEffectStyle/Hidden: iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+; ScrollEdgeEffectStyle & safeAreaBar: also visionOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:) (apple-doc, confidence high)
- **Action:** Add a 'Scroll edge effects & custom bars' section with these verbatim declarations and the .hard/.soft guidance.

```swift
nonisolated func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View; nonisolated func scrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View; nonisolated func safeAreaBar(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content: () -> some View) -> some View
```

### 32. `design-guidance` — Pins a custom glass toolbar with `.safeAreaInset(edge: .bottom)`; examples/06-ChatScreen.swift:40 and examples/05-DashboardScreen.swift:69 do the same for custom bars.  
_patterns/glass-floating-toolbar.md:61_

- **Correct / new info:** iOS 26's `safeAreaBar(edge:alignment:spacing:content:)` behaves like safeAreaInset and also adjusts scroll edge effects: 'A new view that displays content beside the modified view… adjusting the safe area and scroll edge effects to match.' This is the intended API for custom bars over scrolling content.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:) (apple-doc, confidence medium)
- **Action:** Switch the pattern and the chat/dashboard examples to `.safeAreaBar(edge: .bottom) { … }`.

```swift
nonisolated func safeAreaBar(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content: () -> some View) -> some View
```

### 33. `design-guidance` — `Detail().backgroundExtensionEffect()   // extends content under the sidebar's glass` — applied to the whole detail view.  
_references/01-api-reference.md:512_

- **Correct / new info:** Doc: 'The view will be duplicated into mirrored copies which will be placed around the view on any edge with available safe area. Additionally, a blur effect will be applied… Apply this modifier with discretion. This should often be used with only a single instance of background content… Note: This modifier will clip the view.' Apple's example applies it to a BannerView inside the detail ZStack, not to the whole detail. There is also `backgroundExtensionEffect(isEnabled: Bool)`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/backgroundextensioneffect() (apple-doc, confidence high)
- **Action:** Apply it to the hero/background image only (`ZStack { HeroImage().backgroundExtensionEffect(); … }`), mention the clipping and use-once guidance, and add the isEnabled overload.

```swift
@MainActor @preconcurrency func backgroundExtensionEffect() -> some View; @MainActor @preconcurrency func backgroundExtensionEffect(isEnabled: Bool) -> some View
```

### 34. `new-api-ios26x` — The environment-values list stops at reduceTransparency, reduceMotion, differentiateWithoutColor and colorSchemeContrast (all four are correct).  
_references/05-accessibility.md:32_

- **Correct / new info:** New and relevant: `accessibilityReduceHighlightingEffects` ('Whether the system preference for Reduce Bright Effects is enabled… controls, such as buttons, should be drawn in such a way that minimizes highlighting and flashing'), iOS 26.4+, relevant to custom interactive/specular glass. `accessibilityShowBorders` ('Whether the system preference for Show Borders is enabled'): back-deployed (`@backDeployed(before: iOS 26.1, …)`), and macOS 27 adds a dedicated Show Borders setting (WWDC26: 'macOS 27 also supports the "show borders" environment value, just like iOS').
- **Availability:** accessibilityReduceHighlightingEffects: iOS 26.4+, iPadOS 26.4+, Mac Catalyst 26.4+, macOS 26.4+, tvOS 26.4+, visionOS 26.4+, watchOS 26.4+; accessibilityShowBorders: iOS 14.0+, macOS 11.0+, tvOS 14.0+, visionOS 1.0+, watchOS 7.0+ (back-deployed)
- **Evidence:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducehighlightingeffects (apple-doc, confidence high)
- **Action:** Add both values. When ShowBorders is true, add a visible stroke to custom glass controls; when ReduceHighlightingEffects is true, avoid custom shimmer/highlight animations.

```swift
var accessibilityReduceHighlightingEffects: Bool { get }; @backDeployed(before: iOS 26.1, macOS 26.1, tvOS 26.1, watchOS 26.1, visionOS 26.1) var accessibilityShowBorders: Bool { get }
```

### 35. `new-api-ios26x` — Button styles section documents only `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)`; examples (09:150-165, 07:59-68, 08:225-234) branch the whole button to swap styles.  
_references/01-api-reference.md:259_

- **Correct / new info:** `PrimitiveButtonStyle.glass(_:)` takes a Glass value, e.g. `.buttonStyle(.glass(.clear))`. Its doc says: 'applies a configurable Liquid Glass effect… you can customize by specifying a tint or variant'. The docs give conflicting dates: the static func page says 26.0, while the underlying `GlassButtonStyle.init(_ glass: Glass)` page says 26.1. Because the result is always GlassButtonStyle, a selected/unselected tint swap (`.glass(isSelected ? .regular.tint(.accentColor) : .regular)`) works without type-erasure branching.
- **Availability:** PrimitiveButtonStyle.glass(_:): iOS 26.0+ … watchOS 26.0+ per its page; GlassButtonStyle.init(_:): iOS 26.1+, iPadOS 26.1+, Mac Catalyst 26.1+, macOS 26.1+, tvOS 26.1+, watchOS 26.1+
- **Evidence:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glass(_:) (apple-doc, confidence medium)
- **Action:** Document `.buttonStyle(.glass(.clear))` / `.glass(.regular.tint(...))`, and tell readers to treat it as 26.1+ (`if #available(iOS 26.1, *)`) because the two doc pages disagree.

```swift
nonisolated static func glass(_ glass: Glass) -> Self (Available when Self is GlassButtonStyle); nonisolated init(_ glass: Glass)
```

### 36. `inconsistency` — Interactive glass is demonstrated as `Button("Tap me") { }.glassEffect(.regular.interactive())` (also line 142 LikeButton, and 07-anti-patterns.md:230 as the 'Right' example).  
_references/04-motion-and-interaction.md:23_

- **Correct / new info:** This contradicts 01-api-reference.md:254 ('don't roll your own with .glassEffect() on a Button'). Apple: 'Add interactive(_:) to custom components to make them react to touch and pointer interactions. This applies the same responsive and fluid reactions that PrimitiveButtonStyle.glass provides to standard buttons.' In other words, Buttons should use `.buttonStyle(.glass)`, and interactive() is meant for non-Button custom views.
- **Availability:** iOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence medium)
- **Action:** Use `.buttonStyle(.glass)` for Button examples, and show `.interactive()` on a custom non-Button view such as the draggable chip.

```swift
func interactive(_ isEnabled: Bool = true) -> Glass
```

### 37. `inconsistency` — Glass buttons carrying glassEffectID inside a GlassEffectContainer also get `.transition(.scale.combined(with: .opacity))` (lines 47 and 50; also 06-ChatScreen.swift:67/70 and 09-HealthTodayScreen.swift:346-355).  
_examples/04-PhotoDetailScreen.swift:47_

- **Correct / new info:** Apple drives glass insertion and removal through glassEffectTransition. Its default is matchedGeometry for effects within the container's spacing, and materialize is recommended for effects farther apart. Layering an opacity view transition on top contradicts the skill's own anti-pattern #5 ('Don't animate opacity on glass'). This is reasoning, not documented behavior.
- **Availability:** iOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (reasoning, confidence low)
- **Action:** Drop the opacity transitions, or replace them with `.glassEffectTransition(.matchedGeometry)` / `.materialize`, so the examples match the skill's own rules.

```swift
@MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View
```

### 38. `compile-risk` — Wrong-example code `.glassEffect(.regular.tint(.purple).opacity(0.9))`.  
_references/07-anti-patterns.md:93_

- **Correct / new info:** Glass has no `opacity` member. Its only members are regular, clear, identity, tint(_:) and interactive(_:), so even the 'wrong' example fails to compile and readers may copy the pattern. The compilable equivalent is `.regular.tint(.purple.opacity(0.9))`.
- **Availability:** iOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass (apple-doc, confidence high)
- **Action:** Change to `.glassEffect(.regular.tint(.purple.opacity(0.9)))`.

```swift
struct Glass
```

### 39. `compile-risk` — 'Primary CTA | tint the glass (`.glassProminent.tint(.blue)`)'.  
_references/03-design-tokens.md:64_

- **Correct / new info:** `PrimitiveButtonStyle.glassProminent` is a `static var glassProminent: GlassProminentButtonStyle`, which has no tint method. Tint is applied with the View modifier after `.buttonStyle(.glassProminent)`, as the skill itself does at line 153.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent (apple-doc, confidence high)
- **Action:** Write `.buttonStyle(.glassProminent).tint(.blue)`.

```swift
@MainActor @export(implementation) @preconcurrency static var glassProminent: GlassProminentButtonStyle { get }
```

### 40. `behavior-change` — The skill presents iOS 26 / Xcode 26 / WWDC25 as current and says nothing about the 27 releases.  
_SKILL.md:10_

- **Correct / new info:** SwiftUI 'Updates' for June 2026 and September 2026 list NO new Glass / glassEffect / GlassEffectContainer / button-style / ConcentricRectangle symbols. The 27 changes are automatic visual refinements: 'we tuned Liquid Glass so it more effectively diffuses complex content behind it… introduced a darkened edge along with brighter specular highlights… a new slider in settings to adjust Liquid Glass anywhere from ultra clear to fully tinted' and 'Apps already using Liquid Glass get these improvements automatically… We'll be removing support for opting to use the old design. So once your app is recompiled with Xcode 27, it will automatically begin to use the new design with Liquid Glass.' The 27 SwiftUI docs also show `@ContentBuilder`, a typealias of ViewBuilder.
- **Availability:** Xcode 27 (ContentBuilder documented iOS 13.0+ as a typealias)
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/102/ (apple-video, confidence high)
- **Action:** Add an 'iOS 27 / Xcode 27' note covering: no new glass API, the automatic refresh, removal of the old-design opt-out, and the tint slider. Do not invent new glass symbols.

```swift
typealias ContentBuilder = ViewBuilder
```

### 41. `factually-wrong` — `.glassEffectTransition(.matchedGeometry)  // default with glassEffectID`.  
_references/04-motion-and-interaction.md:103_

- **Correct / new info:** Apple: 'For effects you want to add or remove that are positioned within the container's assigned spacing, the default transition type is matchedGeometry. Use the materialize transition for effects you want to add or remove that are farther from each other than the container's assigned spacing.'
- **Availability:** iOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence medium)
- **Action:** Qualify the comment as 'default within container spacing' and recommend `.materialize` for distant effects.

```swift
static var matchedGeometry: GlassEffectTransition
```

### 42. `unverifiable-claim` — Quantified cost claims: 'GlassEffectContainer of N children ≈ cost of one glass effect' (line 21), '1 container of 5 children is ~5× cheaper' (line 25), Instruments phases named 'GlassEffect: layout' / 'GlassEffect: composite' (line 148), and checklists/pre-ship-checklist.md:62 'Metal System Trace shows one composite phase per GlassEffectContainer'.  
_references/06-performance.md:25_

- **Correct / new info:** Apple only states that a container gives 'the best rendering performance' and that 'Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance. Limit the use of Liquid Glass effects onscreen at the same time.' No Apple source was found for the numeric ratios or the Instruments phase names.
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence low)
- **Action:** Replace the invented numbers and phase names with Apple's qualitative guidance, and add the 'too many containers' caveat.

## Symbols (40)

### `View.glassEffect(_:in:)`

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (no visionOS)
- **Members:** glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Skill uses it correctly:** NO
- **Notes:** Only one overload; no isEnabled (glasseffect(_:in:isenabled:) is 404). The skill invents isEnabled in 01, 02, 06 and 07 and lists a separate glassEffect() overload. Default shape is a capsule. No changes in 27.

### `Glass`

```swift
struct Glass
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** static var regular: Glass, static var clear: Glass, static var identity: Glass, func tint(Color?) -> Glass, func interactive(Bool) -> Glass; conforms to Equatable, Sendable
- **Doc:** https://developer.apple.com/documentation/swiftui/glass
- **Skill uses it correctly:** yes
- **Notes:** Variants are used correctly. No opacity member (07:93 uses one). No new members in 26.x or 27. clear docs require a dimming layer for legibility.

### `Glass.tint(_:)`

```swift
func tint(_ color: Color?) -> Glass
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** color: Color?
- **Doc:** https://developer.apple.com/documentation/swiftui/glass/tint(_:)
- **Skill uses it correctly:** yes
- **Notes:** The skill declares the parameter as non-optional Color. Call sites are fine. nil clears the tint.

### `Glass.interactive(_:)`

```swift
func interactive(_ isEnabled: Bool = true) -> Glass
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** isEnabled: Bool = true
- **Doc:** https://developer.apple.com/documentation/swiftui/glass/interactive(_:)
- **Skill uses it correctly:** yes
- **Notes:** The skill names the parameter isInteractive (cosmetic). Apple intends it for custom components; Buttons should use .buttonStyle(.glass). WWDC26: interactive glass is also optimized for macOS pointer clicks.

### `DefaultGlassEffectShape`

```swift
struct DefaultGlassEffectShape
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** init()
- **Doc:** https://developer.apple.com/documentation/swiftui/defaultglasseffectshape
- **Skill uses it correctly:** yes
- **Notes:** 'The default shape applied by glass effects, a capsule.' The skill's capsule-default claim is correct; its signature writes the type instead of the instance DefaultGlassEffectShape().

### `GlassEffectContainer`

```swift
@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** @MainActor @preconcurrency init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)
- **Doc:** https://developer.apple.com/documentation/swiftui/glasseffectcontainer/init(spacing:content:)
- **Skill uses it correctly:** yes
- **Notes:** Usage compiles, but the skill lists two inits when there is one. Its spacing semantics miss Apple's rule that container spacing larger than the inner stack spacing makes shapes blend at rest. Apple also warns that too many containers degrade performance.

### `View.glassEffectID(_:in:)`

```swift
nonisolated func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** id: (some Hashable & Sendable)?, in namespace: Namespace.ID
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffectid(_:in:)
- **Skill uses it correctly:** yes
- **Notes:** Call sites are correct (String IDs). The skill's generic signature omits Sendable and Optional.

### `View.glassEffectUnion(id:namespace:)`

```swift
@MainActor @preconcurrency func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** id: (some Hashable & Sendable)?, namespace: Namespace.ID
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffectunion(id:namespace:)
- **Skill uses it correctly:** yes
- **Notes:** Labels are correct. Docs: effects 'with the same shape and Liquid Glass variant will be combined'. The skill omits this requirement.

### `View.glassEffectTransition(_:)`

```swift
@MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** transition: GlassEffectTransition
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffecttransition(_:)
- **Skill uses it correctly:** NO
- **Notes:** No isEnabled parameter (the isEnabled path is 404). The skill's signature at 01:231 is wrong; its call sites (.materialize etc.) compile.

### `GlassEffectTransition`

```swift
struct GlassEffectTransition
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** static var identity: GlassEffectTransition, static var matchedGeometry: GlassEffectTransition, static var materialize: GlassEffectTransition
- **Doc:** https://developer.apple.com/documentation/swiftui/glasseffecttransition
- **Skill uses it correctly:** NO
- **Notes:** The skill declares it as an enum with cases; it is a struct. matchedGeometry is the default within container spacing; materialize is for distant effects.

### `PrimitiveButtonStyle.glass`

```swift
@export(implementation) nonisolated static var glass: GlassButtonStyle { get }
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** Available when Self is GlassButtonStyle
- **Doc:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glass
- **Skill uses it correctly:** yes
- **Notes:** Used correctly. tvOS: applies glass regardless of focus.

### `PrimitiveButtonStyle.glassProminent`

```swift
@MainActor @export(implementation) @preconcurrency static var glassProminent: GlassProminentButtonStyle { get }
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** Available when Self is GlassProminentButtonStyle
- **Doc:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent
- **Skill uses it correctly:** yes
- **Notes:** Used correctly except at 03-design-tokens:64, where `.glassProminent.tint(.blue)` is an invalid expression.

### `PrimitiveButtonStyle.glass(_:)`

```swift
nonisolated static func glass(_ glass: Glass) -> Self
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (per its page; GlassButtonStyle.init(_:) says 26.1)
- **Members:** glass: Glass; Available when Self is GlassButtonStyle
- **Doc:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glass(_:)
- **Skill uses it correctly:** NO
- **Notes:** Not taught by the skill. Example: `.buttonStyle(.glass(.clear))`. Treat as 26.1+ to be safe because the two doc pages disagree.

### `GlassButtonStyle`

```swift
nonisolated struct GlassButtonStyle
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** init(), nonisolated init(_ glass: Glass) [iOS/iPadOS/Mac Catalyst/macOS/tvOS/watchOS 26.1+], func makeBody(configuration: GlassButtonStyle.PrimitiveButtonStyleConfiguration) -> some View
- **Doc:** https://developer.apple.com/documentation/swiftui/glassbuttonstyle
- **Skill uses it correctly:** yes
- **Notes:** The configurable init(_:) is new in 26.1 and missing from the skill.

### `GlassProminentButtonStyle`

```swift
nonisolated struct GlassProminentButtonStyle
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** init(), func makeBody(configuration: GlassProminentButtonStyle.Configuration) -> some View
- **Doc:** https://developer.apple.com/documentation/swiftui/glassprominentbuttonstyle
- **Skill uses it correctly:** yes
- **Notes:** Has no Glass-taking init. No new styles in 27.

### `ControlSize.extraLarge`

```swift
case extraLarge
```

- **Availability:** iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+
- **Members:** ControlSize: mini, small, regular, large, extraLarge
- **Doc:** https://developer.apple.com/documentation/swiftui/controlsize/extralarge
- **Skill uses it correctly:** NO
- **Notes:** The skill says it is new in iOS 26. Apple's abstract: 'Resolves to ControlSize.large on platforms other than visionOS.' Used in 01, 03-design-tokens and examples 03 and 08.

### `ButtonBorderShape`

```swift
struct ButtonBorderShape
```

- **Availability:** iOS 15.0+, iPadOS 15.0+, Mac Catalyst 15.0+, macOS 12.0+, tvOS 15.0+, visionOS 1.0+, watchOS 8.0+ (circle: iOS 17.0+, macOS 14.0+, tvOS 16.4+, watchOS 10.0+)
- **Members:** static let automatic, static let capsule, static let circle, static let roundedRectangle, static func roundedRectangle(radius: CGFloat) -> ButtonBorderShape
- **Doc:** https://developer.apple.com/documentation/swiftui/buttonbordershape
- **Skill uses it correctly:** yes
- **Notes:** `.capsule`, `.circle` and `.roundedRectangle(radius:)` are used correctly. The system default is `.automatic`; the skill calls `.capsule` the default, which Apple does not document.

### `ConcentricRectangle`

```swift
struct ConcentricRectangle
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** init(), init(corners: Edge.Corner.Style, isUniform: Bool = false), init(topLeadingCorner:topTrailingCorner:bottomLeadingCorner:bottomTrailingCorner:), init(uniformTopCorners:uniformBottomCorners:), init(uniformTopCorners:bottomLeadingCorner:bottomTrailingCorner:), init(uniformBottomCorners:topLeadingCorner:topTrailingCorner:), init(uniformLeadingCorners:uniformTrailingCorners:), init(uniformLeadingCorners:topTrailingCorner:bottomTrailingCorner:), init(uniformTrailingCorners:topLeadingCorner:bottomLeadingCorner:)
- **Doc:** https://developer.apple.com/documentation/swiftui/concentricrectangle
- **Skill uses it correctly:** NO
- **Notes:** Never used by the skill, which uses the nonexistent `.containerConcentric` instead. Needs a container shape (from system views or containerShape(_:)).

### `Shape.rect(corners:isUniform:)`

```swift
@export(implementation) static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** corners: Edge.Corner.Style, isUniform: Bool = false (plus rect(topLeadingCorner:…), rect(uniformTopCorners:…) etc.)
- **Doc:** https://developer.apple.com/documentation/swiftui/shape/rect(corners:isuniform:)
- **Skill uses it correctly:** NO
- **Notes:** This is the correct spelling for `.glassEffect(.regular, in: .rect(corners: .concentric, isUniform: true))`.

### `Edge.Corner.Style`

```swift
struct Style
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** static var concentric: Edge.Corner.Style, static func concentric(minimum: Edge.Corner.Style?) -> Edge.Corner.Style, static func fixed(CGFloat) -> Edge.Corner.Style; ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral
- **Doc:** https://developer.apple.com/documentation/swiftui/edge/corner/style
- **Skill uses it correctly:** NO
- **Notes:** Not used by the skill.

### `.rect(cornerRadius: .containerConcentric)`

```swift
NOT FOUND
```

- **Availability:** 
- **Members:** Shape.rect(cornerRadius:) is `static func rect(cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) -> Self` (iOS 13.0+); no `containerConcentric` anywhere
- **Doc:** https://developer.apple.com/documentation/swiftui/shape/rect(cornerradius:style:)
- **Skill uses it correctly:** NO
- **Notes:** Used in about 12 places (SKILL.md, 01, 02, 03, 07, card-stack pattern, checklist). Does not compile.

### `View.containerShape(_:)`

```swift
nonisolated func containerShape(_ shape: some RoundedRectangularShape) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** overload: nonisolated func containerShape<T>(_ shape: T) -> some View where T : InsettableShape
- **Doc:** https://developer.apple.com/documentation/swiftui/view/containershape(_:)
- **Skill uses it correctly:** NO
- **Notes:** Not used by the skill. Required for ConcentricRectangle to resolve against a custom parent.

### `View.backgroundExtensionEffect()`

```swift
@MainActor @preconcurrency func backgroundExtensionEffect() -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** overload: @MainActor @preconcurrency func backgroundExtensionEffect(isEnabled: Bool) -> some View
- **Doc:** https://developer.apple.com/documentation/swiftui/view/backgroundextensioneffect()
- **Skill uses it correctly:** NO
- **Notes:** Exists. The skill applies it to the whole Detail view; Apple applies it to a single background banner/image and notes that it clips the view. The isEnabled overload is missing from the skill.

### `View.scrollEdgeEffectStyle(_:for:)`

```swift
nonisolated func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** style: ScrollEdgeEffectStyle?, for edges: Edge.Set
- **Doc:** https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** Not taught. WWDC26: the 27 uniform top-toolbar scroll effect 'can be customized using the existing scroll edge effect APIs'.

### `ScrollEdgeEffectStyle`

```swift
struct ScrollEdgeEffectStyle
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** static var automatic: ScrollEdgeEffectStyle, static var hard: ScrollEdgeEffectStyle, static var soft: ScrollEdgeEffectStyle
- **Doc:** https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle
- **Skill uses it correctly:** NO
- **Notes:** Not taught. Conforms to Equatable, Hashable, Sendable.

### `View.scrollEdgeEffectHidden(_:for:)`

```swift
nonisolated func scrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** hidden: Bool = true, for edges: Edge.Set = .all
- **Doc:** https://developer.apple.com/documentation/swiftui/view/scrolledgeeffecthidden(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** Exists; not taught.

### `View.scrollExtensionMode(_:)`

```swift
NOT FOUND
```

- **Availability:** 
- **Members:** No scrollExtensionMode / underSidebar symbol in the Scroll views topic; DocC path is 404
- **Doc:** https://developer.apple.com/documentation/swiftui/scroll-views
- **Skill uses it correctly:** NO
- **Notes:** Invented at 01-api-reference.md:519.

### `View.safeAreaBar(edge:alignment:spacing:content:)`

```swift
nonisolated func safeAreaBar(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content: () -> some View) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** overload: nonisolated func safeAreaBar(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content: () -> some View) -> some View
- **Doc:** https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:)
- **Skill uses it correctly:** NO
- **Notes:** Not taught. The skill uses safeAreaInset for custom glass bars; safeAreaBar also extends scroll edge effects.

### `EnvironmentValues.accessibilityReduceTransparency`

```swift
var accessibilityReduceTransparency: Bool { get }
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducetransparency
- **Skill uses it correctly:** NO
- **Notes:** Reading the value is correct, but the recommended `.identity` swap is questionable: system glass already adapts to Reduce Transparency.

### `EnvironmentValues.accessibilityReduceMotion`

```swift
var accessibilityReduceMotion: Bool { get }
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- **Skill uses it correctly:** yes
- **Notes:** Used correctly.

### `EnvironmentValues.accessibilityDifferentiateWithoutColor`

```swift
var accessibilityDifferentiateWithoutColor: Bool { get }
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilitydifferentiatewithoutcolor
- **Skill uses it correctly:** yes
- **Notes:** Used correctly.

### `EnvironmentValues.colorSchemeContrast / ColorSchemeContrast`

```swift
var colorSchemeContrast: ColorSchemeContrast; enum ColorSchemeContrast
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- **Members:** case standard, case increased
- **Doc:** https://developer.apple.com/documentation/swiftui/colorschemecontrast
- **Skill uses it correctly:** yes
- **Notes:** The skill's comment `.standard | .increased` is correct.

### `EnvironmentValues.accessibilityReduceHighlightingEffects`

```swift
var accessibilityReduceHighlightingEffects: Bool { get }
```

- **Availability:** iOS 26.4+, iPadOS 26.4+, Mac Catalyst 26.4+, macOS 26.4+, tvOS 26.4+, visionOS 26.4+, watchOS 26.4+
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducehighlightingeffects
- **Skill uses it correctly:** NO
- **Notes:** New in 26.4 ('Reduce Bright Effects'); not in the skill. Relevant to custom highlight/shimmer on glass.

### `EnvironmentValues.accessibilityShowBorders`

```swift
@backDeployed(before: iOS 26.1, macOS 26.1, tvOS 26.1, watchOS 26.1, visionOS 26.1) var accessibilityShowBorders: Bool { get }
```

- **Availability:** iOS 14.0+, iPadOS 14.0+, Mac Catalyst 14.0+, macOS 11.0+, tvOS 14.0+, visionOS 1.0+, watchOS 7.0+ (back-deployed)
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityshowborders
- **Skill uses it correctly:** NO
- **Notes:** Not in the skill. macOS 27 adds a dedicated Show Borders setting (WWDC26). Use it to stroke custom glass controls.

### `Liquid Glass appearance preference (Clear/Tinted, 27 slider)`

```swift
NOT FOUND
```

- **Availability:** User setting: iOS 26.1 Clear/Tinted (secondary sources); slider 'ultra clear to fully tinted' in the 27 releases (WWDC26)
- **Doc:** https://developer.apple.com/videos/play/wwdc2026/102/
- **Skill uses it correctly:** NO
- **Notes:** No public EnvironmentValue or API found. The skill wrongly calls it an 'opacity multiplier' under Accessibility → Display.

### `View.glassBackgroundEffect(_:displayMode:) (visionOS)`

```swift
nonisolated func glassBackgroundEffect<S>(_ effect: S, displayMode: GlassBackgroundDisplayMode = .always) -> some View where S : GlassBackgroundEffect
```

- **Availability:** visionOS 2.4+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glassbackgroundeffect(_:displaymode:)
- **Skill uses it correctly:** NO
- **Notes:** This is the visionOS glass API. The skill's visionOS 26 claim for glassEffect is wrong.

### `ToolbarContent.sharedBackgroundVisibility(_:)`

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+
- **Members:** visibility: Visibility
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:)
- **Skill uses it correctly:** NO
- **Notes:** The skill applies it to a Button (a View) instead of the ToolbarItem, which is a compile error.

### `TabViewBottomAccessoryPlacement`

```swift
enum TabViewBottomAccessoryPlacement
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** case expanded, case inline
- **Doc:** https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement
- **Skill uses it correctly:** NO
- **Notes:** The skill lists a nonexistent `.collapsed` case. Comparisons against `.expanded` are fine.

### `DefaultToolbarItem`

```swift
nonisolated struct DefaultToolbarItem
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement); conforms to ToolbarContent
- **Doc:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem
- **Skill uses it correctly:** NO
- **Notes:** The skill nests it inside ToolbarItem { } (in 01 and the search-field pattern). It must go directly in the toolbar builder.

### `ContentBuilder`

```swift
typealias ContentBuilder = ViewBuilder
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+ (introduced with Xcode 27 per the SwiftUI June 2026 updates)
- **Doc:** https://developer.apple.com/documentation/swiftui/contentbuilder
- **Skill uses it correctly:** yes
- **Notes:** Xcode 27's unified builder; it now appears in the GlassEffectContainer and safeAreaBar declarations. The skill's @ViewBuilder remains valid.

