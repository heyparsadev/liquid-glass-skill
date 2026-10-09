# verify:truth-chrome#4

_Phase: Verify — independent re-check of findings from [truth-chrome](truth-chrome.md)_

## Finding 22 — **CONFIRMED**

> Only `.tabViewBottomAccessory { … }` is shown. Accessory visibility cannot be toggled.

- **Established truth:** Correct. `View.tabViewBottomAccessory(isEnabled:content:)` exists. Declaration: `nonisolated func tabViewBottomAccessory<Content>(isEnabled: Bool, @ContentBuilder content: () -> Content) -> some View where Content : View`. Raw platforms: iOS 26.1, iPadOS 26.1, Mac Catalyst 26.1, none beta or deprecated. Abstract: "Places a view as the bottom accessory of the tab view. Use this modifier to dynamically show and hide the accessory view." isEnabled: "If true, the bottom accessory is shown; otherwise, the bottom accessory is hidden." The closure-only `tabViewBottomAccessory(content:)` is iOS/iPadOS/Mac Catalyst 26.0 and not deprecated. The skill shows only the closure form, in 01-api-reference.md §9 (line 379), patterns/glass-tab-bar.md and examples/09-HealthTodayScreen.swift, so it omits the show/hide variant. It never literally says the accessory can't be toggled; the gap is an omission.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:)
- **Notes:** Verified via the DocC JSON at /tutorials/data/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:).json and the ...(content:).json sibling, which lists the isEnabled variant under See Also.
- Apple's sample: `.tabViewBottomAccessory(isEnabled: hasStatusUpdate) { HomeStatusView() }`.
- Both overloads' discussion: on iPhone the accessory appears above a normal-size tab bar and inline when the tab bar is collapsed; adapt the content with `tabViewBottomAccessoryPlacement`.
- If the skill keeps an iOS 26.0 floor, the isEnabled form needs `if #available(iOS 26.1, *)`.
- `@ContentBuilder` is how the Xcode 27 SDK docs now render every builder parameter. Call sites don't change.

## Finding 23 — **CONFIRMED**

> No guidance on hiding a toolbar item.

- **Established truth:** Correct. `ToolbarContent.hidden(_:)` has the declaration `nonisolated func hidden(_ hidden: Bool = true) -> some ToolbarContent`. Abstract: "Hides a toolbar item within its toolbar." Raw metadata.platforms: iOS 26.4, iPadOS 26.4, Mac Catalyst 26.4, macOS 15.0, visionOS 26.4 (all non-beta); tvOS 27.2 and watchOS 27.2 are flagged beta:true. Adopting Liquid Glass says, verbatim: "Check how you hide toolbar items. If you see an empty toolbar item without any content, your app might be hiding the view in the toolbar item instead of the item itself. Instead, hide the entire toolbar item, using these APIs:" It then links SwiftUI ToolbarContent/hidden(_:), UIKit UIBarButtonItem/isHidden and AppKit NSToolbarItem/isHidden. The skill's §8 Toolbar integration (line 298), and the rest of skills/, has no guidance on hiding toolbar items.
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/hidden(_:)
- **Notes:** Verified via /tutorials/data/documentation/swiftui/toolbarcontent/hidden(_:).json (raw platforms JSON fetched twice) and /tutorials/data/documentation/technologyoverviews/adopting-liquid-glass.json.
- Apple's sample applies the modifier to the item, not the inner view: `ToolbarItem { DownloadsButton() }.hidden(!showDownloads)`.
- The iOS floor is 26.4, not 26.0. The skill should say so; projects deploying to iOS 26.0–26.3 need an availability check.
- The doc page files it under "Setting visibility" together with sharedBackgroundVisibility(_:) and visibilityPriority(_:). The SwiftUI updates page (June 2026, Toolbars) lists visibilityPriority(_:) as new.

## Finding 25 — **PARTIALLY**

> The toolbar samples assume ToolbarContentBuilder semantics.

- **Established truth:** The Apple facts are accurate, but the claim that the skill's toolbar samples are wrong does not hold. Verified facts:
- SwiftUI updates page, June 2026 › General, verbatim: "Build your project in Xcode 27 or later to construct type-agnostic content from closures that you mark with ContentBuilder, which serves as the unified replacement for type-specific builders like ToolbarContentBuilder and CommandsBuilder."
- ContentBuilder is declared `typealias ContentBuilder = ViewBuilder`.
- WWDC26-269 'What's new in SwiftUI', verbatim: "ContentBuilder can be used with any minimum deployment target, because under the hood, it's an evolution of the existing ViewBuilder." The session also promises "a substantial improvement in type checking performance in SwiftUI when building using Xcode 27".
- TN3211 'Resolving SwiftUI source incompatibilities for State and ContentBuilder' exists.
- `toolbar(content:)` is now declared `nonisolated func toolbar<Content>(@ContentBuilder content: () -> Content) -> some View where Content : ToolbarContent`.
Why the skill is not wrong:
- The skill never names ToolbarContentBuilder (no occurrence anywhere in skills/).
- Its toolbar samples are plain `.toolbar { ToolbarItem / ToolbarItemGroup / ToolbarSpacer }` closures. TN3211 says such code "keeps the same syntax and type safety, and typechecks substantially faster", and it lists no toolbar-specific source breaks.
- ToolbarContentBuilder is still documented, with deprecated:false on every platform.
Also imprecise: tabViewBottomAccessory is iOS 26.0/26.1 API, not an 'iOS 27-era declaration'. The Xcode 27 docs render every builder parameter as `@ContentBuilder`, including `toolbar(content:)`, which dates from iOS 14.
- **Evidence:** https://developer.apple.com/documentation/technotes/tn3211-resolving-swiftui-source-incompatibilities-for-state-and-contentbuilder
- **Notes:** Sources: /tutorials/data/documentation/updates/swiftui.json, swiftui/contentbuilder.json, swiftui/toolbarcontentbuilder.json, swiftui/view/toolbar(content:)-5w0tj.json, technotes/tn3211-....json, and developer.apple.com/videos/play/wwdc2026/269/ (transcript).
- At most §8 could get an optional note: in Xcode 27 a computed toolbar-content property can be written `@ContentBuilder var items: some ToolbarContent` (Apple's ContentBuilder doc sample). That spelling needs the Xcode 27 SDK to compile, at any deployment target; `@ToolbarContentBuilder` still compiles.
- The real TN3211 breaks are: ambiguous ShapeStyle opacity/blendMode inside background(_:)/overlay(_:); cross-module type/member name collisions; TupleView generic constraints, which become TupleContent (unavailable before iOS 27); empty nested builders when MapKit is in scope; and deep `if`/`switch` branching in Chart when back-deploying. None of them touches the skill's toolbar samples.

## Finding 27 — **CONFIRMED**

> `.searchable` + `.searchToolbarBehavior(.minimize)` combined with a custom `.safeAreaInset(edge: .bottom)` floating glass quick-action bar.

- **Established truth:** Correct, and the proposed alternatives are valid APIs. On iPhone, toolbar search sits at the bottom of the screen:
- WWDC25-323, verbatim: "Search in the toolbar places the field at the bottom of the screen, within easy reach."
- searchToolbarBehavior(_:) doc: "On iPhone, the search field in the bottom toolbar can be configured to appear as a button-like control when inactive".
- SearchToolbarBehavior.minimize (iOS 26.0): "A search toolbar behavior that prefers rendering a search field as a button-like control."
The screen's `.safeAreaInset(edge: .bottom)` content "is anchored to the specified vertical edge of the parent view and its height insets the safe area", so it sits above that bottom bar. DashboardScreen therefore shows two bottom glass rows: the custom quick-action bar, with the system minimized search button below it.
HIG Search fields, verbatim: "Place search at the top when itʼs important to defer to content at the bottom of the screen, or thereʼs no bottom toolbar." Next to it: "Place search at the bottom if there's room. You can either add a search field to an existing toolbar, or as a new toolbar where search is the only item."
The bottom-bar alternative is real. `DefaultToolbarItem` has `init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)` (iOS 26.0+), and `ToolbarDefaultItemKind.search` is "The search item added by a searchable(...) modifier." Apple's own samples (WWDC25-323 InboxView, and the init(kind:placement:) doc) put `DefaultToolbarItem(kind: .search, placement: .bottomBar)` directly in `.toolbar`, next to `ToolbarItem(placement: .bottomBar)` items and ToolbarSpacer.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/search-fields
- **Notes:** Verified via HIG search-fields.json, swiftui/view/searchtoolbarbehavior(_:).json, searchtoolbarbehavior/minimize.json, defaulttoolbaritem/init(kind:placement:).json, toolbardefaultitemkind.json and the WWDC25-323 transcript.
Caveats:
- The two-row stacking is inferred from documented placement rules; nothing here renders SwiftUI. The HIG does not literally forbid a custom bar above the toolbar, but HIG Materials ("Use Liquid Glass effects sparingly... overusing this material in multiple custom controls can provide a subpar user experience") supports the concern.
- When applying the fix, put DefaultToolbarItem directly in the toolbar closure. `ToolbarItem<ID, Content> where Content : View`, and DefaultToolbarItem conforms only to ToolbarContent. The skill's own samples (01-api-reference.md around line 420 and patterns/glass-search-field.md around line 58) nest it inside `ToolbarItem(placement: .bottomBar) { ... }`, which should fail to type-check under either builder; fix those too.
- Apple notes that "Combinations of kind and placement may be valid on some platforms, but not on others."
- Three labeled actions plus search in one bar risks HIG overcrowding ("Choose items deliberately to avoid overcrowding"; "aim for a maximum of three" groups). Use icon-only items and ToolbarSpacer groups; the system may also minimize search on its own.
- The finding names no API for top placement, and I did not verify one.
- If a custom bar is kept, Adopting Liquid Glass points to safeAreaBar. `safeAreaBar(edge: VerticalEdge, …)` (iOS 26.0) "extends the edge effect of any scroll views affected by the inset safe area"; safeAreaInset does not.

