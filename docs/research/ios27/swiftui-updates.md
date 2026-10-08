# swiftui-updates

_Phase: Research_

## Summary

I read Apple's SwiftUI Updates page (documentation/updates/swiftui.json) in full for its September 2026 and June 2026 sections. It has no point-release sections: no December 2025 or March 2026 headings, and the next section is June 2025. I then fetched about 100 symbol pages as DocC JSON, plus the iOS 26.1, 26.2, 26.4 and 27 release notes, the WWDC26 "What's new in SwiftUI" session (269), and the HIG pages for Materials, Toolbars, Tab bars and "Designing for iPhone Duo". The skill folder was only read; nothing in the repo was changed.

KEY RESULTS
1) Release structure. "June 2026" is iOS 27.0. Its General section covers the @State macro, ContentBuilder, reorderable/reorderContainer, swipeActions on any container and swipeActionsContainer. The other sections are Transitions (NavigationTransition.crossFade for sheets), Images, Toolbars (visibilityPriority, ToolbarOverflowMenu, .topBarPinnedTrailing, toolbarMinimizationBehavior(_:for:)), Documents, Tab bars (TabRole.prominent), Alerts/confirmation dialogs (item- and error-driven) and Gestures. "September 2026" is iOS/iPadOS 27.1 and every symbol in it is still marked BETA. It covers Arrangement views, Reserved regions, Hinge, Scene accessories (CameraCaptureAccessory) and "Controls on the vertical axis" (toolbarVerticalEdge, toolbarVerticalBehavior, axisBehavior, toolbarVerticalCompressionBehavior). All of these serve the new iPhone Duo, which has its own new HIG page.
2) Shipping 27.0 APIs that the Updates page leaves out but symbol pages or release notes confirm:
   - ToolbarContent.contentMarginsRemoved(_:)
   - View.toolbarOverflowMenu(content:)
   - toolbarMinimizationRestoration(_:for:) and ToolbarMinimizationRestoration
   - toolbarMinimizationSafeAreaAdjustment(_:for:) and ToolbarMinimizationSafeAreaAdjustment
   - presentationPlacement(_:) and PresentationPlacement
   - ToolbarPlacement.statusBar
   - TabsPickerStyle / .tabs
   - textInputBorderShape(_:), TextInputBorderShape and TextFieldStyle.bordered (.roundedBorder and .squareBorder have deprecatedAt 27.2)
   - GeometryProxy.concentricCornerRadii and concentricCornerRadii(in:)
   - View.sceneAccessory(content:) and ExternalNonInteractiveAccessory
3) Rename. WWDC26 session 269 shows `.toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)`. The shipping docs have only toolbarMinimizationBehavior(_:for:), and the old path returns 404. The iOS 27 release notes say: "This modifier replaces toolbarMinimizeBehavior."
4) Existing glass symbols. Glass, glassEffect(_:in:), GlassEffectContainer, glassEffectID, glassEffectUnion, glassEffectTransition, GlassEffectTransition, GlassProminentButtonStyle and DefaultGlassEffectShape gained no new members in 26.x or 27; all are still 26.0. The only glass addition is GlassButtonStyle.init(_ glass: Glass), introduced in 26.1. PrimitiveButtonStyle.glass(_:) is documented as 26.0. None of the Glass APIs list visionOS. Every declaration printed as @ContentBuilder is a typealias of ViewBuilder, so existing @ViewBuilder code still compiles.
5) 26.x point releases. Symbol-level 26.1 additions are GlassButtonStyle.init(_:), tabViewBottomAccessory(isEnabled:content:) (iOS/iPadOS/Catalyst only), and visibilityPriority / ToolbarItemVisibilityPriority on macOS 26.1. The 26.1 notes say @Animatable now back-deploys to iOS 13, fix "Buttons that do not specify an explicit label display text instead of a symbol in toolbars", and list a known issue: "@FocusState doesn't work in safeAreaBar". The 26.2 notes have no SwiftUI items. The 26.4 notes have no chrome-related SwiftUI items.
6) Behavior changes when building with the 27 SDK:
   - The refreshed Liquid Glass look applies automatically. iOS 27 adds a user Liquid Glass tint slider, iPad dims inactive windows, and interactive() glass now works with the macOS pointer (all three from WWDC26 269).
   - Navigation bars auto-minimize when searchable uses .toolbarPrincipal (ToolbarMinimizationBehavior.automatic).
   - controlSize, buttonSizing, buttonRepeatBehavior, menuIndicatorVisibility and ButtonBorderShape environment values are reset inside sheets and popovers.
   - TabView may crash if its selection points to a hidden tab.
   - Menu-bar item symbol images are hidden by default on iPadOS/macOS 27.
   - @State is now a macro. It initializes its default value once, back-deploys to iOS 17-aligned OSes, and has a few source-compatibility breaks.
7) Existing-skill errors confirmed against the docs while checking the glass and chrome symbols:
   - glassEffect has no isEnabled parameter (the path returns 404).
   - glassEffectTransition has no isEnabled parameter.
   - GlassEffectTransition is a struct, not an enum.
   - `.containerConcentric` does not exist; the real APIs are ConcentricRectangle and Edge.Corner.Style.concentric.
   - `.scrollExtensionMode` does not exist (404).
   - sharedBackgroundVisibility is a ToolbarContent modifier only; a View variant returns 404.
   - DefaultToolbarItem is ToolbarContent and cannot sit inside ToolbarItem, whose Content must be a View.
   - TabViewBottomAccessoryPlacement cases are .expanded and .inline (not .collapsed), and the environment value is Optional.
   - TabBarMinimizeBehavior also has .onScrollUp, and minimizing is iPhone-only.
   - The HIG Materials page tells you to use standard materials in the content layer, which contradicts the skill's "never use Material" rule.
8) Not found in the docs: any SwiftUI API that reads the user's Liquid Glass tint/clear preference, and any new Glass variants or tint APIs in 27.
9) Skipped as unrelated, mentioned only here:
   - Documents: ReadableDocument, WritableDocument, Document, DocumentReader/Writer, FileWrapperDocumentReader/Writer, URLDocumentConfiguration, fileExporter overloads; FileDocument is deprecated.
   - Gestures: GestureInputKinds initializers on DragGesture, LongPressGesture, MagnifyGesture, RotateGesture, RotateGesture3D, SpatialEventGesture, SpatialTapGesture, TapGesture, WindowDragGesture.
   - Images: AsyncImage caching (asyncImageURLSession(_:), init(request:scale:...)).
   - Text: selectable Text gets the system selection UI and supports TextRenderer.
   - LabeledContent inside Menu maps to the menu item subtitle; @Entry gains new warnings.
   Secondary sources (exploreswiftui.com, blakecrosley.com, appcircle, techtimes) were used only as leads; two of them did not resolve.

## Findings (46)

### 0. `new-api-ios27` — Toolbar integration section (iOS 26) has no API to minimize the navigation bar on scroll; only tabBarMinimizeBehavior is taught.  
_references/01-api-reference.md:298_

- **Correct / new info:** iOS 27 adds View.toolbarMinimizationBehavior(_:for:) with ToolbarMinimizationBehavior members .automatic, .never, .onScrollDown, .onScrollUp. Docs: 'Use this modifier to enable toolbar minimization in response to scrolling. The supported placement is navigationBar. When the navigation bar minimizes, an integrated top tab bar will also minimize.' The WWDC26 session 269 code uses `.toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)`, but that symbol is not in the shipping docs (404). The iOS 27 release notes (177954148) say: 'You can use toolbarMinimizationBehavior to control bar minimization behavior. This modifier replaces toolbarMinimizeBehavior.'
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:) (apple-doc, confidence high)
- **Action:** Add an 'iOS 27: minimizing the navigation bar' subsection: `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)` on the scroll content inside a NavigationStack, gated with `if #available(iOS 27, *)` when the deployment target is 26. Explicitly warn that the WWDC26 spelling `toolbarMinimizeBehavior` does not compile. Pair it with tabBarMinimizeBehavior in the decision tree.

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

### 1. `new-api-ios27` — Skill has no control over when a minimized bar restores.  
_references/01-api-reference.md:298_

- **Correct / new info:** View.toolbarMinimizationRestoration(_:for:) with ToolbarMinimizationRestoration members .atScrollEdge and .automatic. 'By default, the bar restores when the user reverses scroll direction. Use atScrollEdge to restrict restoration to when the scroll view's content reaches the scroll edge... Currently, only navigationBar supports customizing the restoration behavior, and only when used in combination with onScrollDown.'
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationrestoration(_:for:) (apple-doc, confidence high)
- **Action:** Document this next to toolbarMinimizationBehavior, noting the constraint (navigationBar + .onScrollDown only). Use case: screens whose bar is mostly chrome.

```swift
nonisolated func toolbarMinimizationRestoration(_ restoration: ToolbarMinimizationRestoration, for bars: ToolbarPlacement...) -> some View
```

### 2. `new-api-ios27` — Full-bleed media examples have no way to stop content reflowing when the nav bar minimizes.  
_examples/04-PhotoDetailScreen.swift_

- **Correct / new info:** View.toolbarMinimizationSafeAreaAdjustment(_:for:) with ToolbarMinimizationSafeAreaAdjustment members .automatic, .disabled ('The safe area remains unchanged as bars minimize.') and .enabled ('The safe area adjusts interactively as bars minimize.'). 'Use this modifier to disable that adjustment when content should remain in place – for example, when displaying full-bleed media beneath a minimizing bar. Currently, only navigationBar supports customizing the safe area adjustment.'
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationsafeareaadjustment(_:for:) (apple-doc, confidence high)
- **Action:** In the API reference and the photo/music examples, show `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar).toolbarMinimizationSafeAreaAdjustment(.disabled, for: .navigationBar)` for media under glass chrome.

```swift
nonisolated func toolbarMinimizationSafeAreaAdjustment(_ adjustment: ToolbarMinimizationSafeAreaAdjustment, for bars: ToolbarPlacement...) -> some View
```

### 3. `new-api-ios27` — Skill only teaches ToolbarSpacer/ToolbarItemGroup for arranging glass toolbar items and gives no way to control which items survive when space shrinks.  
_references/01-api-reference.md:317_

- **Correct / new info:** ToolbarContent.visibilityPriority(_:) with ToolbarItemVisibilityPriority (.automatic, .low, .high, init(lowerThan:), init(higherThan:)). 'When toolbar space is limited, items with a lower priority move into the overflow menu before items with a higher priority. The default is automatic.' WWDC26 sample: `ToolbarItemGroup { UndoButton(); RedoButton() }.visibilityPriority(.high)`.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 26.1, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:) (apple-doc, confidence high)
- **Action:** Add a 'Controlling item visibility (iOS 27)' subsection. Apply it to ToolbarItem/ToolbarItemGroup, not to the inner Button, because it is a ToolbarContent modifier. Teach .high for key actions such as Undo/Redo/Compose and badged items (per the HIG iPhone Duo page).

```swift
@MainActor @preconcurrency func visibilityPriority(_ priority: ToolbarItemVisibilityPriority) -> some ToolbarContent
```

### 4. `new-api-ios27` — Skill has no way to send secondary toolbar actions to the system overflow (ellipsis) menu.  
_references/01-api-reference.md:317_

- **Correct / new info:** ToolbarOverflowMenu (ToolbarContent container) and View.toolbarOverflowMenu(content:). 'An overflow menu represents actions that are always placed in the toolbar's overflow menu, regardless of the toolbar mode, platform, or customizability. In iOS and visionOS, this content is placed into the overflow menu in the navigation bar.' Not available on macOS, tvOS or watchOS. HIG (iPhone Duo): 'Use the system overflow menu. If your app has its own overflow menu, move those actions into the system menu... Reserve the ellipsis symbol for overflow.'
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, visionOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu (apple-doc, confidence high)
- **Action:** Teach `.toolbar { ToolbarOverflowMenu { Button("Archive", systemImage: "archivebox") {} } }`. Add an anti-pattern: don't build a custom glass ellipsis Menu in the nav bar on iOS 27; use ToolbarOverflowMenu instead. Note that it is unavailable on macOS.

```swift
nonisolated struct ToolbarOverflowMenu<Content> where Content : View  |  init(content: () -> Content)  |  nonisolated func toolbarOverflowMenu<C>(@ContentBuilder content: () -> C) -> some View where C : View
```

### 5. `new-api-ios27` — Pattern places the primary/share action with .topBarTrailing, which can move into overflow when space is tight.  
_patterns/glass-navigation-bar.md:22_

- **Correct / new info:** ToolbarItemPlacement.topBarPinnedTrailing: 'A placement that pins the item to the trailing edge of the toolbar. Pinned items only move to the overflow menu when search is active and there isn't enough room. On iOS and visionOS, the top bar is the navigation bar.'
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, visionOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbaritemplacement/topbarpinnedtrailing (apple-doc, confidence high)
- **Action:** In the nav-bar pattern and the API reference, show `ToolbarItem(placement: .topBarPinnedTrailing) { ShareButton() }` for the one action that must never overflow, with an availability gate. Keep .topBarTrailing for iOS 26.

```swift
static let topBarPinnedTrailing: ToolbarItemPlacement
```

### 6. `new-api-ios27` — Skill doesn't cover removing the default padding around a toolbar item's content.  
_references/01-api-reference.md:298_

- **Correct / new info:** ToolbarContent.contentMarginsRemoved(_:): 'Use this modifier to remove the default padding around a toolbar item's content. This is useful for content that goes to the edge of the item.' This is not listed on the SwiftUI Updates page but is documented as 27.0.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/contentmarginsremoved(_:) (apple-doc, confidence high)
- **Action:** Mention it as the supported way to make edge-to-edge custom toolbar content (avatars, progress rings) inside the glass item, instead of negative padding hacks.

```swift
nonisolated func contentMarginsRemoved(_ removed: Bool = true) -> some ToolbarContent
```

### 7. `new-api-ios27` — Tab bar pattern only knows role: .search for the separated trailing tab.  
_patterns/glass-tab-bar.md:20_

- **Correct / new info:** TabRole.prominent: 'A tab role that provides prominent visual treatment to one of the tabs in supported tab bars. Only one tab can receive the prominent treatment. When there are no tabs with an explicit .prominent role, then a .search role tab may receive the prominent visual treatment by default.' Updates page: 'Set the prominent role on a tab to place the tab in a separate, trailing position of the tab bar.' WWDC26: `Tab(role: .prominent) { CartTab() }`.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabrole/prominent (apple-doc, confidence high)
- **Action:** Add a 'Prominent tab (iOS 27)' variation, e.g. Cart/Create. State the rules: only one prominent tab, and .search gets the treatment when no explicit .prominent exists. Update the anti-patterns so that no custom floating glass FAB imitates a separated tab.

```swift
static var prominent: TabRole { get }
```

### 8. `new-api-ios27` — Sheet transitions taught are only the default slide-up and the .zoom morph.  
_patterns/glass-modal-sheet.md:64_

- **Correct / new info:** NavigationTransition.crossFade / CrossFadeNavigationTransition: 'A navigation transition that cross-fades between the appearing view and the disappearing view. Specify this transition in a sheet to have it appear by fading in over the content, as opposed to moving upwards to cover content.' Example: `.sheet(isPresented: $showSheet) { Text("Sheet Content").presentationDetents([.medium]).navigationTransition(.crossFade) }`. Not available on macOS.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/navigationtransition/crossfade (apple-doc, confidence high)
- **Action:** Add a crossFade variation for glass sheets that should materialize in place (e.g. over a map or photo). Note that it applies inside the sheet content and is absent on macOS.

```swift
static var crossFade: CrossFadeNavigationTransition { get }
```

### 9. `new-api-ios27` — Sheet patterns can't move a sheet to the leading or trailing edge to keep content (e.g. a map) visible.  
_patterns/glass-modal-sheet.md:80_

- **Correct / new info:** View.presentationPlacement(_:) with PresentationPlacement members .automatic, .center, .leading, .trailing. 'By default, a presentation uses automatic placement. Use this modifier to place it on the leading or trailing edge... Only sheet presentations respect this placement.' This is not listed on the SwiftUI Updates page.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/presentationplacement(_:) (apple-doc, confidence high)
- **Action:** Add the variation `Map().sheet(isPresented:) { PlaceDetailView().presentationDetents([.medium, .large]).presentationPlacement(.leading) }`, gated to iOS 27.

```swift
nonisolated func presentationPlacement(_ placement: PresentationPlacement) -> some View
```

### 10. `new-api-ios26x` — Skill shows only `.tabViewBottomAccessory { … }`, with no way to hide or show it dynamically.  
_references/01-api-reference.md:379_

- **Correct / new info:** tabViewBottomAccessory(isEnabled:content:) was added in 26.1: 'Places a view as the bottom accessory of the tab view. Use this modifier to dynamically show and hide the accessory view.' isEnabled: 'If true, the bottom accessory is shown; otherwise, the bottom accessory is hidden.' Both overloads now print `@ContentBuilder content`.
- **Availability:** iOS 26.1, iPadOS 26.1, Mac Catalyst 26.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:) (apple-doc, confidence high)
- **Action:** Teach `.tabViewBottomAccessory(isEnabled: hasNowPlaying) { … }` (iOS 26.1+) instead of conditionally emptying the accessory content. Note that it exists only on iOS, iPadOS and Mac Catalyst.

```swift
nonisolated func tabViewBottomAccessory<Content>(isEnabled: Bool, @ContentBuilder content: () -> Content) -> some View where Content : View
```

### 11. `factually-wrong` — `@Environment(\.tabViewBottomAccessoryPlacement) var placement // .expanded | .collapsed`  
_references/01-api-reference.md:396_

- **Correct / new info:** TabViewBottomAccessoryPlacement is an enum with cases `expanded` ('The bar is expanded on top of the bottom tab bar...') and `inline` ('The view is displayed in line with the bottom tab bar.'). There is no `.collapsed`. The environment value is Optional: `var tabViewBottomAccessoryPlacement: TabViewBottomAccessoryPlacement? { get }`, where 'A nil value corresponds to an undefined placement.'
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement (apple-doc, confidence high)
- **Action:** Replace the comment with `.expanded | .inline (Optional — handle nil)` and fix any switch over the placement to handle nil/default.

```swift
enum TabViewBottomAccessoryPlacement { case expanded; case inline }
```

### 12. `new-api-ios26x` — Button styles section offers only `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)`; a configurable glass button requires .glassEffect on a Button.  
_references/01-api-reference.md:256_

- **Correct / new info:** PrimitiveButtonStyle.glass(_:) ('A button style that applies a configurable Liquid Glass effect based on the button's context.') is documented with 26.0 availability, e.g. `Button("Button") {}.buttonStyle(.glass(.clear))`. GlassButtonStyle also gained `init(_ glass: Glass)`, documented as introduced in 26.1. 'In tvOS, this button style applies a Liquid Glass effect regardless of whether the button has focus.'
- **Availability:** glass(_:): iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0; GlassButtonStyle.init(_:): iOS 26.1, iPadOS 26.1, Mac Catalyst 26.1, macOS 26.1, tvOS 26.1, watchOS 26.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glass(_:) (apple-doc, confidence high)
- **Action:** Add `.buttonStyle(.glass(.clear))` and `.buttonStyle(.glass(.regular.tint(.orange)))` as the preferred way to get clear or tinted glass buttons over media. Add an anti-pattern against `.glassEffect(.clear)` on a Button with a plain style. Flag the 26.0 (static func) vs 26.1 (init) documentation discrepancy.

```swift
nonisolated static func glass(_ glass: Glass) -> Self   |   nonisolated init(_ glass: Glass)  (GlassButtonStyle)
```

### 13. `other` — Skill's Glass/glassEffect/GlassEffectContainer/glassEffectID/glassEffectUnion/glassEffectTransition API (iOS 26) is presented as the full current surface.  
_references/01-api-reference.md:61_

- **Correct / new info:** I checked whether these symbols gained members in 26.x or 27; none did. Glass still has only regular, clear, identity, tint(_:) and interactive(_:). GlassEffectTransition still has identity, matchedGeometry and materialize. GlassEffectContainer still has only init(spacing:content:). Every page shows introducedAt 26.0, and none lists visionOS. The only glass-related addition is GlassButtonStyle.init(_:) in 26.1. WWDC26 says the refreshed look requires no code changes.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass (apple-doc, confidence high)
- **Action:** State in the skill that the core glass API is unchanged in iOS 27; the iOS 27 work is in toolbars, tabs, presentations and layout. Don't invent new Glass variants. Note that tint takes `Color?` (pass nil to clear the tint).

```swift
struct Glass { func interactive(Bool) -> Glass; func tint(Color?) -> Glass; static var clear: Glass; static var identity: Glass; static var regular: Glass }
```

### 14. `wrong-signature` — `.glassEffect(_:in:isEnabled:)` with `isEnabled: Bool = true`; also used at references/07-anti-patterns.md:127, references/06-performance.md:162 and references/02-hig-principles.md:133.  
_references/01-api-reference.md:7_

- **Correct / new info:** The only overload is glassEffect(_:in:). The doc path view/glasseffect(_:in:isenabled:) returns 404. The default shape is DefaultGlassEffectShape (a capsule).
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Remove isEnabled from every signature and example. To toggle, teach `.glassEffect(flag ? .regular : .identity)`. Fix the anti-pattern, performance and HIG files that rely on isEnabled.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 15. `wrong-signature` — `func glassEffectTransition(_ transition: GlassEffectTransition, isEnabled: Bool = true)` and `enum GlassEffectTransition { case identity; case matchedGeometry; case materialize }`  
_references/01-api-reference.md:224_

- **Correct / new info:** glassEffectTransition has no isEnabled parameter. GlassEffectTransition is a struct with static properties `identity`, `matchedGeometry` and `materialize`. Separately, glassEffectID and glassEffectUnion take an Optional `some Hashable & Sendable` id, not a generic `ID: Hashable`. GlassEffectContainer has a single `init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)`.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/glasseffecttransition (apple-doc, confidence high)
- **Action:** Replace these signature blocks with the verbatim declarations, and note that ids must be Sendable. Don't switch over GlassEffectTransition as an enum.

```swift
@MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View | struct GlassEffectTransition { static var identity; static var matchedGeometry; static var materialize } | nonisolated func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View | @MainActor @preconcurrency func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View | @MainActor @preconcurrency init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)
```

### 16. `wrong-availability` — Minimum requirements table lists visionOS 26.0+ for Liquid Glass; SKILL.md frontmatter also lists visionOS 26+.  
_references/01-api-reference.md:532_

- **Correct / new info:** Glass, glassEffect(_:in:), GlassEffectContainer, glassEffectID, glassEffectUnion, glassEffectTransition, GlassButtonStyle, GlassProminentButtonStyle and PrimitiveButtonStyle.glass(_:) list iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS only, with no visionOS entry. On visionOS the glass API is glassBackgroundEffect(...) with GlassBackgroundEffect / GlassBackgroundDisplayMode (visionOS 1.0/2.4).
- **Availability:** glassEffect family: iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 (no visionOS); glassBackgroundEffect(_:in:displayMode:): visionOS 2.4
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Drop visionOS from the glassEffect platform list, or add a note that visionOS uses glassBackgroundEffect. Add iOS 27 / Xcode 27 rows for the new chrome APIs.

```swift
nonisolated func glassBackgroundEffect<T, S>(_ effect: S, in shape: T, displayMode: GlassBackgroundDisplayMode = .always) -> some View where T : InsettableShape, S : GlassBackgroundEffect
```

### 17. `nonexistent-api` — `.rect(cornerRadius: .containerConcentric)` matches the parent radius; also used in SKILL.md golden rule 4, 03-design-tokens.md, 02-hig-principles.md, 07-anti-patterns.md, glass-card-stack.md and the pre-ship checklist.  
_references/01-api-reference.md:466_

- **Correct / new info:** `containerConcentric` does not appear in the ConcentricRectangle or Edge.Corner.Style docs. The real iOS 26 API is ConcentricRectangle (`init()`, `init(corners:isUniform:)`, uniform/individual-corner initializers) with Edge.Corner.Style members `.concentric`, `.concentric(minimum:)` and `.fixed(_:)`, plus Shape.rect(corners:isUniform:). Concentric radii resolve against `containerShape(_:)` or system containers.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/concentricrectangle (apple-doc, confidence high)
- **Action:** Replace every `.rect(cornerRadius: .containerConcentric)` with `.glassEffect(.regular, in: ConcentricRectangle())` or `.rect(corners: .concentric(minimum: 12), isUniform: true)`, and teach `.containerShape(_:)` on custom containers.

```swift
struct ConcentricRectangle | static var concentric: Edge.Corner.Style | static func concentric(minimum: Edge.Corner.Style?) -> Edge.Corner.Style | static func fixed(_: CGFloat) -> Edge.Corner.Style
```

### 18. `new-api-ios27` — Concentric corners section offers only shape-based concentricity.  
_references/01-api-reference.md:472_

- **Correct / new info:** GeometryProxy.concentricCornerRadii and concentricCornerRadii(in:) return 'The resolved corner radii, or nil if no container shape is set or the shape does not provide sufficient corner info.' 'Unlike ConcentricRectangle, which calculates and draws the shape, this property only returns the calculated radii.' Release notes 177185166.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/geometryproxy/concentriccornerradii (apple-doc, confidence high)
- **Action:** Add an iOS 27 note: use `GeometryReader { geo in … geo.concentricCornerRadii … }.containerShape(.rect(cornerRadius: 48))` for custom drawing or animation that must stay concentric with the glass container.

```swift
var concentricCornerRadii: RectangleCornerRadii? { get }  |  func concentricCornerRadii(in frame: CGRect) -> RectangleCornerRadii?
```

### 19. `new-api-ios27` — The 'Vertical floating palette' variation positions custom vertical glass bars with no awareness of system vertical bars.  
_patterns/glass-floating-toolbar.md:54_

- **Correct / new info:** EnvironmentValues.toolbarVerticalEdge (BETA, iOS/iPadOS 27.1): 'This value reflects the system's preferred edge for the vertical bar in the current context, regardless of whether a vertical bar is currently visible. Use it to position custom bars or other UI relative to the system's bar placement... Returns nil on devices and in contexts where the system never places a vertical bar.' On iPhone Duo, toolbars, tab bars and nav controls move to the side (HIG 'Designing for iPhone Duo', Sept 9 2026).
- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarverticaledge (apple-doc, confidence high)
- **Action:** In the floating-toolbar pattern, read `@Environment(\.toolbarVerticalEdge)` and keep custom glass palettes off the system's vertical-bar edge. Label it beta (27.1).

```swift
var toolbarVerticalEdge: HorizontalEdge? { get }
```

### 20. `new-api-ios27` — Skill assumes system bars are always horizontal (top nav bar / bottom tab bar).  
_references/01-api-reference.md:298_

- **Correct / new info:** View.toolbarVerticalBehavior(_:) with ToolbarVerticalBehavior (.automatic, .disabled) (BETA 27.1). '...Use disabled to opt out of the vertical bar, causing bar content to fall back to the standard horizontal top and bottom toolbars. Disable the vertical bar only for UIs that are better served by horizontal bars — such as a fullscreen video player with toolbar controls, or a non-scrolling layout like a calculator... avoid changing it frequently... To hide the bars on a given screen rather than change the layout, use toolbarVisibility(_:for:) instead.' Resolution: NavigationStack uses the top-most view, TabView the selected view, and NavigationSplitView the trailing-most column.
- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarverticalbehavior(_:) (apple-doc, confidence high)
- **Action:** Add a 'Controls on the vertical axis (iPhone Duo, iOS 27.1 beta)' section explaining that system glass bars can render vertically. Default to automatic, use .disabled only for full-screen media or calculator-style screens, and never toggle it per state.

```swift
nonisolated func toolbarVerticalBehavior(_ behavior: ToolbarVerticalBehavior) -> some View
```

### 21. `new-api-ios27` — No per-item control over horizontal vs vertical bar placement.  
_references/01-api-reference.md:298_

- **Correct / new info:** ToolbarContent.axisBehavior(_:) and CustomizableToolbarContent.axisBehavior(_:) with ToolbarItemAxisBehavior (.automatic; .horizontalOnly: 'The item only supports horizontal bars. If an item only supports horizontal bars and no horizontal bars are present, the item is not shown.'; .verticalPreferred: '...prefers a vertical placement when both horizontal and vertical bars are present.') (BETA 27.1). HIG: 'Labels that include text stay in a horizontal bar, so prefer a symbol wherever one works.'
- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/axisbehavior(_:) (apple-doc, confidence high)
- **Action:** Document it with a warning that .horizontalOnly items disappear when only vertical bars exist. Recommend `Button("Title", systemImage:)` (title + symbol) for every toolbar item, per the HIG.

```swift
nonisolated func axisBehavior(_ behavior: ToolbarItemAxisBehavior) -> some ToolbarContent
```

### 22. `new-api-ios27` — No guidance on toolbar vs tab bar priority when bars share constrained space.  
_references/01-api-reference.md:355_

- **Correct / new info:** View.toolbarVerticalCompressionBehavior(_:) with ToolbarVerticalCompressionBehavior (.automatic, .prefersTabBar, .prefersToolbarItems) (BETA 27.1): 'Sets how bars should compress when different types of toolbars are hosted together and space is constrained.' HIG: navigation-focused experiences keep the tab bar (the default); task-oriented experiences minimize the tab bar to keep toolbar actions.
- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarverticalcompressionbehavior(_:) (apple-doc, confidence high)
- **Action:** Add it to the TabView section as beta and give the HIG decision rule: editor or task screens use .prefersToolbarItems, browse screens keep the default.

```swift
nonisolated func toolbarVerticalCompressionBehavior(_ behavior: ToolbarVerticalCompressionBehavior) -> some View
```

### 23. `new-api-ios27` — New adaptive two-pane layout container (September 2026 'Arrangement views').

- **Correct / new info:** ArrangementView<Primary, Secondary> (init(primary:secondary:), init(_: ArrangementViewStyleConfiguration)). Styles via arrangementViewStyle(_:): .automatic (resolves to split), .split (SplitArrangementViewStyle.axes(_:)), .overlay (OverlayArrangementViewStyle.axes(_:)). Custom styles conform to ArrangementViewStyle (makeBody(configuration:), configuration.primary/.secondary). Modifiers: splitArrangementLayoutRatio(_:), splitArrangementLayoutRatio(minHorizontal:idealHorizontal:maxHorizontal:minVertical:idealVertical:maxVertical:), splitArrangementLayoutSize(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:), splitArrangementFixedLayoutSize(horizontal:vertical:), overlayArrangementEdge(_:). Environment values: splitArrangementAxis (Axis?) and overlayArrangementZIndex (Int). All are BETA 27.1. HIG: 'Keep navigation outside of arrangement views... place navigation containers like navigation split views and tab views around it rather than within it.'
- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/arrangementview (apple-doc, confidence high)
- **Action:** Optionally add a short layout note for glass media screens: `ArrangementView { PlayerControls() } secondary: { VideoPlayer() }.arrangementViewStyle(.overlay)`, with glass controls in the primary view. Keep TabView/NavigationStack outside. Mark it beta.

```swift
nonisolated struct ArrangementView<Primary, Secondary> where Primary : View, Secondary : View
```

### 24. `new-api-ios27` — No hardware-avoidance API for floating glass controls.

- **Correct / new info:** ReservedRegion (id, frame, isActive, kind, margins). Kind members: .occlusion ('An area where an element, such as the Dynamic Island, a camera, or window controls, occludes content.') and .division ('...such as at the fold of a hinge'). QueryOptions.includeInactive. Read regions with GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:). By default, frames are mirrored for RTL. All BETA 27.1.
- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/reservedregion (apple-doc, confidence high)
- **Action:** In the floating-glass patterns, note that custom floating glass (FABs, palettes) must avoid occlusion and division regions on iPhone Duo; system bars, sheets and alerts adapt automatically. Mark it beta.

```swift
func reservedRegions(kind: ReservedRegion.Kind, options: ReservedRegion.QueryOptions = [], layoutDirectionBehavior: LayoutDirectionBehavior = .mirrors) -> [ReservedRegion]
```

### 25. `new-api-ios27` — Hinge state APIs (September 2026 'Hinge').

- **Correct / new info:** View.onHingeChange(isEnabled:_:) delivers DeviceHingeContext (var hinge: DeviceHinge?). DeviceHinge has angle (Angle) and status (DeviceHinge.Status: .closed, .partiallyOpen, .fullyOpen). All BETA 27.1.
- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:) (apple-doc, confidence high)
- **Action:** Mention it only briefly. It is low-relevance to glass; prefer ArrangementView or ReservedRegion over manual hinge math, following the HIG advice to avoid extreme layout changes.

```swift
nonisolated func onHingeChange(isEnabled: Bool = true, _ action: @escaping (DeviceHingeContext, DeviceHingeContext) -> Void) -> some View
```

### 26. `new-api-ios27` — Scene accessories (secondary display / camera content).

- **Correct / new info:** View.sceneAccessory(content:) (27.0) takes SceneAccessoryContent: ExternalNonInteractiveAccessory (27.0; 'presents non-interactive content on an external display') and CameraCaptureAccessory (27.1 beta; 'A scene accessory that presents content during camera capture', shown on the iPhone Duo outer display). Each has init(content:) and init(isEnabled: Binding<Bool>, content:), plus onAvailabilityChange.
- **Availability:** sceneAccessory / ExternalNonInteractiveAccessory: iOS 27.0, iPadOS 27.0; CameraCaptureAccessory: iOS 27.1 (beta), iPadOS 27.1 (beta)
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/sceneaccessory(content:) (apple-doc, confidence high)
- **Action:** Out of scope for glass. List it in a 'not covered' note only.

```swift
nonisolated func sceneAccessory<C>(@ContentBuilder content: () -> C) -> some View where C : SceneAccessoryContent
```

### 27. `changed-api` — Signatures throughout use `@ViewBuilder content` (e.g. GlassEffectContainer init(@ViewBuilder content:)).  
_references/01-api-reference.md:116_

- **Correct / new info:** Xcode 27 introduces ContentBuilder: 'typealias ContentBuilder = ViewBuilder'. 'SwiftUI constructs type-agnostic content from closures that you mark with ContentBuilder, which serves as the unified replacement for type-specific builders like ToolbarContentBuilder and CommandsBuilder.' Apple's declarations (GlassEffectContainer.init, tabViewBottomAccessory, safeAreaBar, toolbarOverflowMenu, swipeActions, alert) now print @ContentBuilder. It is a typealias, so existing @ViewBuilder code still compiles; the docs list availability back to iOS 13.
- **Availability:** iOS 13.0, iPadOS 13.0, Mac Catalyst 13.0, macOS 10.15, tvOS 13.0, visionOS 1.0, watchOS 6.0 (requires building with Xcode 27)
- **Evidence:** https://developer.apple.com/documentation/swiftui/contentbuilder (apple-doc, confidence high)
- **Action:** Update quoted signatures to match Apple (@ContentBuilder). Optionally show `@ContentBuilder var toolbarItems: some ToolbarContent { … }` for factored glass toolbar content when building with Xcode 27, noting that @ToolbarContentBuilder still works.

```swift
typealias ContentBuilder = ViewBuilder
```

### 28. `behavior-change` — Examples use `@State private var x = …` assuming property-wrapper semantics.  
_examples/01-SettingsScreen.swift_

- **Correct / new info:** Building with Xcode 27, @State becomes a macro: `@attached(accessor, names: named(init), named(get), named(set)) @attached(peer, names: prefixed(`_`), prefixed(__), prefixed(`$`)) macro State()`. Release notes: the initial-value expression is no longer re-evaluated on every view re-instantiation, and 'This new behavior back-deploys to iOS 17 aligned OSes.' Breaks: assigning in init when a declaration initial value exists no longer compiles in some cases; the synthesized memberwise init for all-private structs is disabled; generic inference is less flexible; 'Composing @State with other property wrappers or macros is not supported.' The State() doc says: 'When you build with Xcode 26 or earlier, the system uses the State property wrapper instead.'
- **Availability:** iOS 13.0, iPadOS 13.0, Mac Catalyst 13.0, macOS 10.15, tvOS 13.0, visionOS 1.0, watchOS 6.0 (macro when building with Xcode 27; behavior back-deploys to iOS 17-aligned)
- **Evidence:** https://developer.apple.com/documentation/swiftui/state() (apple-doc, confidence high)
- **Action:** Add a short Xcode 27 note: @State with an @Observable model is now initialized once, so the `@State private var model = Model()` pattern is safe. Don't give @State both an initial value and an init assignment, and don't stack it with other wrappers. A grep found no init-assigned @State in the current examples.

```swift
@attached(accessor, names: named(init), named(get), named(set)) @attached(peer, names: prefixed(`_`), prefixed(__), prefixed(`$`)) macro State()
```

### 29. `new-api-ios27` — Full-bleed media screens under glass chrome have no SwiftUI way to set status bar style or visibility.  
_examples/04-PhotoDetailScreen.swift_

- **Correct / new info:** ToolbarPlacement.statusBar: 'Use with toolbarVisibility(_:for:) to hide the status bar, or with toolbarColorScheme(_:for:) to specify the preferred status bar style. Using this placement with other toolbar customization APIs has no effect.' Example: `.toolbarVisibility(hideStatusBar ? .hidden : .automatic, for: .statusBar).toolbarColorScheme(.dark, for: .statusBar)`.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarplacement/statusbar (apple-doc, confidence high)
- **Action:** In the photo, music and onboarding examples, show `.toolbarColorScheme(.dark, for: .statusBar)` for light-on-dark media behind glass, gated to iOS 27.

```swift
static var statusBar: ToolbarPlacement { get }
```

### 30. `new-api-ios27` — Search scope / tab-like pickers use the standard segmented picker.  
_patterns/glass-search-field.md:33_

- **Correct / new info:** TabsPickerStyle / PickerStyle.tabs: 'A picker style that presents options as segmented tabs... On iOS, tvOS, and visionOS, the visual appearance matches that of the standard .segmented style. On all supported platforms, VoiceOver announces options as tabs.' Release notes 173211711.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabspickerstyle (apple-doc, confidence high)
- **Action:** Use `.pickerStyle(.tabs)` (iOS 27) for pickers that switch content views. Keep .segmented for value selection. Note it is unavailable on watchOS.

```swift
struct TabsPickerStyle  |  static var tabs: TabsPickerStyle
```

### 31. `new-api-ios27` — Skill has no supported way to match text-field shape to capsule glass buttons.  
_patterns/glass-search-field.md:83_

- **Correct / new info:** View.textInputBorderShape(_:) with TextInputBorderShape (.automatic, .capsule, .roundedRectangle) and TextFieldStyle.bordered ('A text field style with a system-defined border whose shape is determined by the textInputBorderShape(_:) modifier'), both 27.0. TextFieldStyle.roundedBorder and .squareBorder carry deprecatedAt 27.2 with the message 'Use `textFieldStyle(.bordered)` with `textInputBorderShape(.roundedRectangle)`'. Example: `HStack { TextField("Search", text: $searchText); Button("Go", action: search) }.buttonBorderShape(.capsule).textInputBorderShape(.capsule)`.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0 (roundedBorder deprecatedAt 27.2 on iOS/iPadOS/Mac Catalyst/macOS)
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/textinputbordershape(_:) (apple-doc, confidence high)
- **Action:** In the login and search patterns, teach `.textFieldStyle(.bordered).textInputBorderShape(.capsule)` next to capsule glass buttons instead of hand-made glassEffect fields. Avoid .roundedBorder in new code.

```swift
nonisolated func textInputBorderShape(_ shape: TextInputBorderShape) -> some View  |  static var bordered: BorderedTextFieldStyle { get }
```

### 32. `new-api-ios27` — Swipe actions outside List.

- **Correct / new info:** swipeActions(edge:allowsFullSwipe:content:onPresentationChanged:) (27.0) adds actions to a row 'in a list or container'. swipeActionsContainer() (27.0) 'Coordinates swipe action dismissal and mutual exclusion across rows in a container'; 'Applying this modifier to a List is a no-op.' Use it with ScrollView/LazyVStack card stacks.
- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/swipeactionscontainer() (apple-doc, confidence high)
- **Action:** In glass-card-stack, mention system swipe actions on custom stacks (iOS 27) instead of custom drag gestures that reveal glass buttons.

```swift
nonisolated func swipeActions(edge: HorizontalEdge = .trailing, allowsFullSwipe: Bool = true, @ContentBuilder content: () -> some View, onPresentationChanged: @escaping (Bool) -> Void) -> some View  |  nonisolated func swipeActionsContainer() -> some View
```

### 33. `new-api-ios27` — Alerts and confirmation dialogs driven by an optional item or error.

- **Correct / new info:** New overloads: alert(_:item:actions:), alert(_:item:actions:message:), alert(error:actions:), alert(error:actions:message:), confirmationDialog(_:item:titleVisibility:actions:), confirmationDialog(_:item:titleVisibility:actions:message:). They require the Xcode 27 SDK but back-deploy: 'can now be used by projects targeting iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, and visionOS 1.0' (release notes 179388848). Doc pages show iOS 15.0 with `@export(implementation)`.
- **Availability:** iOS 15.0, iPadOS 15.0, Mac Catalyst 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0 (requires Xcode 27 SDK)
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/alert(_:item:actions:) (apple-doc, confidence high)
- **Action:** Where examples present destructive confirmations (e.g. 07-ProfileScreen), use `.confirmationDialog("Delete?", item: $toDelete) { item in … }` when building with Xcode 27.

```swift
@export(implementation) nonisolated func alert<A, T>(_ title: Text, item data: Binding<T?>, @ContentBuilder actions: (T) -> A) -> some View where A : View
```

### 34. `behavior-change` — Patterns and token recipes set .controlSize / .buttonBorderShape on a parent and expect them to style glass buttons inside sheets.  
_patterns/glass-modal-sheet.md:95_

- **Correct / new info:** iOS 27 release notes (167448274): 'In apps built with the 27.0 SDKs, the controlSize, buttonSizing, buttonRepeatBehavior, menuIndicatorVisibility, and ButtonBorderShape environment values are now reset to their default values in sheets and popovers.'
- **Availability:** Apps built with the 27.0 SDKs
- **Evidence:** https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes (apple-other, confidence high)
- **Action:** Add a gotcha: apply .controlSize(.large/.extraLarge) and .buttonBorderShape(.circle/.capsule) inside the sheet or popover content, not on the presenter.

### 35. `behavior-change` — Tab bar gotchas don't cover selection validity.  
_patterns/glass-tab-bar.md:83_

- **Correct / new info:** iOS 27 release notes (164516837): 'In apps built with the iOS 27.0 and iPadOS 27.0 SDKs, a TabView enforces that its selection is set to a visible tab. TabView might crash when its selection is set to a hidden or otherwise unavailable tab.'
- **Availability:** Apps built with the iOS 27.0 / iPadOS 27.0 SDKs
- **Evidence:** https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes (apple-other, confidence high)
- **Action:** Add a gotcha: never bind TabView(selection:) to a tab that is hidden or not present (e.g. a conditional prominent or search tab).

### 36. `behavior-change` — Mental model / appearance guidance is iOS 26-only.  
_SKILL.md:95_

- **Correct / new info:** WWDC26 'What's new in SwiftUI' (269): 'When I build and run our app, the Liquid Glass design automatically takes on its updated appearance... without having to change a single line of code! Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint.' 'On macOS, like on iOS, you can mark Liquid Glass custom elements as "interactive" so they respond more fluidly to user's clicks.' 'our iPad app automatically takes on a distinct appearance when inactive, with the icons and text dimming'. Use `@Environment(\.appearsActive)` for custom elements. I found no SwiftUI API that reads the user's Liquid Glass tint preference.
- **Availability:** iOS 27 / iPadOS 27 / macOS 27 (built with Xcode 27)
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/269/ (apple-video, confidence medium)
- **Action:** Add an 'iOS 27 changes' note: the glass look is refreshed automatically, users can adjust glass tint, so don't fight it with heavy custom tints. Custom glass on iPad and Mac should dim when appearsActive is false. .interactive() now matters on macOS too.

### 37. `behavior-change` — Search-in-nav-bar variation doesn't mention that the bar may minimize automatically.  
_patterns/glass-navigation-bar.md:45_

- **Correct / new info:** ToolbarMinimizationBehavior.automatic: 'The system determines the minimize behavior. By default, navigation bars on iOS will minimize when the view has a searchable using the toolbarPrincipal placement.' SearchFieldPlacement.toolbarPrincipal: 'The search field appears in the principal section of the toolbar.'
- **Availability:** ToolbarMinimizationBehavior: iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior (apple-doc, confidence high)
- **Action:** Note that `.searchable(text:, placement: .toolbarPrincipal)` on iOS 27 implies an auto-minimizing nav bar. Use `.toolbarMinimizationBehavior(.never, for: .navigationBar)` to opt out.

```swift
static var automatic: ToolbarMinimizationBehavior  |  static var toolbarPrincipal: SearchFieldPlacement { get }
```

### 38. `behavior-change` — Menu item icons.

- **Correct / new info:** iOS 27 release notes (170480710): 'The menu bar on iPadOS 27.0 and macOS 27.0, as well as context menus on macOS 27.0, present a reduced set of menu item images. By default, SwiftUI now hides all menu item symbol images in most contexts... Use the labelStyle(_:) view modifier with the .titleAndIcon style to indicate that a menu item Label's icon should always be shown.'
- **Availability:** iPadOS 27.0, macOS 27.0
- **Evidence:** https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes (apple-other, confidence high)
- **Action:** Mention it briefly in the iPad/macOS notes. Glass toolbar overflow and ToolbarOverflowMenu items still need Label titles.

### 39. `design-guidance` — Skill teaches ToolbarSpacer(.fixed) to add breathing room between glass items as a general technique.  
_references/01-api-reference.md:317_

- **Correct / new info:** HIG 'Designing for iPhone Duo' (new Sept 9 2026): 'Group related toolbar items instead of spacing them manually. Groups you create with ToolbarItemGroup... provide space between items and other groups automatically, and adapt as the available space changes, so avoid adding fixed spacing yourself.' Also: 'Provide both a title and a symbol for each toolbar item that isn't text-only', 'Use the system overflow menu', 'In general, don't override the default bar placement', 'Follow the standard placement order... Reserve the top of the vertical axis for primary navigation controls, like Back or Close, followed by prominent actions, like Done.'
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo (apple-other, confidence high)
- **Action:** Rewrite the ToolbarSpacer advice: prefer ToolbarItemGroup grouping and use ToolbarSpacer sparingly. Add the iPhone Duo vertical-controls rules to 02-hig-principles.md.

### 40. `design-guidance` — Golden rule 5: 'Never use .ultraThinMaterial or other legacy Material values in iOS 26+. They look out of place.' (also checklists/pre-ship-checklist.md:9)  
_SKILL.md:88_

- **Correct / new info:** HIG Materials: 'Don't use Liquid Glass in the content layer... Instead, use standard materials for elements in the content layer, such as app backgrounds.' Also: 'Only use clear Liquid Glass for components that appear over visually rich backgrounds... If the underlying content is bright, consider adding a dark dimming layer of 35% opacity.' And: 'The appearance of these variants can differ in response to certain system settings, like if people choose a preferred look for Liquid Glass in their device's settings.'
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Change the rule to 'Never use Material for chrome; standard materials remain correct for content-layer surfaces.' Add the 35% dimming guidance for .clear glass over bright media, and fix the checklist item.

### 41. `compile-risk` — `ToolbarItem { Button(...) { }.sharedBackgroundVisibility(.hidden) }`  
_references/01-api-reference.md:344_

- **Correct / new info:** sharedBackgroundVisibility is a ToolbarContent modifier only (the View variant returns 404). It must be applied to the ToolbarItem: `ToolbarItem(placement: .principal) { BuildStatus() }.sharedBackgroundVisibility(.hidden)`. 'Hiding the effect will cause the item to be placed in its own grouping.' Availability: iOS, iPadOS, Mac Catalyst and macOS only.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:) (apple-doc, confidence high)
- **Action:** Move the modifier outside the ToolbarItem closure in the API reference and any examples. Do the same for the new iOS 27 ToolbarContent modifiers (visibilityPriority, axisBehavior, contentMarginsRemoved).

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
```

### 42. `compile-risk` — `ToolbarItem(placement: .bottomBar) { DefaultToolbarItem(kind: .search, placement: .bottomBar) }` (also patterns/glass-search-field.md:59-60)  
_references/01-api-reference.md:417_

- **Correct / new info:** DefaultToolbarItem conforms to ToolbarContent (init(kind:placement:)), while ToolbarItem<ID, Content> requires Content : View. A DefaultToolbarItem therefore cannot be the content of a ToolbarItem; it is placed directly in .toolbar { }. ToolbarDefaultItemKind members: sidebarToggle, search, title.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem (apple-doc, confidence medium)
- **Action:** Replace with `.toolbar { DefaultToolbarItem(kind: .search, placement: .bottomBar) }`.

```swift
nonisolated struct DefaultToolbarItem  |  init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement)
```

### 43. `factually-wrong` — tabBarMinimizeBehavior lists .automatic, .onScrollDown and .never only.  
_references/01-api-reference.md:372_

- **Correct / new info:** TabBarMinimizeBehavior members: automatic, never, onScrollDown and onScrollUp ('Minimize the tab bar when upwards scrolling starts. Minimizing is supported for tab bars on only iPhone.'). onScrollDown says the same: 'Minimizing is supported for tab bars on only iPhone.'
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior (apple-doc, confidence high)
- **Action:** Add .onScrollUp, state that minimization is iPhone-only, and cross-reference the new iOS 27 navigation-bar toolbarMinimizationBehavior.

```swift
struct TabBarMinimizeBehavior { static let automatic; static let never; static let onScrollDown; static let onScrollUp }
```

### 44. `nonexistent-api` — `ScrollView(.horizontal) { … }.scrollExtensionMode(.underSidebar)`  
_references/01-api-reference.md:516_

- **Correct / new info:** There is no scrollExtensionMode(_:) in SwiftUI (doc path returns 404, and it is absent from the Scroll views topic list). The real iOS 26 scroll-edge and safe-area APIs are scrollEdgeEffectStyle(_:for:) (ScrollEdgeEffectStyle .automatic/.hard/.soft), scrollEdgeEffectHidden(_:for:), safeAreaBar(edge:alignment:spacing:content:) and backgroundExtensionEffect() / backgroundExtensionEffect(isEnabled:).
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/scroll-views (apple-doc, confidence high)
- **Action:** Delete the 'Scroll extension' snippet and replace it with backgroundExtensionEffect / scrollEdgeEffectStyle guidance.

```swift
nonisolated func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View
```

### 45. `skill-authoring` — Frontmatter description, platforms and activation triggers mention only iOS 26 / Xcode 26.  
_SKILL.md:3_

- **Correct / new info:** iOS 27 / Xcode 27 shipped with chrome-layer APIs the skill should trigger on: toolbarMinimizationBehavior, visibilityPriority, ToolbarOverflowMenu, topBarPinnedTrailing, TabRole.prominent, crossFade sheet transition, presentationPlacement, plus the iPhone Duo vertical-bar APIs (27.1 beta).
- **Evidence:** https://developer.apple.com/documentation/updates/swiftui (apple-doc, confidence high)
- **Action:** Update the description and triggers to 'iOS 26 and iOS 27'. Add trigger terms (overflow menu, prominent tab, minimize navigation bar, iPhone Duo / vertical toolbar). Add a references/08-whats-new-ios27.md with availability gating (`if #available(iOS 27.0, *)`) and a clear BETA label on the 27.1 APIs. Update the Xcode row in the requirements table to 'Xcode 27 for iOS 27 APIs'.

## Symbols (110)

### `Glass`

```swift
struct Glass
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** interactive(_:) -> Glass, tint(_:) [func tint(Color?) -> Glass], clear, identity, regular
- **Doc:** https://developer.apple.com/documentation/swiftui/glass
- **Skill uses it correctly:** yes
- **Notes:** No new members in 26.x or 27. No visionOS. The skill shows tint(_ color: Color); the real parameter is Color?.

### `View.glassEffect(_:in:)`

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** glass, shape
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Skill uses it correctly:** NO
- **Notes:** The skill documents and uses a nonexistent isEnabled: parameter; glasseffect(_:in:isenabled:) returns 404.

### `glassEffect(_:in:isEnabled:)`

```swift
NOT FOUND
```

- **Availability:** 
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:isenabled:)
- **Skill uses it correctly:** NO
- **Notes:** 404. Used in 01-api-reference, 07-anti-patterns, 06-performance and 02-hig-principles.

### `GlassEffectContainer`

```swift
@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)
- **Doc:** https://developer.apple.com/documentation/swiftui/glasseffectcontainer
- **Skill uses it correctly:** yes
- **Notes:** Only one initializer exists; the skill lists two, but call sites compile because spacing defaults to nil. The declaration now prints @ContentBuilder. No changes in 27.

### `View.glassEffectID(_:in:)`

```swift
nonisolated func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** id, namespace
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffectid(_:in:)
- **Skill uses it correctly:** yes
- **Notes:** The skill's signature shows <ID: Hashable>; the real one requires Sendable and is Optional. Usage with String ids is fine.

### `View.glassEffectUnion(id:namespace:)`

```swift
@MainActor @preconcurrency func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** id, namespace
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffectunion(id:namespace:)
- **Skill uses it correctly:** yes
- **Notes:** 'All Liquid Glass effects with the same shape and Liquid Glass variant will be combined into a single shape.' No changes.

### `GlassEffectTransition`

```swift
struct GlassEffectTransition
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** identity, matchedGeometry, materialize
- **Doc:** https://developer.apple.com/documentation/swiftui/glasseffecttransition
- **Skill uses it correctly:** NO
- **Notes:** The skill declares it as an enum. Member usage (.materialize, .matchedGeometry) is fine.

### `View.glassEffectTransition(_:)`

```swift
@MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** transition
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffecttransition(_:)
- **Skill uses it correctly:** NO
- **Notes:** The skill adds a nonexistent isEnabled: parameter.

### `GlassButtonStyle`

```swift
nonisolated struct GlassButtonStyle
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** init(), init(_ glass: Glass) [26.1], makeBody(configuration:)
- **Doc:** https://developer.apple.com/documentation/swiftui/glassbuttonstyle
- **Skill uses it correctly:** yes
- **Notes:** init(_:) is new in 26.1 (iOS/iPadOS/Catalyst/macOS/tvOS/watchOS 26.1).

### `PrimitiveButtonStyle.glass(_:)`

```swift
nonisolated static func glass(_ glass: Glass) -> Self
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** glass
- **Doc:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glass(_:)
- **Skill uses it correctly:** yes
- **Notes:** Absent from the skill. Example: .buttonStyle(.glass(.clear)). The PrimitiveButtonStyle list also has glass, glassProminent and card ('applies a Liquid Glass effect when the button has focus').

### `GlassProminentButtonStyle`

```swift
nonisolated struct GlassProminentButtonStyle
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** init(), makeBody(configuration:)
- **Doc:** https://developer.apple.com/documentation/swiftui/glassprominentbuttonstyle
- **Skill uses it correctly:** yes
- **Notes:** No Glass-configurable init. No changes.

### `DefaultGlassEffectShape`

```swift
struct DefaultGlassEffectShape
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** init()
- **Doc:** https://developer.apple.com/documentation/swiftui/defaultglasseffectshape
- **Skill uses it correctly:** yes
- **Notes:** 'The default shape applied by glass effects, a capsule.'

### `View.glassBackgroundEffect(_:in:displayMode:)`

```swift
nonisolated func glassBackgroundEffect<T, S>(_ effect: S, in shape: T, displayMode: GlassBackgroundDisplayMode = .always) -> some View where T : InsettableShape, S : GlassBackgroundEffect
```

- **Availability:** visionOS 2.4
- **Members:** effect, shape, displayMode
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glassbackgroundeffect(_:in:displaymode:)
- **Skill uses it correctly:** yes
- **Notes:** The visionOS glass API; the skill wrongly implies glassEffect works on visionOS.

### `ToolbarContent.visibilityPriority(_:)`

```swift
@MainActor @preconcurrency func visibilityPriority(_ priority: ToolbarItemVisibilityPriority) -> some ToolbarContent
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 26.1, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** priority
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:)
- **Skill uses it correctly:** yes
- **Notes:** New, absent from the skill. Example: ToolbarItem { PrimaryControl() }.visibilityPriority(.high).

### `ToolbarItemVisibilityPriority`

```swift
struct ToolbarItemVisibilityPriority
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 26.1, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** automatic, low, high, init(lowerThan:), init(higherThan:)
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemvisibilitypriority
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ToolbarOverflowMenu`

```swift
nonisolated struct ToolbarOverflowMenu<Content> where Content : View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, visionOS 27.0
- **Members:** init(content: () -> Content)
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu
- **Skill uses it correctly:** yes
- **Notes:** New, with no macOS, tvOS or watchOS. Usage: .toolbar { ToolbarOverflowMenu { Button("Action 1") { } } }.

### `View.toolbarOverflowMenu(content:)`

```swift
nonisolated func toolbarOverflowMenu<C>(@ContentBuilder content: () -> C) -> some View where C : View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, visionOS 27.0
- **Members:** content
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbaroverflowmenu(content:)
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page. View-modifier form of ToolbarOverflowMenu.

### `ToolbarItemPlacement.topBarPinnedTrailing`

```swift
static let topBarPinnedTrailing: ToolbarItemPlacement
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, visionOS 27.0
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemplacement/topbarpinnedtrailing
- **Skill uses it correctly:** yes
- **Notes:** New. 'Pinned items only move to the overflow menu when search is active and there isn't enough room.'

### `ToolbarItemPlacement`

```swift
struct ToolbarItemPlacement
```

- **Availability:** iOS 14.0, iPadOS 14.0, Mac Catalyst 14.0, macOS 11.0, tvOS 14.0, visionOS 1.0, watchOS 7.0
- **Members:** automatic, principal, status, primaryAction, secondaryAction, confirmationAction, cancellationAction, destructiveAction, navigation, topBarLeading, topBarTrailing, topBarPinnedTrailing, bottomBar, bottomOrnament, keyboard, accessoryBar(id:), init(id:) [deprecated], navigationBarLeading [deprecated], navigationBarTrailing [deprecated], largeSubtitle, largeTitle, subtitle, title
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemplacement
- **Skill uses it correctly:** yes
- **Notes:** largeTitle and subtitle are iOS/iPadOS/Catalyst 26.0; title is 14.0. Only topBarPinnedTrailing is new in 27.

### `ToolbarItemPlacement.largeTitle`

```swift
static let largeTitle: ToolbarItemPlacement
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemplacement/largetitle
- **Skill uses it correctly:** yes
- **Notes:** iOS 26 API, absent from the skill. 'takes precedence over the value provided to the View.navigationTitle(_:) modifier.'

### `ToolbarItemPlacement.subtitle`

```swift
static let subtitle: ToolbarItemPlacement
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemplacement/subtitle
- **Skill uses it correctly:** yes
- **Notes:** iOS 26 API, absent from the skill.

### `View.toolbarMinimizationBehavior(_:for:)`

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** behavior, bars
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)
- **Skill uses it correctly:** yes
- **Notes:** New. Replaces the WWDC26 spelling toolbarMinimizeBehavior. Supported placement: navigationBar.

### `toolbarMinimizeBehavior(_:for:)`

```swift
NOT FOUND
```

- **Availability:** 
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizebehavior(_:for:)
- **Skill uses it correctly:** yes
- **Notes:** 404. Shown in WWDC26 session 269 code but replaced by toolbarMinimizationBehavior (release notes 177954148).

### `ToolbarMinimizationBehavior`

```swift
struct ToolbarMinimizationBehavior
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** automatic, never, onScrollDown, onScrollUp
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior
- **Skill uses it correctly:** yes
- **Notes:** automatic: nav bars minimize by default with searchable placement .toolbarPrincipal.

### `View.toolbarMinimizationRestoration(_:for:)`

```swift
nonisolated func toolbarMinimizationRestoration(_ restoration: ToolbarMinimizationRestoration, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** restoration, bars
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationrestoration(_:for:)
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page. Only navigationBar + onScrollDown.

### `ToolbarMinimizationRestoration`

```swift
struct ToolbarMinimizationRestoration
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** atScrollEdge, automatic
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarminimizationrestoration
- **Skill uses it correctly:** yes
- **Notes:** New.

### `View.toolbarMinimizationSafeAreaAdjustment(_:for:)`

```swift
nonisolated func toolbarMinimizationSafeAreaAdjustment(_ adjustment: ToolbarMinimizationSafeAreaAdjustment, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** adjustment, bars
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationsafeareaadjustment(_:for:)
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page. Only navigationBar.

### `ToolbarMinimizationSafeAreaAdjustment`

```swift
struct ToolbarMinimizationSafeAreaAdjustment
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** automatic, disabled, enabled
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarminimizationsafeareaadjustment
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ToolbarContent.contentMarginsRemoved(_:)`

```swift
nonisolated func contentMarginsRemoved(_ removed: Bool = true) -> some ToolbarContent
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** removed
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/contentmarginsremoved(_:)
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page.

### `ToolbarContent`

```swift
@MainActor @preconcurrency protocol ToolbarContent
```

- **Availability:** iOS 14.0, iPadOS 14.0, Mac Catalyst 14.0, macOS 11.0, tvOS 14.0, visionOS 1.0, watchOS 7.0
- **Members:** body, Body, axisBehavior(_:), hidden(_:), sharedBackgroundVisibility(_:), visibilityPriority(_:), matchedTransitionSource(id:in:), contentMarginsRemoved(_:)
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent
- **Skill uses it correctly:** NO
- **Notes:** The skill applies sharedBackgroundVisibility to a Button (View) instead of the ToolbarItem.

### `ToolbarContent.sharedBackgroundVisibility(_:)`

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0
- **Members:** visibility
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:)
- **Skill uses it correctly:** NO
- **Notes:** View.sharedBackgroundVisibility returns 404. The skill attaches it to a Button inside ToolbarItem, which is a compile risk.

### `ToolbarSpacer`

```swift
nonisolated struct ToolbarSpacer
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0
- **Members:** nonisolated init(_ sizing: SpacerSizing = .flexible, placement: ToolbarItemPlacement = .automatic)
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarspacer
- **Skill uses it correctly:** yes
- **Notes:** The skill's signature is correct. No tvOS, watchOS or visionOS. The HIG (iPhone Duo) prefers ToolbarItemGroup over manual fixed spacing.

### `DefaultToolbarItem`

```swift
nonisolated struct DefaultToolbarItem
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement)
- **Doc:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem
- **Skill uses it correctly:** NO
- **Notes:** Conforms to ToolbarContent. The skill nests it inside ToolbarItem (Content : View), which is a compile risk.

### `ToolbarDefaultItemKind`

```swift
struct ToolbarDefaultItemKind
```

- **Availability:** iOS 17.0, iPadOS 17.0, Mac Catalyst 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0
- **Members:** sidebarToggle, search, title
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbardefaultitemkind
- **Skill uses it correctly:** yes
- **Notes:** title is iOS 18.0. No changes in 27.

### `ToolbarItem`

```swift
nonisolated struct ToolbarItem<ID, Content> where Content : View
```

- **Availability:** iOS 14.0+ (type)
- **Members:** init(placement:content:), init(id:placement:content:), init(id:placement:showsByDefault:content:) [deprecated]
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritem
- **Skill uses it correctly:** yes
- **Notes:** Content must be a View. Used to verify the DefaultToolbarItem nesting issue.

### `ContentToolbarPlacement`

```swift
struct ContentToolbarPlacement
```

- **Availability:** iOS 18.4, iPadOS 18.4, Mac Catalyst 18.4, macOS 15.4, tvOS 18.4, visionOS 2.4, watchOS 11.4
- **Members:** tabViewSidebar
- **Doc:** https://developer.apple.com/documentation/swiftui/contenttoolbarplacement
- **Skill uses it correctly:** yes
- **Notes:** Not new. Used with contentToolbar(for:content:) for sidebarAdaptable TabView.

### `ToolbarPlacement.statusBar`

```swift
static var statusBar: ToolbarPlacement { get }
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarplacement/statusbar
- **Skill uses it correctly:** yes
- **Notes:** New. Works only with toolbarVisibility(_:for:) and toolbarColorScheme(_:for:).

### `TabRole`

```swift
struct TabRole
```

- **Availability:** iOS 18.0, iPadOS 18.0, Mac Catalyst 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, watchOS 11.0
- **Members:** prominent [27.0], search
- **Doc:** https://developer.apple.com/documentation/swiftui/tabrole
- **Skill uses it correctly:** yes
- **Notes:** The skill uses .search correctly; .prominent is absent.

### `TabRole.prominent`

```swift
static var prominent: TabRole { get }
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Doc:** https://developer.apple.com/documentation/swiftui/tabrole/prominent
- **Skill uses it correctly:** yes
- **Notes:** New. Only one prominent tab; .search gets the treatment if no explicit .prominent exists. Usage: Tab(role: .prominent) { CartTab() }.

### `NavigationTransition.crossFade`

```swift
static var crossFade: CrossFadeNavigationTransition { get }
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Doc:** https://developer.apple.com/documentation/swiftui/navigationtransition/crossfade
- **Skill uses it correctly:** yes
- **Notes:** New, no macOS. Applied inside the sheet content: .navigationTransition(.crossFade).

### `NavigationTransition`

```swift
protocol NavigationTransition
```

- **Availability:** iOS 18.0, iPadOS 18.0, Mac Catalyst 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, watchOS 11.0
- **Members:** automatic, AutomaticNavigationTransition, crossFade, CrossFadeNavigationTransition, zoom(sourceID:in:), ZoomNavigationTransition; conforming AnyNavigationTransition
- **Doc:** https://developer.apple.com/documentation/swiftui/navigationtransition
- **Skill uses it correctly:** yes
- **Notes:** The skill's .zoom usage is correct.

### `TabBarMinimizeBehavior`

```swift
struct TabBarMinimizeBehavior
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** automatic, never, onScrollDown, onScrollUp
- **Doc:** https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior
- **Skill uses it correctly:** yes
- **Notes:** The skill omits onScrollUp and the iPhone-only note. No changes in 27.

### `View.tabBarMinimizeBehavior(_:)`

```swift
nonisolated func tabBarMinimizeBehavior(_ behavior: TabBarMinimizeBehavior) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** behavior
- **Doc:** https://developer.apple.com/documentation/swiftui/view/tabbarminimizebehavior(_:)
- **Skill uses it correctly:** yes
- **Notes:** Unchanged.

### `View.tabViewBottomAccessory(content:)`

```swift
nonisolated func tabViewBottomAccessory<Content>(@ContentBuilder content: () -> Content) -> some View where Content : View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0
- **Members:** content
- **Doc:** https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(content:)
- **Skill uses it correctly:** yes
- **Notes:** iOS, iPadOS and Mac Catalyst only. Now printed with @ContentBuilder.

### `View.tabViewBottomAccessory(isEnabled:content:)`

```swift
nonisolated func tabViewBottomAccessory<Content>(isEnabled: Bool, @ContentBuilder content: () -> Content) -> some View where Content : View
```

- **Availability:** iOS 26.1, iPadOS 26.1, Mac Catalyst 26.1
- **Members:** isEnabled, content
- **Doc:** https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:)
- **Skill uses it correctly:** yes
- **Notes:** New in 26.1, absent from the skill.

### `TabViewBottomAccessoryPlacement`

```swift
enum TabViewBottomAccessoryPlacement
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** expanded, inline
- **Doc:** https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement
- **Skill uses it correctly:** NO
- **Notes:** The skill says .expanded | .collapsed; .collapsed does not exist.

### `EnvironmentValues.tabViewBottomAccessoryPlacement`

```swift
var tabViewBottomAccessoryPlacement: TabViewBottomAccessoryPlacement? { get }
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/tabviewbottomaccessoryplacement
- **Skill uses it correctly:** NO
- **Notes:** Optional; nil means an undefined placement. The skill treats it as non-optional.

### `TabSearchActivation`

```swift
struct TabSearchActivation
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** automatic, searchTabSelection
- **Doc:** https://developer.apple.com/documentation/swiftui/tabsearchactivation
- **Skill uses it correctly:** yes
- **Notes:** Used with tabViewSearchActivation(_:). No changes.

### `ContentBuilder`

```swift
typealias ContentBuilder = ViewBuilder
```

- **Availability:** iOS 13.0, iPadOS 13.0, Mac Catalyst 13.0, macOS 10.15, tvOS 13.0, visionOS 1.0, watchOS 6.0
- **Doc:** https://developer.apple.com/documentation/swiftui/contentbuilder
- **Skill uses it correctly:** yes
- **Notes:** Xcode 27. Unified replacement for ToolbarContentBuilder and CommandsBuilder; @ViewBuilder code still compiles.

### `State() macro`

```swift
@attached(accessor, names: named(init), named(get), named(set)) @attached(peer, names: prefixed(`_`), prefixed(__), prefixed(`$`)) macro State()
```

- **Availability:** iOS 13.0, iPadOS 13.0, Mac Catalyst 13.0, macOS 10.15, tvOS 13.0, visionOS 1.0, watchOS 6.0
- **Doc:** https://developer.apple.com/documentation/swiftui/state()
- **Skill uses it correctly:** yes
- **Notes:** Used when building with Xcode 27; the default value is created once; back-deploys to iOS 17-aligned OSes per release notes. No init-assigned @State found in the skill examples.

### `EnvironmentValues.toolbarVerticalEdge`

```swift
var toolbarVerticalEdge: HorizontalEdge? { get }
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarverticaledge
- **Skill uses it correctly:** yes
- **Notes:** New (iPhone Duo). nil where no vertical bar is ever used.

### `View.toolbarVerticalBehavior(_:)`

```swift
nonisolated func toolbarVerticalBehavior(_ behavior: ToolbarVerticalBehavior) -> some View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** behavior
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarverticalbehavior(_:)
- **Skill uses it correctly:** yes
- **Notes:** New. Example: TabView { … }.toolbarVerticalBehavior(.disabled).

### `ToolbarVerticalBehavior`

```swift
struct ToolbarVerticalBehavior
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** automatic, disabled
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarverticalbehavior
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ToolbarItemAxisBehavior`

```swift
struct ToolbarItemAxisBehavior
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** automatic, horizontalOnly, verticalPreferred
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemaxisbehavior
- **Skill uses it correctly:** yes
- **Notes:** New. horizontalOnly items are hidden when no horizontal bar exists.

### `ToolbarContent.axisBehavior(_:)`

```swift
nonisolated func axisBehavior(_ behavior: ToolbarItemAxisBehavior) -> some ToolbarContent
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** behavior
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/axisbehavior(_:)
- **Skill uses it correctly:** yes
- **Notes:** New. Example: ToolbarItem(placement: .primaryAction) { Toggle(…) }.axisBehavior(.horizontalOnly).

### `CustomizableToolbarContent.axisBehavior(_:)`

```swift
nonisolated func axisBehavior(_ behavior: ToolbarItemAxisBehavior) -> some CustomizableToolbarContent
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** behavior
- **Doc:** https://developer.apple.com/documentation/swiftui/customizabletoolbarcontent/axisbehavior(_:)
- **Skill uses it correctly:** yes
- **Notes:** New.

### `View.toolbarVerticalCompressionBehavior(_:)`

```swift
nonisolated func toolbarVerticalCompressionBehavior(_ behavior: ToolbarVerticalCompressionBehavior) -> some View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** behavior
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarverticalcompressionbehavior(_:)
- **Skill uses it correctly:** yes
- **Notes:** New. Example: .toolbarVerticalCompressionBehavior(.prefersToolbarItems).

### `ToolbarVerticalCompressionBehavior`

```swift
struct ToolbarVerticalCompressionBehavior
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** automatic, prefersTabBar, prefersToolbarItems
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarverticalcompressionbehavior
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ArrangementView`

```swift
nonisolated struct ArrangementView<Primary, Secondary> where Primary : View, Secondary : View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** init(primary:secondary:), init(_: ArrangementViewStyleConfiguration), arrangementViewStyle(_:)
- **Doc:** https://developer.apple.com/documentation/swiftui/arrangementview
- **Skill uses it correctly:** yes
- **Notes:** New. Default style resolves to split.

### `ArrangementViewStyle`

```swift
@MainActor @preconcurrency protocol ArrangementViewStyle
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** automatic, overlay, split, makeBody(configuration:), Body, Configuration, AutomaticArrangementViewStyle, OverlayArrangementViewStyle, SplitArrangementViewStyle
- **Doc:** https://developer.apple.com/documentation/swiftui/arrangementviewstyle
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ArrangementViewStyleConfiguration`

```swift
struct ArrangementViewStyleConfiguration
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** Primary, Secondary, primary, secondary
- **Doc:** https://developer.apple.com/documentation/swiftui/arrangementviewstyleconfiguration
- **Skill uses it correctly:** yes
- **Notes:** New.

### `SplitArrangementViewStyle.axes(_:)`

```swift
nonisolated func axes(_ axes: Axis.Set) -> SplitArrangementViewStyle
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** axes
- **Doc:** https://developer.apple.com/documentation/swiftui/splitarrangementviewstyle/axes(_:)
- **Skill uses it correctly:** yes
- **Notes:** Example: .arrangementViewStyle(.split.axes(.vertical)).

### `OverlayArrangementViewStyle.axes(_:)`

```swift
nonisolated func axes(_ axes: Axis.Set) -> OverlayArrangementViewStyle
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** axes
- **Doc:** https://developer.apple.com/documentation/swiftui/overlayarrangementviewstyle/axes(_:)
- **Skill uses it correctly:** yes
- **Notes:** New.

### `View.overlayArrangementEdge(_:)`

```swift
nonisolated func overlayArrangementEdge(_ edge: HorizontalEdge?) -> some View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** edge
- **Doc:** https://developer.apple.com/documentation/swiftui/view/overlayarrangementedge(_:)
- **Skill uses it correctly:** yes
- **Notes:** New.

### `View.splitArrangementLayoutRatio(_:)`

```swift
nonisolated func splitArrangementLayoutRatio(_ ratio: CGFloat?) -> some View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** ratio
- **Doc:** https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutratio(_:)
- **Skill uses it correctly:** yes
- **Notes:** New. A min/ideal/max overload also exists.

### `View.splitArrangementLayoutSize(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:)`

```swift
nonisolated func splitArrangementLayoutSize(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) -> some View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** minWidth, idealWidth, maxWidth, minHeight, idealHeight, maxHeight
- **Doc:** https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutsize(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:)
- **Skill uses it correctly:** yes
- **Notes:** New.

### `View.splitArrangementFixedLayoutSize(horizontal:vertical:)`

```swift
nonisolated func splitArrangementFixedLayoutSize(horizontal: Bool = true, vertical: Bool = true) -> some View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** horizontal, vertical
- **Doc:** https://developer.apple.com/documentation/swiftui/view/splitarrangementfixedlayoutsize(horizontal:vertical:)
- **Skill uses it correctly:** yes
- **Notes:** New.

### `EnvironmentValues.splitArrangementAxis`

```swift
var splitArrangementAxis: Axis? { get set }
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/splitarrangementaxis
- **Skill uses it correctly:** yes
- **Notes:** New.

### `EnvironmentValues.overlayArrangementZIndex`

```swift
var overlayArrangementZIndex: Int { get set }
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/overlayarrangementzindex
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ReservedRegion`

```swift
struct ReservedRegion
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** id, ReservedRegion.ID, frame, isActive, kind, ReservedRegion.Kind, margins, ReservedRegion.QueryOptions
- **Doc:** https://developer.apple.com/documentation/swiftui/reservedregion
- **Skill uses it correctly:** yes
- **Notes:** New.

### `GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)`

```swift
func reservedRegions(kind: ReservedRegion.Kind, options: ReservedRegion.QueryOptions = [], layoutDirectionBehavior: LayoutDirectionBehavior = .mirrors) -> [ReservedRegion]
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** kind, options, layoutDirectionBehavior
- **Doc:** https://developer.apple.com/documentation/swiftui/geometryproxy/reservedregions(kind:options:layoutdirectionbehavior:)
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ReservedRegion.Kind`

```swift
struct Kind
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** division, occlusion
- **Doc:** https://developer.apple.com/documentation/swiftui/reservedregion/kind-swift.struct
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ReservedRegion.QueryOptions`

```swift
@frozen struct QueryOptions
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** includeInactive
- **Doc:** https://developer.apple.com/documentation/swiftui/reservedregion/queryoptions
- **Skill uses it correctly:** yes
- **Notes:** New.

### `View.onHingeChange(isEnabled:_:)`

```swift
nonisolated func onHingeChange(isEnabled: Bool = true, _ action: @escaping (DeviceHingeContext, DeviceHingeContext) -> Void) -> some View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** isEnabled, action
- **Doc:** https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)
- **Skill uses it correctly:** yes
- **Notes:** New (iPhone Duo).

### `DeviceHinge`

```swift
struct DeviceHinge
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** angle, status, DeviceHinge.Status
- **Doc:** https://developer.apple.com/documentation/swiftui/devicehinge
- **Skill uses it correctly:** yes
- **Notes:** New.

### `DeviceHinge.Status`

```swift
struct Status
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** closed, fullyOpen, partiallyOpen
- **Doc:** https://developer.apple.com/documentation/swiftui/devicehinge/status-swift.struct
- **Skill uses it correctly:** yes
- **Notes:** New.

### `DeviceHingeContext`

```swift
struct DeviceHingeContext
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** hinge
- **Doc:** https://developer.apple.com/documentation/swiftui/devicehingecontext
- **Skill uses it correctly:** yes
- **Notes:** New.

### `CameraCaptureAccessory`

```swift
nonisolated struct CameraCaptureAccessory<Content> where Content : View
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta)
- **Members:** init(content:), init(isEnabled: Binding<Bool>, content:)
- **Doc:** https://developer.apple.com/documentation/swiftui/cameracaptureaccessory
- **Skill uses it correctly:** yes
- **Notes:** New; out of scope for glass.

### `View.sceneAccessory(content:)`

```swift
nonisolated func sceneAccessory<C>(@ContentBuilder content: () -> C) -> some View where C : SceneAccessoryContent
```

- **Availability:** iOS 27.0, iPadOS 27.0
- **Members:** content
- **Doc:** https://developer.apple.com/documentation/swiftui/view/sceneaccessory(content:)
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page; out of scope for glass.

### `ExternalNonInteractiveAccessory`

```swift
nonisolated struct ExternalNonInteractiveAccessory<Content> where Content : View
```

- **Availability:** iOS 27.0, iPadOS 27.0
- **Members:** init(content:), init(isEnabled:content:)
- **Doc:** https://developer.apple.com/documentation/swiftui/externalnoninteractiveaccessory
- **Skill uses it correctly:** yes
- **Notes:** New; out of scope.

### `View.presentationPlacement(_:)`

```swift
nonisolated func presentationPlacement(_ placement: PresentationPlacement) -> some View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** placement
- **Doc:** https://developer.apple.com/documentation/swiftui/view/presentationplacement(_:)
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page. Only sheets respect it.

### `PresentationPlacement`

```swift
struct PresentationPlacement
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** automatic, center, leading, trailing
- **Doc:** https://developer.apple.com/documentation/swiftui/presentationplacement
- **Skill uses it correctly:** yes
- **Notes:** New.

### `TabsPickerStyle`

```swift
struct TabsPickerStyle
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0
- **Members:** init(); PickerStyle.tabs
- **Doc:** https://developer.apple.com/documentation/swiftui/tabspickerstyle
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page. Looks like .segmented on iOS; VoiceOver reads it as tabs.

### `View.textInputBorderShape(_:)`

```swift
nonisolated func textInputBorderShape(_ shape: TextInputBorderShape) -> some View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** shape
- **Doc:** https://developer.apple.com/documentation/swiftui/view/textinputbordershape(_:)
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page.

### `TextInputBorderShape`

```swift
struct TextInputBorderShape
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** automatic, capsule, roundedRectangle
- **Doc:** https://developer.apple.com/documentation/swiftui/textinputbordershape
- **Skill uses it correctly:** yes
- **Notes:** New.

### `TextFieldStyle.bordered`

```swift
@export(implementation) static var bordered: BorderedTextFieldStyle { get }
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Doc:** https://developer.apple.com/documentation/swiftui/textfieldstyle/bordered
- **Skill uses it correctly:** yes
- **Notes:** New.

### `TextFieldStyle.roundedBorder`

```swift
@export(implementation) static var roundedBorder: RoundedBorderTextFieldStyle { get }
```

- **Availability:** iOS 13.0 (deprecatedAt 27.2), iPadOS 13.0 (deprecatedAt 27.2), Mac Catalyst 13.0 (deprecatedAt 27.2), macOS 10.15 (deprecatedAt 27.2), visionOS 1.0
- **Doc:** https://developer.apple.com/documentation/swiftui/textfieldstyle/roundedborder
- **Skill uses it correctly:** yes
- **Notes:** Soft-deprecated: 'Use `textFieldStyle(.bordered)` with `textInputBorderShape(.roundedRectangle)`'. squareBorder is also deprecated. Not used by the skill.

### `GeometryProxy.concentricCornerRadii`

```swift
var concentricCornerRadii: RectangleCornerRadii? { get }
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Doc:** https://developer.apple.com/documentation/swiftui/geometryproxy/concentriccornerradii
- **Skill uses it correctly:** yes
- **Notes:** New and not on the Updates page (release notes 177185166).

### `GeometryProxy.concentricCornerRadii(in:)`

```swift
func concentricCornerRadii(in frame: CGRect) -> RectangleCornerRadii?
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** frame
- **Doc:** https://developer.apple.com/documentation/swiftui/geometryproxy/concentriccornerradii(in:)
- **Skill uses it correctly:** yes
- **Notes:** New.

### `ConcentricRectangle`

```swift
struct ConcentricRectangle
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** init(), init(corners:isUniform:), init(topLeadingCorner:topTrailingCorner:bottomLeadingCorner:bottomTrailingCorner:), init(uniformBottomCorners:topLeadingCorner:topTrailingCorner:), init(uniformLeadingCorners:topTrailingCorner:bottomTrailingCorner:), init(uniformLeadingCorners:uniformTrailingCorners:), init(uniformTopCorners:bottomLeadingCorner:bottomTrailingCorner:), init(uniformTopCorners:uniformBottomCorners:), init(uniformTrailingCorners:topLeadingCorner:bottomLeadingCorner:)
- **Doc:** https://developer.apple.com/documentation/swiftui/concentricrectangle
- **Skill uses it correctly:** NO
- **Notes:** The skill never uses it and instead uses a nonexistent `.containerConcentric`.

### `Edge.Corner.Style`

```swift
struct Style
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** concentric, concentric(minimum:), fixed(_:)
- **Doc:** https://developer.apple.com/documentation/swiftui/edge/corner/style
- **Skill uses it correctly:** NO
- **Notes:** 'containerConcentric' does not appear anywhere in it.

### `.containerConcentric`

```swift
NOT FOUND
```

- **Availability:** 
- **Doc:** https://developer.apple.com/documentation/swiftui/concentricrectangle
- **Skill uses it correctly:** NO
- **Notes:** Used throughout the skill as .rect(cornerRadius: .containerConcentric); not found in the docs.

### `View.scrollExtensionMode(_:)`

```swift
NOT FOUND
```

- **Availability:** 
- **Doc:** https://developer.apple.com/documentation/swiftui/view/scrollextensionmode(_:)
- **Skill uses it correctly:** NO
- **Notes:** 404. Used at 01-api-reference.md:516-519.

### `SearchFieldPlacement.toolbarPrincipal`

```swift
static var toolbarPrincipal: SearchFieldPlacement { get }
```

- **Availability:** iOS 15.0, iPadOS 15.0, Mac Catalyst 15.0, macOS 12.0, visionOS 1.0
- **Doc:** https://developer.apple.com/documentation/swiftui/searchfieldplacement/toolbarprincipal
- **Skill uses it correctly:** yes
- **Notes:** In iOS 27, nav bars auto-minimize when searchable uses this placement (ToolbarMinimizationBehavior.automatic).

### `SearchToolbarBehavior`

```swift
struct SearchToolbarBehavior
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** automatic, minimize
- **Doc:** https://developer.apple.com/documentation/swiftui/searchtoolbarbehavior
- **Skill uses it correctly:** yes
- **Notes:** The skill's .minimize is correct; Apple's own example misspells it as .minimized. No changes in 27.

### `View.searchToolbarBehavior(_:)`

```swift
nonisolated func searchToolbarBehavior(_ behavior: SearchToolbarBehavior) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** behavior
- **Doc:** https://developer.apple.com/documentation/swiftui/view/searchtoolbarbehavior(_:)
- **Skill uses it correctly:** yes
- **Notes:** Unchanged.

### `ScrollEdgeEffectStyle`

```swift
struct ScrollEdgeEffectStyle
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** automatic, hard, soft
- **Doc:** https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle
- **Skill uses it correctly:** yes
- **Notes:** Unchanged in 27.

### `View.scrollEdgeEffectStyle(_:for:)`

```swift
nonisolated func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** style, edges
- **Doc:** https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:)
- **Skill uses it correctly:** yes
- **Notes:** Unchanged.

### `View.scrollEdgeEffectHidden(_:for:)`

```swift
nonisolated func scrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Members:** hidden, edges
- **Doc:** https://developer.apple.com/documentation/swiftui/view/scrolledgeeffecthidden(_:for:)
- **Skill uses it correctly:** yes
- **Notes:** Unchanged.

### `View.safeAreaBar(edge:alignment:spacing:content:)`

```swift
nonisolated func safeAreaBar(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content: () -> some View) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** edge, alignment, spacing, content (VerticalEdge overload also exists)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:)
- **Skill uses it correctly:** yes
- **Notes:** 26.1 known issue: @FocusState doesn't work in safeAreaBar. The skill uses safeAreaInset for floating glass toolbars; safeAreaBar also extends scroll edge effects.

### `View.backgroundExtensionEffect() / backgroundExtensionEffect(isEnabled:)`

```swift
@MainActor @preconcurrency func backgroundExtensionEffect() -> some View  |  @MainActor @preconcurrency func backgroundExtensionEffect(isEnabled: Bool) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** isEnabled
- **Doc:** https://developer.apple.com/documentation/swiftui/view/backgroundextensioneffect()
- **Skill uses it correctly:** yes
- **Notes:** The isEnabled overload (26.0) is absent from the skill. Note: it clips the view.

### `View.swipeActions(edge:allowsFullSwipe:content:onPresentationChanged:)`

```swift
nonisolated func swipeActions(edge: HorizontalEdge = .trailing, allowsFullSwipe: Bool = true, @ContentBuilder content: () -> some View, onPresentationChanged: @escaping (Bool) -> Void) -> some View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** edge, allowsFullSwipe, content, onPresentationChanged
- **Doc:** https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:onpresentationchanged:)
- **Skill uses it correctly:** yes
- **Notes:** New.

### `View.swipeActionsContainer()`

```swift
nonisolated func swipeActionsContainer() -> some View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0
- **Doc:** https://developer.apple.com/documentation/swiftui/view/swipeactionscontainer()
- **Skill uses it correctly:** yes
- **Notes:** New. A no-op on List.

### `View.alert(_:item:actions:)`

```swift
@export(implementation) nonisolated func alert<A, T>(_ title: Text, item data: Binding<T?>, @ContentBuilder actions: (T) -> A) -> some View where A : View
```

- **Availability:** iOS 15.0, iPadOS 15.0, Mac Catalyst 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0
- **Members:** title, data, actions (plus alert(_:item:actions:message:), alert(error:actions:), alert(error:actions:message:))
- **Doc:** https://developer.apple.com/documentation/swiftui/view/alert(_:item:actions:)
- **Skill uses it correctly:** yes
- **Notes:** New in the Xcode 27 SDK; back-deploys to iOS 15.

### `View.confirmationDialog(_:item:titleVisibility:actions:)`

```swift
@export(implementation) nonisolated func confirmationDialog<A, T>(_ title: Text, item data: Binding<T?>, titleVisibility: Visibility = .automatic, @ContentBuilder actions: (T) -> A) -> some View where A : View
```

- **Availability:** iOS 15.0, iPadOS 15.0, Mac Catalyst 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0
- **Members:** title, data, titleVisibility, actions (plus ...:message: overload)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:item:titlevisibility:actions:)
- **Skill uses it correctly:** yes
- **Notes:** New in the Xcode 27 SDK; back-deploys.

### `View.reorderContainer(for:isEnabled:move:)`

```swift
nonisolated func reorderContainer<Item>(for item: Item.Type, isEnabled: Bool = true, move: @escaping (ReorderDifference<Item.ID, ReorderableSingleCollectionIdentifier>) -> ()) -> some View where Item : Identifiable, Item.ID : Sendable
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0
- **Members:** item, isEnabled, move
- **Doc:** https://developer.apple.com/documentation/swiftui/view/reordercontainer(for:isenabled:move:)
- **Skill uses it correctly:** yes
- **Notes:** New; low relevance to glass.

### `DynamicViewContent.reorderable()`

```swift
nonisolated func reorderable() -> some DynamicViewContent<Self.Data>
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0
- **Doc:** https://developer.apple.com/documentation/swiftui/dynamicviewcontent/reorderable()
- **Skill uses it correctly:** yes
- **Notes:** New; low relevance.

### `EnvironmentValues.appearsActive`

```swift
@backDeployed(before: macOS 15.0) var appearsActive: Bool { get set }
```

- **Availability:** iOS 18.0, iPadOS 18.0, Mac Catalyst 18.0, macOS 10.15, tvOS 18.0, visionOS 2.0, watchOS 11.0
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/appearsactive
- **Skill uses it correctly:** yes
- **Notes:** The docs still say 'On all other platforms, this value is always true', but WWDC26 shows iPadOS 27 inactive-window dimming using appearsActive. Bridged to UITraitCollection.activeAppearance.

### `EnvironmentValues.buttonSizing`

```swift
var buttonSizing: ButtonSizing { get }
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** ButtonSizing: flexible, fitted (from example)
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/buttonsizing
- **Skill uses it correctly:** yes
- **Notes:** Reset to default inside sheets and popovers with the 27 SDK, along with controlSize and ButtonBorderShape.

### `ButtonRole`

```swift
struct ButtonRole
```

- **Availability:** iOS 15.0, iPadOS 15.0, Mac Catalyst 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0
- **Members:** cancel, destructive, close, confirm
- **Doc:** https://developer.apple.com/documentation/swiftui/buttonrole
- **Skill uses it correctly:** yes
- **Notes:** No 27 additions found. close and confirm are the iOS 26 roles.

