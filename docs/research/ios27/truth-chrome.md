# truth-chrome

_Phase: Research_

## Summary

Read-only audit of the skill's toolbar, tab, search, sheet and transition APIs, checked against Apple DocC JSON, the WWDC25-323 and WWDC26-269 transcripts, HIG Search fields and the Adopting Liquid Glass page.

Four code samples will not compile or are wrong:
(1) `.sharedBackgroundVisibility(.hidden)` is put on a Button. It exists only on ToolbarContent, and the View version returns 404 (01-api-reference.md:349).
(2) `DefaultToolbarItem` is wrapped inside `ToolbarItem { }`. It is ToolbarContent, not a View (01-api-reference.md:421, glass-search-field.md:59).
(3) The bottom-accessory placement cases are given as `.expanded | .collapsed`. The real cases are `expanded` and `inline`, and the environment value is Optional (01-api-reference.md:396).
(4) The tab-bar pattern says the `.search` tab puts the search field at the top of the screen. Apple says the search field takes the place of the tab bar (glass-tab-bar.md:85).

Sheet guidance is wrong in three places:
- `presentationBackground(.clear)` does not "show glass". It replaces the system Liquid Glass sheet background, and Apple says to remove custom presentation backgrounds.
- The "doesn't dim" sample uses detents `[.large]` with `.enabled(upThrough: .medium)`, which contradicts its own title.
- `scrollContentBackground(.hidden)` is applied to a ScrollView, which has no system background on iOS.

Two calls the skill uses are now marked for rename in Apple's metadata (deprecatedAt 27.2):
- `toolbarBackground(.hidden, for:)` → `toolbarBackgroundVisibility(_:for:)`
- `toolbar(.hidden, for:)` → `toolbarVisibility(_:for:)`

The search pattern says the field "lives in the nav bar", but on iPhone toolbar search sits at the bottom of the screen.

The frontmatter claims watchOS, tvOS and visionOS, but several APIs the skill teaches are not available there:
- ToolbarSpacer, SpacerSizing and sharedBackgroundVisibility: iOS, iPadOS, Mac Catalyst and macOS only.
- tabViewBottomAccessory: iOS, iPadOS and Mac Catalyst only.
- Tab-bar minimizing: iPhone only.

The skill has no iOS 27 content. Missing APIs:
- `ToolbarContent.visibilityPriority(_:)`
- `ToolbarOverflowMenu` and `View.toolbarOverflowMenu`
- `ToolbarItemPlacement.topBarPinnedTrailing`
- `View.toolbarMinimizationBehavior(_:for:)` and `ToolbarMinimizationBehavior`. The WWDC26 video spells it `toolbarMinimizeBehavior`, which returns 404 in the docs.
- `TabRole.prominent`
- `NavigationTransition.crossFade` for sheets
- The ContentBuilder unification (Xcode 27, TN3211)

Missing 26.x APIs:
- `tabViewBottomAccessory(isEnabled:content:)` (26.1)
- `ToolbarContent.hidden(_:)` (26.4)
- `ToolbarContent.matchedTransitionSource(id:in:)` (26.0)
- `tabViewSearchActivation` (26.0)

Verified correct as written:
- ToolbarSpacer's signature
- `searchToolbarBehavior(.minimize)` (Apple's own sample says `.minimized`, but the type's member is `minimize`)
- `searchable(text:prompt:)`
- `tabBarMinimizeBehavior`
- `Tab(_:systemImage:role:content:)`
- `presentationDetents` and `presentationBackgroundInteraction(.enabled(upThrough:))`
- `matchedTransitionSource` and `navigationTransition(.zoom)` on sheet content (Apple's docs allow it inside a sheet)
- the `symbolEffect` and `contentTransition(.symbolEffect(.replace))` forms
- `.badge` on toolbar-item content

## Findings (28)

### 0. `wrong-signature` — `.sharedBackgroundVisibility(.hidden)` is applied to the Button inside `ToolbarItem { ... }`.  
_references/01-api-reference.md:349_

- **Correct / new info:** sharedBackgroundVisibility(_:) exists only on ToolbarContent. It is applied to the ToolbarItem, after its closing brace. There is no View overload: developer.apple.com/tutorials/data/documentation/swiftui/view/sharedbackgroundvisibility(_:).json returns 404. Calling it on a Button does not compile. Apple's sample: `ToolbarItem(placement: principal) { BuildStatus() }.sharedBackgroundVisibility(.hidden)`. Hiding the background places the item in its own grouping.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+ (no tvOS/visionOS/watchOS)
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:) (apple-doc, confidence high)
- **Action:** Rewrite the sample as `ToolbarItem { Button("Profile", systemImage: "person.crop.circle") { } }\n.sharedBackgroundVisibility(.hidden)`. Add a note that this is a ToolbarContent modifier and must never go on a View.

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
```

### 1. `wrong-signature` — Search is pinned to a toolbar placement by nesting `DefaultToolbarItem(kind: .search, placement: .bottomBar)` inside `ToolbarItem(placement: .bottomBar) { ... }`.  
_references/01-api-reference.md:421_

- **Correct / new info:** DefaultToolbarItem conforms to ToolbarContent, not View. Its init returns "A ToolbarItem with content provided by the kind". ToolbarItem's content closure requires `Content : View`, so nesting it does not compile. Apple's samples (DocC and WWDC25-323) put it directly in the toolbar builder: `.toolbar { ToolbarItem(placement: .bottomBar) { CalendarPicker() } ... DefaultToolbarItem(kind: .search, placement: .bottomBar); ToolbarSpacer(placement: .bottomBar) ... }`. It repositions the system search item; it does not create a new one.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem/init(kind:placement:) (apple-doc, confidence high)
- **Action:** Replace with `.toolbar { DefaultToolbarItem(kind: .search, placement: .bottomBar) }`. Optionally show it combined with ToolbarSpacer and other bottomBar items, as in Apple's sample.

```swift
nonisolated init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)
```

### 2. `wrong-signature` — Variation 'Search field in the bottom toolbar' wraps `DefaultToolbarItem(kind: .search, placement: .bottomBar)` inside `ToolbarItem(placement: .bottomBar) { }`.  
_patterns/glass-search-field.md:59_

- **Correct / new info:** This is the same compile error as in 01-api-reference.md. DefaultToolbarItem is ToolbarContent and must be a direct child of `.toolbar { }`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem (apple-doc, confidence high)
- **Action:** Change the snippet to `.toolbar { DefaultToolbarItem(kind: .search, placement: .bottomBar) }` followed by `.searchable(text: $query)`.

```swift
nonisolated struct DefaultToolbarItem (Conforms To: ToolbarContent)
```

### 3. `factually-wrong` — Inside the accessory, `@Environment(\.tabViewBottomAccessoryPlacement) var placement` takes the values `.expanded | .collapsed`.  
_references/01-api-reference.md:396_

- **Correct / new info:** TabViewBottomAccessoryPlacement is an enum with exactly two cases: `case expanded` ("The bar is expanded on top of the bottom tab bar...") and `case inline` ("The view is displayed in line with the bottom tab bar."). There is no `.collapsed`, so `placement == .collapsed` does not compile. The environment value is Optional (`var tabViewBottomAccessoryPlacement: TabViewBottomAccessoryPlacement? { get }`). The docs say "A nil value corresponds to an undefined placement." Apple's WWDC25 sample checks `if placement == .inline { compact } else { full }`.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement (apple-doc, confidence high)
- **Action:** Change the comment to `// .expanded | .inline (Optional — nil = undefined)` and show a switch or if on `.inline`.

```swift
enum TabViewBottomAccessoryPlacement { case expanded; case inline }
```

### 4. `inconsistency` — "Inside the accessory, react to whether it's expanded or collapsed"  
_patterns/glass-tab-bar.md:44_

- **Correct / new info:** The placement values are `.expanded` and `.inline`. On iPhone, when the tab bar collapses, the accessory displays inline. The code below the sentence (`placement == .expanded`) compiles, because Optional is compared to a case, but the wording teaches a nonexistent `.collapsed` case.
- **Availability:** iOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/environmentvalues/tabviewbottomaccessoryplacement (apple-doc, confidence high)
- **Action:** Reword to "expanded or inline (when the tab bar minimizes)". Optionally branch on `.inline`, as Apple does.

```swift
var tabViewBottomAccessoryPlacement: TabViewBottomAccessoryPlacement? { get }
```

### 5. `factually-wrong` — "The `role: .search` tab is special: it surfaces the system search field at the top of the screen automatically."  
_patterns/glass-tab-bar.md:85_

- **Correct / new info:** The SwiftUI updates page (June 2025) says: "Set the search role on a tab to take someone to a search tab and have a search field take the place of the tab bar." WWDC25-323 says: "When someone selects this tab, a search field takes the place of the tab bar, and the content of the tab is shown." Adopting Liquid Glass says the system separates the search tab and places it at the trailing end. TabRole.search docs: "Searchable tab views will prefer to have the first tab with this role implement search." The HIG (updated June 8, 2026) describes two search-tab styles: a 'Standard tab' that leads to a landing page with the field at the top, and a 'Button appearance'.
- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence high)
- **Action:** Replace with: "On iPhone, selecting the `.search` tab replaces the tab bar with the search field at the bottom; the tab sits separated at the trailing end. Put `.searchable` on the TabView." Mention `Tab(role: .search) { ... }` (system label) and `tabViewSearchActivation(.searchTabSelection)`.

```swift
static var search: TabRole { get }
```

### 6. `factually-wrong` — "When the search tab is active, the search field automatically takes prominence in the nav layer."  
_patterns/glass-search-field.md:79_

- **Correct / new info:** Per Apple, the search field takes the place of the tab bar at the bottom on iPhone, not "in the nav layer". In iOS 27, the TabRole.prominent docs add: "When there are no tabs with an explicit .prominent role, then a .search role tab may receive the prominent visual treatment by default."
- **Availability:** iOS 18.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabrole/prominent (apple-doc, confidence medium)
- **Action:** Reword to match Apple: the search field replaces the tab bar. Add an iOS 27 note about prominent treatment of the search tab.

```swift
static var search: TabRole { get }
```

### 7. `factually-wrong` — `.presentationBackground(.clear)  // glass shows full background`  
_patterns/glass-modal-sheet.md:85_

- **Correct / new info:** In iOS 26, sheets get a system Liquid Glass background. WWDC25-323: "On iOS 26, partial height sheets are inset by default with a Liquid Glass background... If you’ve used the presentationBackground modifier to apply a custom background to your sheets, consider removing that and let the new material shine." presentationBackground(_:) sets the sheet background to the given ShapeStyle and "Automatically fills the entire presentation". With `.clear` the sheet has no glass at all: content floats over the presenter with no material, which hurts legibility.
- **Availability:** iOS 16.4+, iPadOS 16.4+, Mac Catalyst 16.4+, macOS 13.3+, tvOS 16.4+, visionOS 1.0+, watchOS 9.4+
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence high)
- **Action:** Remove `.presentationBackground(.clear)` from the glass sheet pattern. Add a gotcha: "Don't set presentationBackground on iOS 26+ sheets — it replaces the system Liquid Glass background."

```swift
nonisolated func presentationBackground<S>(_ style: S) -> some View where S : ShapeStyle
```

### 8. `bad-practice` — 'Tall sheet that doesn't dim background': `.presentationDetents([.large])` + `.presentationBackgroundInteraction(.enabled(upThrough: .medium))`.  
_patterns/glass-modal-sheet.md:84_

- **Correct / new info:** `.enabled(upThrough:)` means "People can interact with the view behind a presentation up through a specified detent." The only detent offered is `.large`, so the sheet never sits at or below `.medium`. Background interaction therefore stays disabled and the presenter stays dimmed, the opposite of the heading. Apple's sample lists the threshold detent in the set: `.presentationDetents([.height(120), .medium, .large]).presentationBackgroundInteraction(.enabled(upThrough: .height(120)))`.
- **Availability:** iOS 16.4+, iPadOS 16.4+, Mac Catalyst 16.4+, macOS 13.3+, tvOS 16.4+, visionOS 1.0+, watchOS 9.4+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/presentationbackgroundinteraction(_:) (apple-doc, confidence high)
- **Action:** Change to `.presentationDetents([.medium, .large]).presentationBackgroundInteraction(.enabled(upThrough: .medium))` and retitle to 'Sheet that keeps the background interactive at medium height'. Drop the clear background.

```swift
static func enabled(upThrough: PresentationDetent) -> PresentationBackgroundInteraction
```

### 9. `factually-wrong` — `ScrollView { ... }.scrollContentBackground(.hidden)` "so glass shows through scrollables" (also stated at line 60 and in 01-api-reference.md:438).  
_patterns/glass-modal-sheet.md:42_

- **Correct / new info:** scrollContentBackground(_:) "Specifies the visibility of the background for scrollable views within this view". Apple's example hides "the standard system background of the List". On iOS, List and Form (and TextEditor) have an opaque system background. A plain ScrollView has none, so the modifier does nothing on the pattern's ScrollView. The modifier is not available on tvOS.
- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, visionOS 1.0+, watchOS 9.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/scrollcontentbackground(_:) (apple-doc, confidence medium)
- **Action:** Say that `.scrollContentBackground(.hidden)` is for List, Form and TextEditor. Remove it from the ScrollView sample, or switch the sample to a List.

```swift
nonisolated func scrollContentBackground(_ visibility: Visibility) -> some View
```

### 10. `unverifiable-claim` — `.containerBackground(.clear, for: .navigation)` on sheet content (InfoView); glass-modal-sheet.md:98 says it "lets the nav-bar glass blend with the sheet's glass behind it".  
_references/01-api-reference.md:439_

- **Correct / new info:** ContainerBackgroundPlacement.navigation is "A background placement inside a NavigationStack or NavigationSplitView". The modifier must be applied to a view inside the NavigationStack, as in Apple's example on the NavigationLink destination content. In the snippet, InfoView has no visible NavigationStack, so the effect depends on InfoView's internals. Apple docs say nothing about blending nav-bar glass with sheet glass. The `.navigation` placement is iOS/iPadOS/Mac Catalyst 18.0 and watchOS 10.0 only.
- **Availability:** containerBackground: iOS 17.0+; .navigation: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, watchOS 10.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/containerbackgroundplacement/navigation (apple-doc, confidence medium)
- **Action:** Show it applied inside the sheet's NavigationStack root, or remove it. Delete the 'blend nav-bar glass with sheet glass' claim, or mark it as untested.

```swift
nonisolated func containerBackground<S>(_ style: S, for container: ContainerBackgroundPlacement) -> some View where S : ShapeStyle; static let navigation: ContainerBackgroundPlacement
```

### 11. `deprecated` — "For a full-bleed image (no nav bar background), use `.toolbarBackground(.hidden, for: .navigationBar)`"  
_patterns/glass-navigation-bar.md:59_

- **Correct / new info:** The Visibility overload of toolbarBackground(_:for:) carries Apple doc metadata `"deprecatedAt":"27.2","renamed":"toolbarBackgroundVisibility(_:for:)"` on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS. The `deprecated` flag is still false; 27.2 appears to be the current beta. The replacement has existed since iOS 18. The claim that items "still float as glass shapes individually" is not in Apple docs.
- **Availability:** toolbarBackgroundVisibility: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+; old overload deprecatedAt 27.2
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarbackground(_:for:)-7lv0f (apple-doc, confidence high)
- **Action:** Replace with `.toolbarBackgroundVisibility(.hidden, for: .navigationBar)`. Drop or soften the 'float individually' claim.

```swift
nonisolated func toolbarBackgroundVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

### 12. `deprecated` — `.toolbar(.hidden, for: .tabBar)   // hides only within this stack`  
_patterns/glass-tab-bar.md:79_

- **Correct / new info:** toolbar(_:for:) (Visibility) carries Apple doc metadata `"deprecatedAt":"27.2","renamed":"toolbarVisibility(_:for:)"` on every platform except visionOS. The replacement `toolbarVisibility(_:for:)` has existed since iOS 18.0.
- **Availability:** toolbarVisibility: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbar(_:for:) (apple-doc, confidence high)
- **Action:** Use `.toolbarVisibility(.hidden, for: .tabBar)`.

```swift
nonisolated func toolbarVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

### 13. `platform-requirement` — Frontmatter `platforms: [iOS 26+, iPadOS 26+, macOS 26+, watchOS 26+, tvOS 26+, visionOS 26+]`. The toolbar and tab APIs are presented with no per-platform caveats.  
_SKILL.md:5_

- **Correct / new info:** Several APIs the skill teaches are not available on every listed platform:
- ToolbarSpacer, SpacerSizing and ToolbarContent.sharedBackgroundVisibility: iOS, iPadOS, Mac Catalyst and macOS 26.0 only (no tvOS, visionOS or watchOS).
- tabViewBottomAccessory(content:): iOS, iPadOS and Mac Catalyst 26.0 only; the isEnabled: overload is 26.1.
- ToolbarContent.matchedTransitionSource(id:in:): iOS, iPadOS and Mac Catalyst 26.0 only.
- TabBarMinimizeBehavior.onScrollDown and .onScrollUp: "Minimizing is supported for tab bars on only iPhone."
- NavigationTransition.zoom: "not supported in tvOS".
- **Availability:** see correct_info
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarspacer (apple-doc, confidence high)
- **Action:** Add an availability column to the toolbar and tab sections of 01-api-reference.md. In the patterns, mark the bottom accessory as iOS/iPadOS only and tab-bar minimize as iPhone only.

### 14. `platform-requirement` — "`.tabBarMinimizeBehavior(.onScrollDown)` only works inside a tab whose root is a scrollable view"  
_patterns/glass-tab-bar.md:86_

- **Correct / new info:** Apple's member docs for both onScrollDown and onScrollUp say: "Minimizing is supported for tab bars on only iPhone." TabBarMinimizeBehavior has four members: automatic, never, onScrollDown and onScrollUp. The skill (01-api-reference.md:374-376) omits onScrollUp. WWDC25: "the tab bar re-expands when scrolling in the opposite direction."
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+ (minimizing effective on iPhone only)
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior (apple-doc, confidence high)
- **Action:** Add 'iPhone only' to the gotcha and add `.onScrollUp` to the member list in 01-api-reference.md §9.

```swift
nonisolated func tabBarMinimizeBehavior(_ behavior: TabBarMinimizeBehavior) -> some View
```

### 15. `factually-wrong` — "A native iOS 26 search field that lives in the nav bar, collapses to an icon when not in use" (also glass-navigation-bar.md:45 'Search in nav bar').  
_patterns/glass-search-field.md:4_

- **Correct / new info:** WWDC25-323: "Search in the toolbar places the field at the bottom of the screen, within easy reach. And on iPad and Mac, it appears in the top-trailing position of the toolbar." The searchToolbarBehavior(_:) docs say: "On iPhone, the search field in the bottom toolbar can be configured to appear as a button-like control when inactive." The HIG says to place search at the bottom if there's room and at the top "when it's important to defer to content at the bottom of the screen, or there's no bottom toolbar".
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/searchtoolbarbehavior(_:) (apple-doc, confidence medium)
- **Action:** Describe the platform placement (iPhone: bottom toolbar; iPad/Mac: top trailing). Say `.minimize` renders the bottom-toolbar field as a button-like control. Retitle 'Search in nav bar'.

```swift
nonisolated func searchToolbarBehavior(_ behavior: SearchToolbarBehavior) -> some View
```

### 16. `factually-wrong` — DefaultToolbarItem(kind: .search, placement: .bottomBar) "pins the search field above the tab bar — common in media apps"  
_patterns/glass-search-field.md:66_

- **Correct / new info:** DefaultToolbarItem: "Place this item in your toolbar to control where the system-provided item, like search, will be positioned." It moves or replaces the default-placed search item among other bottom-bar items; Apple's example moves search between other bottomBar items. It can also mark which NavigationSplitView column shows search when collapsed. It is not a tab-bar accessory.
- **Availability:** iOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem/init(kind:placement:) (apple-doc, confidence medium)
- **Action:** Reword: "Repositions the system search item within the bottom toolbar relative to your other items (use ToolbarSpacer to separate)."

```swift
nonisolated init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)
```

### 17. `design-guidance` — Badge sample: `Button("Inbox", systemImage: "tray") { }.badge(5).tint(.red)`, repeated in examples/09-HealthTodayScreen.swift:109-110 on a bell icon.  
_references/01-api-reference.md:340_

- **Correct / new info:** `.badge` on toolbar-item content is correct (View.badge: "Badges appear in list rows, tab bars, toolbar items, and menus"; WWDC25 applies it to the item's content). `.tint` tints the button or icon, not the badge. WWDC25-323: "Icons use monochrome rendering in more places, including in toolbars... You can still tint icons with a tint modifier, but use this to convey meaning, like a call to action or next step, but not just for visual effect."
- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, visionOS 1.0+
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence medium)
- **Action:** Remove `.tint(.red)` from the badge samples. Add the monochrome-icon guidance: tint only to convey meaning.

```swift
nonisolated func badge(_ count: Int) -> some View
```

### 18. `new-api-ios27` — Toolbar integration section covers only ToolbarSpacer, badges and sharedBackgroundVisibility. No iOS 27 toolbar APIs.  
_references/01-api-reference.md:298_

- **Correct / new info:** New in iOS 27 (SwiftUI updates, June 2026; WWDC26-269):
- `ToolbarContent.visibilityPriority(_:)` with ToolbarItemVisibilityPriority (.automatic, .low, .high, init(lowerThan:), init(higherThan:)). Lower-priority items move to the overflow menu first.
- `ToolbarOverflowMenu { }` (ToolbarContent) and `View.toolbarOverflowMenu(content:)`. Their actions always go in the overflow menu.
- `ToolbarItemPlacement.topBarPinnedTrailing`. "Pinned items only move to the overflow menu when search is active and there isn't enough room."
- **Availability:** visibilityPriority: iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 26.1+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+; ToolbarOverflowMenu/toolbarOverflowMenu & topBarPinnedTrailing: iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, visionOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:) (apple-doc, confidence high)
- **Action:** Add an 'iOS 27 toolbar' subsection using Apple's WWDC26 sample: `ToolbarItemGroup { Undo; Redo }.visibilityPriority(.high)`, `ToolbarOverflowMenu { ... }`, `ToolbarItem(placement: .topBarPinnedTrailing) { ShareButton() }`. Gate it with `if #available(iOS 27, *)` guidance.

```swift
@MainActor @preconcurrency func visibilityPriority(_ priority: ToolbarItemVisibilityPriority) -> some ToolbarContent; nonisolated struct ToolbarOverflowMenu<Content> where Content : View { init(content: () -> Content) }; static let topBarPinnedTrailing: ToolbarItemPlacement
```

### 19. `new-api-ios27` — Only tab-bar minimization is covered. There is no navigation-bar or toolbar minimization API.  
_references/01-api-reference.md:372_

- **Correct / new info:** iOS 27 adds `View.toolbarMinimizationBehavior(_:for:)`. Its docs say: "The supported placement is navigationBar. When the navigation bar minimizes, an integrated top tab bar will also minimize." Related types: ToolbarMinimizationBehavior (automatic, never, onScrollDown, onScrollUp), `toolbarMinimizationSafeAreaAdjustment(_:for:)` and `toolbarMinimizationRestoration(_:for:)`. ToolbarMinimizationBehavior.automatic: "By default, navigation bars on iOS will minimize when the view has a searchable using the toolbarPrincipal placement." The WWDC26-269 video code spells it `.toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)`, but that page 404s in the shipping docs. The shipping name is toolbarMinimizationBehavior.
- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:) (apple-doc, confidence high)
- **Action:** Add `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)` with an iOS 27 gate. Warn explicitly against the beta spelling `toolbarMinimizeBehavior`.

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

### 20. `new-api-ios27` — Tab roles taught: only `.search`.  
_patterns/glass-tab-bar.md:13_

- **Correct / new info:** TabRole.prominent (iOS 27): "A tab role that provides prominent visual treatment to one of the tabs in supported tab bars. Only one tab can receive the prominent treatment. When there are no tabs with an explicit .prominent role, then a .search role tab may receive the prominent visual treatment by default." The updates page: "Set the TabRole.prominent role on a tab to place the tab in a separate, trailing position of the tab bar." WWDC26 sample: `Tab(role: .prominent) { CartTab() }`.
- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabrole/prominent (apple-doc, confidence high)
- **Action:** Add a '.prominent tab (iOS 27)' variation. Note that only one tab gets the treatment and that a .search tab may become prominent by default on iOS 27.

```swift
static var prominent: TabRole { get }
```

### 21. `new-api-ios27` — The only sheet transition variant taught is zoom.  
_patterns/glass-modal-sheet.md:64_

- **Correct / new info:** NavigationTransition.crossFade (iOS 27): "Specify this transition in a sheet to have it appear by fading in over the content, as opposed to moving upwards to cover content." Sample: `.sheet(isPresented: $showSheet) { Text("Sheet Content").presentationDetents([.medium]).navigationTransition(.crossFade) }`. Not available on macOS.
- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/navigationtransition/crossfade (apple-doc, confidence high)
- **Action:** Add a 'Cross-fade sheet (iOS 27)' variation.

```swift
static var crossFade: CrossFadeNavigationTransition { get }
```

### 22. `new-api-ios26x` — Only `.tabViewBottomAccessory { … }` is shown. Accessory visibility cannot be toggled.  
_references/01-api-reference.md:379_

- **Correct / new info:** iOS 26.1 added `tabViewBottomAccessory(isEnabled:content:)`: "Use this modifier to dynamically show and hide the accessory view." isEnabled: "If true, the bottom accessory is shown; otherwise, the bottom accessory is hidden."
- **Availability:** iOS 26.1+, iPadOS 26.1+, Mac Catalyst 26.1+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:) (apple-doc, confidence high)
- **Action:** Add the isEnabled: overload for conditional accessories, such as a now-playing strip shown only while audio plays. Advise against using `if` inside the content closure to hide it.

```swift
nonisolated func tabViewBottomAccessory<Content>(isEnabled: Bool, @ContentBuilder content: () -> Content) -> some View where Content : View
```

### 23. `new-api-ios26x` — No guidance on hiding a toolbar item.  
_references/01-api-reference.md:298_

- **Correct / new info:** `ToolbarContent.hidden(_:)` hides a toolbar item within its toolbar. Adopting Liquid Glass: "If you see an empty toolbar item without any content, your app might be hiding the view in the toolbar item instead of the item itself. Instead, hide the entire toolbar item" (SwiftUI: ToolbarContent.hidden(_:)).
- **Availability:** iOS 26.4+, iPadOS 26.4+, Mac Catalyst 26.4+, macOS 15.0+, visionOS 26.4+, tvOS 27.2 (beta), watchOS 27.2 (beta)
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/hidden(_:) (apple-doc, confidence high)
- **Action:** Add an anti-pattern: "Don't put `if` around the view inside ToolbarItem; use `ToolbarItem { … }.hidden(condition)` (iOS 26.4+)".

```swift
nonisolated func hidden(_ hidden: Bool = true) -> some ToolbarContent
```

### 24. `other` — The zoom transition source is shown only as a free-standing Button with View.matchedTransitionSource.  
_references/04-motion-and-interaction.md:187_

- **Correct / new info:** For a toolbar button that presents a sheet (the most common Liquid Glass case), iOS 26 adds `ToolbarContent.matchedTransitionSource(id:in:)`, applied to the ToolbarItem. Apple's sample: `ToolbarItem(placement: .topBarTrailing) { Button(...) }.matchedTransitionSource(id: "world", in: namespace)` with `.sheet { SheetView().navigationTransition(.zoom(sourceID: "world", in: namespace)) }`. The skill's View-level usage on sheet content is valid. navigationTransition docs: "Add this modifier to a view that appears within a NavigationStack or a sheet, outside of any containers such as VStack." Zoom is not supported on tvOS.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/matchedtransitionsource(id:in:) (apple-doc, confidence high)
- **Action:** Add the toolbar-item source variant to 04-motion, glass-modal-sheet.md and 01-api-reference §11. Note that navigationTransition must be on the outermost sheet content.

```swift
nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some ToolbarContent
```

### 25. `behavior-change` — The toolbar samples assume ToolbarContentBuilder semantics.  
_references/01-api-reference.md:298_

- **Correct / new info:** Xcode 27: "construct type-agnostic content from closures that you mark with ContentBuilder, which serves as the unified replacement for type-specific builders like ToolbarContentBuilder and CommandsBuilder." WWDC26-269: ContentBuilder works with any deployment target and improves type-checking. Apple TN3211 'Resolving SwiftUI source incompatibilities for State and ContentBuilder' covers source breaks. New iOS 27-era declarations such as tabViewBottomAccessory already show `@ContentBuilder content:`.
- **Availability:** Xcode 27+ (any deployment target)
- **Evidence:** https://developer.apple.com/documentation/updates/swiftui (apple-doc, confidence medium)
- **Action:** Add a short 'Xcode 27 notes' block: helper functions returning toolbar content can use @ContentBuilder; see TN3211 for State-macro and ContentBuilder source breaks.

### 26. `other` — `.searchToolbarBehavior(.minimize)` is the default recommendation, and SearchToolbarBehavior is not enumerated.  
_patterns/glass-search-field.md:84_

- **Correct / new info:** SearchToolbarBehavior has exactly two members: `automatic` and `minimize` ("A search toolbar behavior that prefers rendering a search field as a button-like control"). Apple's own discussion sample misspells it `.searchToolbarBehavior(.minimized)`; that spelling is not a member. Apple: "Place this modifier after the searchable(...) modifier". The skill does this correctly. Related: `searchPresentationToolbarBehavior(.avoidHidingContent)` (iOS 17.1) and `tabViewSearchActivation(.searchTabSelection)` (iOS 26.0) are not covered.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/searchtoolbarbehavior (apple-doc, confidence high)
- **Action:** Keep `.minimize` and list both members. Note that `.minimized` is wrong despite Apple's sample. Optionally add tabViewSearchActivation for search tabs.

```swift
struct SearchToolbarBehavior { static var automatic; static var minimize }
```

### 27. `design-guidance` — `.searchable` + `.searchToolbarBehavior(.minimize)` combined with a custom `.safeAreaInset(edge: .bottom)` floating glass quick-action bar.  
_examples/05-DashboardScreen.swift:63_

- **Correct / new info:** On iPhone, toolbar search renders in the bottom toolbar. With `.minimize` it is a button-like control there, so this screen stacks two bottom glass layers: the custom bar and the system search. HIG: "Place search at the top when itʼs important to defer to content at the bottom of the screen, or thereʼs no bottom toolbar." Alternatives: `DefaultToolbarItem(kind: .search, placement: .bottomBar)` together with the quick actions as real bottomBar ToolbarItems, or top placement.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/search-fields (apple-other, confidence low)
- **Action:** Verify on device. Consider moving the quick actions into `.toolbar { ToolbarItem(placement: .bottomBar) ... DefaultToolbarItem(kind: .search, placement: .bottomBar) }` instead of a custom inset bar.

## Symbols (41)

### `ToolbarSpacer / init(_:placement:)`

```swift
nonisolated struct ToolbarSpacer; nonisolated init(_ sizing: SpacerSizing = .flexible, placement: ToolbarItemPlacement = .automatic)
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+ (no tvOS/visionOS/watchOS)
- **Members:** init(_:placement:); conforms to CustomizableToolbarContent, ToolbarContent
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarspacer/init(_:placement:)
- **Skill uses it correctly:** yes
- **Notes:** The skill's signature claim (01-api-reference.md:333) and usages `ToolbarSpacer(.fixed, placement: .topBarTrailing)` are correct. Missing: the platform limitation.

### `SpacerSizing`

```swift
struct SpacerSizing
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+
- **Members:** static let fixed: SpacerSizing, static let flexible: SpacerSizing
- **Doc:** https://developer.apple.com/documentation/swiftui/spacersizing
- **Skill uses it correctly:** yes
- **Notes:** fixed = system-defined size; flexible = expands.

### `ToolbarContent.sharedBackgroundVisibility(_:)`

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:)
- **Skill uses it correctly:** NO
- **Notes:** A ToolbarContent modifier applied to ToolbarItem. The skill applies it to a Button (View), which does not compile. The View version 404s.

### `View.sharedBackgroundVisibility(_:)`

```swift
NOT FOUND
```

- **Availability:** 
- **Doc:** https://developer.apple.com/documentation/swiftui/view/sharedbackgroundvisibility(_:)
- **Skill uses it correctly:** NO
- **Notes:** The DocC JSON returns HTTP 404. No View overload exists.

### `DefaultToolbarItem / init(kind:placement:)`

```swift
nonisolated struct DefaultToolbarItem; nonisolated init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** init(kind:placement:); Conforms To: ToolbarContent
- **Doc:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem/init(kind:placement:)
- **Skill uses it correctly:** NO
- **Notes:** It is ToolbarContent and must go directly in `.toolbar {}`. The skill wraps it in ToolbarItem (01-api-reference.md:421, glass-search-field.md:59), which is a compile error.

### `ToolbarDefaultItemKind`

```swift
struct ToolbarDefaultItemKind
```

- **Availability:** iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+
- **Members:** sidebarToggle, search, title
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbardefaultitemkind
- **Skill uses it correctly:** yes
- **Notes:** .search is used correctly as the kind.

### `ToolbarItem`

```swift
nonisolated struct ToolbarItem<ID, Content> where Content : View
```

- **Availability:** iOS 14.0+, iPadOS 14.0+, Mac Catalyst 14.0+, macOS 11.0+, tvOS 14.0+, visionOS 1.0+, watchOS 7.0+
- **Members:** init(placement:content:), init(id:placement:content:), init(id:placement:showsByDefault:content:) [deprecated]
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritem
- **Skill uses it correctly:** yes
- **Notes:** The content closure must be a View. That is why nesting DefaultToolbarItem fails. ToolbarItem has no badge method; badge goes on the content View.

### `ToolbarItemPlacement`

```swift
struct ToolbarItemPlacement
```

- **Availability:** iOS 14.0+, macOS 11.0+, watchOS 7.0+, visionOS 1.0+ (type)
- **Members:** automatic, principal, status, primaryAction, secondaryAction, confirmationAction, cancellationAction, destructiveAction, navigation, topBarLeading, topBarTrailing, topBarPinnedTrailing, bottomBar, bottomOrnament, keyboard, accessoryBar(id:), largeSubtitle, largeTitle, subtitle, title; deprecated: init(id:), navigationBarLeading, navigationBarTrailing
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemplacement
- **Skill uses it correctly:** yes
- **Notes:** The skill uses topBarLeading, topBarTrailing, bottomBar, confirmationAction and cancellationAction, all valid, and avoids the deprecated navigationBar* placements. largeSubtitle is iOS/iPadOS/Catalyst 26.0.

### `ToolbarItemPlacement.topBarPinnedTrailing`

```swift
static let topBarPinnedTrailing: ToolbarItemPlacement
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, visionOS 27.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemplacement/topbarpinnedtrailing
- **Skill uses it correctly:** NO
- **Notes:** New in 27 and absent from the skill. "Pinned items only move to the overflow menu when search is active and there isn't enough room."

### `View.badge(_:)`

```swift
nonisolated func badge(_ count: Int) -> some View (+ LocalizedStringKey?, Text?, S: StringProtocol?, LocalizedStringResource? overloads)
```

- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, visionOS 1.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/badge(_:)
- **Skill uses it correctly:** yes
- **Notes:** "Badges appear in list rows, tab bars, toolbar items, and menus." Applying it to the toolbar item's Button content is correct (as in WWDC25). The accompanying `.tint(.red)` does not color the badge.

### `View.toolbarBackground(_:for:) [ShapeStyle]`

```swift
nonisolated func toolbarBackground<S>(_ style: S, for bars: ToolbarPlacement...) -> some View where S : ShapeStyle
```

- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, tvOS 16.0+, visionOS 1.0+, watchOS 9.0+ (not deprecated)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarbackground(_:for:)
- **Skill uses it correctly:** yes
- **Notes:** Used only as an anti-pattern (07-anti-patterns.md:90), which matches Apple's 'remove custom bar backgrounds' guidance.

### `View.toolbarBackground(_:for:) [Visibility] (-7lv0f)`

```swift
nonisolated func toolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** introduced iOS 16.0 / macOS 13.0 / watchOS 9.0; metadata deprecatedAt 27.2 (iOS, iPadOS, Mac Catalyst, macOS, tvOS, watchOS), renamed toolbarBackgroundVisibility(_:for:)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarbackground(_:for:)-7lv0f
- **Skill uses it correctly:** NO
- **Notes:** glass-navigation-bar.md:59 uses `.toolbarBackground(.hidden, for: .navigationBar)`. It should be toolbarBackgroundVisibility.

### `View.toolbarBackgroundVisibility(_:for:)`

```swift
nonisolated func toolbarBackgroundVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarbackgroundvisibility(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** The replacement API. Not used in the skill.

### `View.toolbar(_:for:) [Visibility] / toolbarVisibility(_:for:)`

```swift
nonisolated func toolbar(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View; nonisolated func toolbarVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** toolbar(_:for:): iOS 16.0+, deprecatedAt 27.2, renamed toolbarVisibility(_:for:); toolbarVisibility: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarvisibility(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** glass-tab-bar.md:79 uses `.toolbar(.hidden, for: .tabBar)`.

### `ToolbarOverflowMenu / View.toolbarOverflowMenu(content:)`

```swift
nonisolated struct ToolbarOverflowMenu<Content> where Content : View { init(content: () -> Content) }; nonisolated func toolbarOverflowMenu<C>(@ContentBuilder content: () -> C) -> some View where C : View
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, visionOS 27.0+
- **Members:** init(content:); conforms to CustomizableToolbarContent, ToolbarContent
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu
- **Skill uses it correctly:** NO
- **Notes:** New in 27 and absent. "actions that are always placed in the toolbar's overflow menu".

### `ToolbarContent.visibilityPriority(_:) / ToolbarItemVisibilityPriority`

```swift
@MainActor @preconcurrency func visibilityPriority(_ priority: ToolbarItemVisibilityPriority) -> some ToolbarContent; struct ToolbarItemVisibilityPriority
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 26.1+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Members:** automatic, low, high, init(lowerThan:), init(higherThan:)
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:)
- **Skill uses it correctly:** NO
- **Notes:** New in 27 and absent.

### `View.toolbarMinimizationBehavior(_:for:) / ToolbarMinimizationBehavior`

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View; struct ToolbarMinimizationBehavior
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Members:** automatic, never, onScrollDown, onScrollUp; related: toolbarMinimizationSafeAreaAdjustment(_:for:), toolbarMinimizationRestoration(_:for:)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** New in 27 and absent. Supported placement: navigationBar. The WWDC26 video spells it toolbarMinimizeBehavior, which 404s; the shipping name is toolbarMinimizationBehavior.

### `View.toolbarMinimizeBehavior(_:for:)`

```swift
NOT FOUND
```

- **Availability:** 
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizebehavior(_:for:)
- **Skill uses it correctly:** yes
- **Notes:** 404 in DocC. This spelling appears only in the WWDC26-269 code; do not use it.

### `ToolbarContent.hidden(_:)`

```swift
nonisolated func hidden(_ hidden: Bool = true) -> some ToolbarContent
```

- **Availability:** iOS 26.4+, iPadOS 26.4+, Mac Catalyst 26.4+, macOS 15.0+, visionOS 26.4+, tvOS 27.2 (beta), watchOS 27.2 (beta)
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/hidden(_:)
- **Skill uses it correctly:** NO
- **Notes:** Absent. Recommended by Adopting Liquid Glass to avoid empty glass toolbar items.

### `ToolbarContent.axisBehavior(_:)`

```swift
nonisolated func axisBehavior(_ behavior: ToolbarItemAxisBehavior) -> some ToolbarContent
```

- **Availability:** iOS 27.1 (beta), iPadOS 27.1 (beta), Mac Catalyst 27.1+, macOS 27.1+, tvOS 27.1+, visionOS 27.1+, watchOS 27.1+
- **Members:** ToolbarItemAxisBehavior e.g. .horizontalOnly, .verticalPreferred (from updates page)
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/axisbehavior(_:)
- **Skill uses it correctly:** NO
- **Notes:** September 2026 'Controls on the vertical axis' (toolbarVerticalEdge, toolbarVerticalBehavior, toolbarVerticalCompressionBehavior). Still beta on iOS. Optional mention.

### `ToolbarContent.matchedTransitionSource(id:in:)`

```swift
nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some ToolbarContent
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/matchedtransitionsource(id:in:)
- **Skill uses it correctly:** NO
- **Notes:** Absent. Use it for toolbar-item to sheet zoom transitions.

### `Tab`

```swift
struct Tab<Value, Content, Label>
```

- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Members:** init(content:), init(value:content:), init(role:content:), init(value:role:content:), init(content:label:), init(value:content:label:), init(role:content:label:), init(value:role:content:label:), init(_:systemImage:content:), init(_:systemImage:value:content:), init(_:systemImage:role:content:), init(_:systemImage:value:role:content:), init(_:image:content:), init(_:image:value:content:), init(_:image:role:content:), init(_:image:value:role:content:)
- **Doc:** https://developer.apple.com/documentation/swiftui/tab
- **Skill uses it correctly:** yes
- **Notes:** `Tab("Search", systemImage: "magnifyingglass", role: .search)` is valid. Apple samples prefer `Tab(role: .search)` with the system label.

### `TabRole`

```swift
struct TabRole
```

- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+; .prominent iOS/iPadOS/Mac Catalyst/macOS/tvOS/visionOS/watchOS 27.0+
- **Members:** static var prominent: TabRole (27.0), static var search: TabRole (18.0)
- **Doc:** https://developer.apple.com/documentation/swiftui/tabrole
- **Skill uses it correctly:** NO
- **Notes:** .search usage compiles, but the skill misdescribes where the field appears (it replaces the tab bar). .prominent is missing.

### `View.tabBarMinimizeBehavior(_:) / TabBarMinimizeBehavior`

```swift
nonisolated func tabBarMinimizeBehavior(_ behavior: TabBarMinimizeBehavior) -> some View; struct TabBarMinimizeBehavior
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** automatic, never, onScrollDown, onScrollUp
- **Doc:** https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior
- **Skill uses it correctly:** yes
- **Notes:** Usage is correct. The skill omits .onScrollUp and the doc note "Minimizing is supported for tab bars on only iPhone."

### `View.tabViewBottomAccessory(content:) / (isEnabled:content:)`

```swift
nonisolated func tabViewBottomAccessory<Content>(@ContentBuilder content: () -> Content) -> some View where Content : View; nonisolated func tabViewBottomAccessory<Content>(isEnabled: Bool, @ContentBuilder content: () -> Content) -> some View where Content : View
```

- **Availability:** content: iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+; isEnabled: iOS 26.1+, iPadOS 26.1+, Mac Catalyst 26.1+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:)
- **Skill uses it correctly:** yes
- **Notes:** Usage on the TabView is correct. The isEnabled overload (26.1) and the iOS-only availability are missing.

### `TabViewBottomAccessoryPlacement / EnvironmentValues.tabViewBottomAccessoryPlacement`

```swift
enum TabViewBottomAccessoryPlacement; var tabViewBottomAccessoryPlacement: TabViewBottomAccessoryPlacement? { get }
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** case expanded, case inline
- **Doc:** https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement
- **Skill uses it correctly:** NO
- **Notes:** The skill claims a `.collapsed` case, which does not exist (it is `.inline`). The environment value is Optional; nil means undefined. The env key name `\.tabViewBottomAccessoryPlacement` is correct.

### `View.tabViewSearchActivation(_:) / TabSearchActivation`

```swift
nonisolated func tabViewSearchActivation(_ activation: TabSearchActivation) -> some View; struct TabSearchActivation
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+ (modifier); type also tvOS/visionOS/watchOS 26.0
- **Members:** automatic, searchTabSelection
- **Doc:** https://developer.apple.com/documentation/swiftui/view/tabviewsearchactivation(_:)
- **Skill uses it correctly:** NO
- **Notes:** Absent from the skill.

### `TabViewStyle.sidebarAdaptable`

```swift
@MainActor @export(implementation) @preconcurrency static var sidebarAdaptable: SidebarAdaptableTabViewStyle { get }
```

- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/tabviewstyle/sidebaradaptable
- **Skill uses it correctly:** yes
- **Notes:** Not used by the skill. Recommended in Adopting Liquid Glass for tab bars that adapt into a sidebar. tabViewSidebarHeader/Footer/BottomBar also exist.

### `View.searchable(text:placement:prompt:)`

```swift
nonisolated func searchable(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey) -> some View (+ Text? = nil, StringProtocol, LocalizedStringResource overloads)
```

- **Availability:** iOS 16.0+ (this overload family), iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, tvOS 16.0+, visionOS 1.0+, watchOS 9.0+
- **Members:** SearchFieldPlacement: automatic, navigationBarDrawer, navigationBarDrawer(displayMode:), sidebar, toolbar, toolbarPrincipal
- **Doc:** https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)
- **Skill uses it correctly:** yes
- **Notes:** Calls are valid. The skill's description of placement ('lives in the nav bar') is wrong for iPhone, where toolbar search sits at the bottom.

### `View.searchToolbarBehavior(_:) / SearchToolbarBehavior`

```swift
nonisolated func searchToolbarBehavior(_ behavior: SearchToolbarBehavior) -> some View; struct SearchToolbarBehavior
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** automatic, minimize
- **Doc:** https://developer.apple.com/documentation/swiftui/searchtoolbarbehavior
- **Skill uses it correctly:** yes
- **Notes:** `.minimize` is correct and placed after `.searchable`, as Apple requires. Apple's sample typo `.minimized` is not a member.

### `View.searchPresentationToolbarBehavior(_:)`

```swift
nonisolated func searchPresentationToolbarBehavior(_ behavior: SearchPresentationToolbarBehavior) -> some View
```

- **Availability:** iOS 17.1+, iPadOS 17.1+, Mac Catalyst 17.1+, macOS 14.1+, tvOS 17.1+, visionOS 1.0+, watchOS 10.1+
- **Members:** avoidHidingContent (only member shown)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/searchpresentationtoolbarbehavior(_:)
- **Skill uses it correctly:** yes
- **Notes:** Not used by the skill.

### `View.presentationDetents(_:)`

```swift
nonisolated func presentationDetents(_ detents: Set<PresentationDetent>) -> some View
```

- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, tvOS 16.0+, visionOS 1.0+, watchOS 9.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:)
- **Skill uses it correctly:** yes
- **Notes:** `[.medium, .large]` and `[.height(220), .medium, .large]` are valid. The `[.large]` + `.enabled(upThrough: .medium)` combination is logically wrong.

### `View.presentationBackground(_:)`

```swift
nonisolated func presentationBackground<S>(_ style: S) -> some View where S : ShapeStyle
```

- **Availability:** iOS 16.4+, iPadOS 16.4+, Mac Catalyst 16.4+, macOS 13.3+, tvOS 16.4+, visionOS 1.0+, watchOS 9.4+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/presentationbackground(_:)
- **Skill uses it correctly:** NO
- **Notes:** `.clear` replaces the iOS 26 Liquid Glass sheet background. Apple says to remove custom presentationBackground.

### `View.presentationBackgroundInteraction(_:) / PresentationBackgroundInteraction`

```swift
nonisolated func presentationBackgroundInteraction(_ interaction: PresentationBackgroundInteraction) -> some View; struct PresentationBackgroundInteraction
```

- **Availability:** iOS 16.4+, iPadOS 16.4+, Mac Catalyst 16.4+, macOS 13.3+, tvOS 16.4+, visionOS 1.0+, watchOS 9.4+
- **Members:** automatic, disabled, enabled, enabled(upThrough:)
- **Doc:** https://developer.apple.com/documentation/swiftui/presentationbackgroundinteraction
- **Skill uses it correctly:** NO
- **Notes:** The call is valid, but upThrough: .medium is used with detents [.large] only, so it never takes effect.

### `View.containerBackground(_:for:) / ContainerBackgroundPlacement.navigation`

```swift
nonisolated func containerBackground<S>(_ style: S, for container: ContainerBackgroundPlacement) -> some View where S : ShapeStyle; static let navigation: ContainerBackgroundPlacement
```

- **Availability:** containerBackground: iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+; .navigation: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, watchOS 10.0+
- **Members:** navigation, navigationSplitView, tabView, widget, window, subscriptionStore, subscriptionStoreFullHeight, subscriptionStoreHeader
- **Doc:** https://developer.apple.com/documentation/swiftui/containerbackgroundplacement/navigation
- **Skill uses it correctly:** NO
- **Notes:** Must be applied inside a NavigationStack. The skill's 'blend nav-bar glass with sheet glass' claim is unverified.

### `View.scrollContentBackground(_:)`

```swift
nonisolated func scrollContentBackground(_ visibility: Visibility) -> some View
```

- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, visionOS 1.0+, watchOS 9.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/scrollcontentbackground(_:)
- **Skill uses it correctly:** NO
- **Notes:** Correct on List (07-anti-patterns). No effect on the plain ScrollView in glass-modal-sheet.md:42.

### `View.matchedTransitionSource(id:in:)`

```swift
nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View
```

- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Members:** also matchedTransitionSource(id:in:configuration:)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource(id:in:)
- **Skill uses it correctly:** yes
- **Notes:** Used correctly on Buttons.

### `View.navigationTransition(_:)`

```swift
nonisolated func navigationTransition(_ style: some NavigationTransition) -> some View
```

- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:)
- **Skill uses it correctly:** yes
- **Notes:** "Add this modifier to a view that appears within a NavigationStack or a sheet, outside of any containers such as VStack." The skill's use on sheet content is valid.

### `NavigationTransition`

```swift
protocol NavigationTransition
```

- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+; crossFade iOS/iPadOS/Mac Catalyst/tvOS/visionOS/watchOS 27.0+
- **Members:** automatic, crossFade (27.0), zoom(sourceID:in:)
- **Doc:** https://developer.apple.com/documentation/swiftui/navigationtransition
- **Skill uses it correctly:** yes
- **Notes:** zoom is used correctly; zoom is "not supported in tvOS". crossFade (iOS 27, for sheets) is missing.

### `ContentTransition.symbolEffect(_:options:)`

```swift
static func symbolEffect<T>(_ effect: T, options: SymbolEffectOptions = .default) -> ContentTransition where T : ContentTransitionSymbolEffect, T : SymbolEffect
```

- **Availability:** iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/contenttransition/symboleffect(_:options:)
- **Skill uses it correctly:** yes
- **Notes:** `.contentTransition(.symbolEffect(.replace))` is valid everywhere it appears in the skill.

### `View.symbolEffect(_:options:value:)`

```swift
@export(implementation) nonisolated func symbolEffect<T, U>(_ effect: T, options: SymbolEffectOptions = .default, value: U) -> some View where T : DiscreteSymbolEffect, T : SymbolEffect, U : Equatable
```

- **Availability:** iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:value:)
- **Skill uses it correctly:** yes
- **Notes:** `.symbolEffect(.bounce, value: liked)` is valid.

