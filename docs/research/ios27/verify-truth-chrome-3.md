# verify:truth-chrome#3

_Phase: Verify — independent re-check of findings from [truth-chrome](truth-chrome.md)_

## Finding 16 — **CONFIRMED**

> DefaultToolbarItem(kind: .search, placement: .bottomBar) "pins the search field above the tab bar — common in media apps"

- **Established truth:** DefaultToolbarItem is `nonisolated struct DefaultToolbarItem`. It conforms only to ToolbarContent and is iOS/iPadOS/Mac Catalyst/macOS/tvOS/visionOS/watchOS 26.0+. Abstract: "A toolbar item that represents a system component." Overview: "Place this item in your toolbar to control where the system-provided item, like search, will be positioned."

The initializer is `nonisolated init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)`, 26.0+ on all platforms. Its docs say a matching default item "will implicitly replace the default-placed instance", and that you can use it "to move default item kinds to other ToolbarItemPlacements, or to reposition default item kinds relative to other toolbar content". Apple's example puts `.search` between other `.bottomBar` items ("The search item is the leading-most item by default"). It can also mark which NavigationSplitView column shows search when collapsed ("only applies when the search modifier is placed on the NavigationSplitView").

No Apple doc ties it to a tab bar or calls it a way to pin search above one. Search as a destination in media apps is the search-tab pattern (`Tab(role: .search)`), not a bottom toolbar.

The skill's sample also does not compile. It nests `DefaultToolbarItem` inside `ToolbarItem(placement: .bottomBar) { }`, but ToolbarItem requires `Content : View` and DefaultToolbarItem is ToolbarContent, not a View. It must sit directly in `.toolbar { }`. The same nesting appears at references/01-api-reference.md:419-423.
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem/init(kind:placement:)
- **Notes:** Sources:
- apple-doc JSON: defaulttoolbaritem, defaulttoolbaritem/init(kind:placement:), toolbaritem (`nonisolated struct ToolbarItem<ID, Content> where Content : View`; inits available when Content conforms to View), and toolbardefaultitemkind (`.search`: "The search item added by a searchable(text:isPresented:placement:prompt:) modifier").
- apple-video WWDC25-323. Its Mail-style sample places `DefaultToolbarItem(kind: .search, placement: .bottomBar)` directly between bottom-bar ToolbarSpacers. Transcript: "Search in the toolbar places the field at the bottom of the screen" and "Searching in multi-tab apps is often done in a dedicated search page... set a search role on one of your tabs".
- apple-other HIG search-fields (updated June 8, 2026): "Include search as an item in the sidebar or tab bar when you want an area dedicated to discovery... like Music and TV." The HIG's iOS bottom-toolbar examples are Settings, Mail and Notes.

Caveat: the docs never say how a bottom toolbar looks inside a TabView. It might render above the tab bar, but nothing documents it, so the skill's "pins above the tab bar" is unsupported rather than provably false. The "media apps / search as destination" framing does contradict the HIG.

All quotes, the declaration and the availability in the finding are accurate.

## Finding 17 — **PARTIALLY**

> Badge sample: `Button("Inbox", systemImage: "tray") { }.badge(5).tint(.red)`, repeated in examples/09-HealthTodayScreen.swift:109-110 on a bell icon.

- **Established truth:** Putting `.badge` on a toolbar item's content is correct.

The Int overload is `nonisolated func badge(_ count: Int) -> some View`, discussion verbatim: "Use a badge to convey optional, supplementary information about a view. Keep the contents of the badge as short as possible. Badges appear in list rows, tab bars, toolbar items, and menus." WWDC25-323 says: "I applied the badge modifier to my toolbar item's content to display this indicator". Its sample is `Button("Notifications", systemImage: "bell") { }.badge(modelData.notifications.count)` inside a ToolbarItemGroup, with no tint.

The tint guidance quote is verbatim from WWDC25-323: "Icons use monochrome rendering in more places, including in toolbars. ... You can still tint icons with a tint modifier, but use this to convey meaning, like a call to action or next step, but not just for visual effect." The HIG Toolbars page agrees: "Reduce the use of toolbar backgrounds and tinted controls."

The finding's availability is wrong. The Int overload is iOS 15.0+, iPadOS 15.0+, Mac Catalyst 15.0+, macOS 12.0+, visionOS 1.0+. The 16.0/13.0 values belong to the `badge(_ resource: LocalizedStringResource?)` overload.

No Apple doc says what `.tint` does to a badge's color. "tint tints the icon" is supported by the WWDC wording. "not the badge" is an inference.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/badge(_:)-8adyq
- **Notes:** Sources:
- apple-doc JSON view/badge(_:)-8adyq. Raw platforms array: iOS/iPadOS/Mac Catalyst 15.0, macOS 12.0, visionOS 1.0; externalID s:7SwiftUI4ViewPAAE5badgeyQrSiF.
- view/badge(_:) (the LocalizedStringResource overload, iOS 16.0 / macOS 13.0).
- view/tint(_:)-93mfq: "tint is always respected and should be used as a way to provide additional meaning to the control". Nothing about badges.
- badgeprominence: says nothing about color.
- apple-video WWDC25-323 transcript and code.
- apple-other HIG toolbars ("Reduce the use of toolbar backgrounds and tinted controls").
- The Adopting Liquid Glass article: "be judicious with your use of color in controls and navigation".

The skill locations are accurate: references/01-api-reference.md:338-340 (`.badge(5).tint(.red)` on "tray") and examples/09-HealthTodayScreen.swift:108-110 (`.badge(3).tint(.red)` on "bell.fill").

The recommended fix stands: drop `.tint(.red)` or justify it semantically. Badges are already system-styled, and the tint mainly recolors the glyph for decoration.

## Finding 18 — **CONFIRMED**

> Toolbar integration section covers only ToolbarSpacer, badges and sharedBackgroundVisibility. No iOS 27 toolbar APIs.

- **Established truth:** iOS 27 adds three toolbar APIs.

**Visibility priority**
- `@MainActor @preconcurrency func visibilityPriority(_ priority: ToolbarItemVisibilityPriority) -> some ToolbarContent`. Docs: "When toolbar space is limited, items with a lower priority move into the overflow menu before items with a higher priority. The default is automatic."
- `struct ToolbarItemVisibilityPriority` has `static let automatic`, `low` and `high`, plus `init(lowerThan:)` and `init(higherThan:)`.
- Both are iOS/iPadOS/Mac Catalyst/tvOS/visionOS/watchOS 27.0 and macOS 26.1.

**Overflow menu**
- `nonisolated struct ToolbarOverflowMenu<Content> where Content : View` conforms to ToolbarContent and CustomizableToolbarContent. Its initializer is exactly `nonisolated init(@ContentBuilder content: () -> Content)`.
- `View.toolbarOverflowMenu(content:)` is `nonisolated func toolbarOverflowMenu<C>(@ContentBuilder content: () -> C) -> some View where C : View`.
- Both say: "An overflow menu represents actions that are always placed in the toolbar's overflow menu, regardless of the toolbar mode, platform, or customizability." and "In iOS and visionOS, this content is placed into the overflow menu in the navigation bar."

**Pinned placement**
- `static let topBarPinnedTrailing: ToolbarItemPlacement`: "A placement that pins the item to the trailing edge of the toolbar." Also: "Pinned items only move to the overflow menu when search is active and there isn't enough room." and "On iOS and visionOS, the top bar is the navigation bar."

ToolbarOverflowMenu, toolbarOverflowMenu(content:) and topBarPinnedTrailing are iOS/iPadOS/Mac Catalyst/visionOS 27.0 only. No macOS, tvOS or watchOS is listed.
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:)
- **Notes:** Sources:
- apple-doc JSON: toolbarcontent/visibilitypriority(_:), toolbaritemvisibilitypriority, toolbaroverflowmenu, toolbaroverflowmenu/init(content:), view/toolbaroverflowmenu(content:), toolbaritemplacement/topbarpinnedtrailing, and the toolbars collection ("Controlling item visibility", "Populating a toolbar").
- apple-doc updates/swiftui, June 2026 Toolbars bullets for all three APIs.
- apple-video WWDC26-269 ("What's new in SwiftUI"), code at 6:15: `ToolbarItemGroup { UndoButton(); RedoButton() }.visibilityPriority(.high)`, `ToolbarOverflowMenu { ... }`, `ToolbarItem(placement: .topBarPinnedTrailing) { ShareButton() }`.

The finding's shorthand `init(content: () -> Content)` leaves out `nonisolated` and `@ContentBuilder`. ContentBuilder is new to the SwiftUI updates page in June 2026 (Xcode 27).

The skill's section 8 really does cover only the basic placements, ToolbarSpacer, badges and sharedBackgroundVisibility, and there are no iOS 27 references anywhere in the skill.

A useful HIG Toolbars caveat for any rewrite: "Don't add an overflow menu manually, and avoid layouts that cause toolbar items to overflow by default."

## Finding 19 — **CONFIRMED**

> Only tab-bar minimization is covered. There is no navigation-bar or toolbar minimization API.

- **Established truth:** iOS 27 adds `nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View`. It is 27.0 on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS. Docs: "Use this modifier to enable toolbar minimization in response to scrolling. The supported placement is navigationBar. When the navigation bar minimizes, an integrated top tab bar will also minimize." Sample: `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)`.

`struct ToolbarMinimizationBehavior` has four members: `static var automatic` ("The system determines the minimize behavior. By default, navigation bars on iOS will minimize when the view has a searchable using the toolbarPrincipal placement."), `static let never`, `static let onScrollDown` and `static let onScrollUp`.

Companion modifiers, both 27.0 on all platforms:
- `nonisolated func toolbarMinimizationSafeAreaAdjustment(_ adjustment: ToolbarMinimizationSafeAreaAdjustment, for bars: ToolbarPlacement...) -> some View`. Doc example uses `.disabled`; "only navigationBar supports customizing the safe area adjustment".
- `nonisolated func toolbarMinimizationRestoration(_ restoration: ToolbarMinimizationRestoration, for bars: ToolbarPlacement...) -> some View`. Doc example uses `.atScrollEdge`; "only navigationBar ... and only when used in combination with onScrollDown".

WWDC26-269 used `toolbarMinimizeBehavior`. The iOS 27 release notes say: "You can use toolbarMinimizationBehavior to control bar minimization behavior. This modifier replaces toolbarMinimizeBehavior. (177954148)"
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)
- **Notes:** Sources:
- apple-doc JSON: view/toolbarminimizationbehavior(_:for:), toolbarminimizationbehavior, view/toolbarminimizationsafeareaadjustment(_:for:), view/toolbarminimizationrestoration(_:for:), and the toolbars collection. Its "Minimizing a toolbar" section lists only the Minimization-spelled symbols.
- The guessed path view/toolbarminimizebehavior(_:for:).json returns HTTP 404.
- apple-video WWDC26-269: transcript "I add the new toolbarMinimizeBehavior modifier, and set it to 'onScrollDown' for the navigationBar placement"; code at 7:37 is `.toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)`.
- apple-other iOS & iPadOS 27 release notes: SwiftUI 177954148 (the rename), plus UIKit 177953926: "Use UINavigationItem.navigationBarMinimization ... replaces UINavigationItem.barMinimizeBehavior and UINavigationItem.barMinimizationSafeAreaAdjustment."
- apple-doc updates/swiftui June 2026: "Control how toolbars minimize in response to scrolling using the toolbarMinimizationBehavior(_:for:) modifier."

The skill characterization is accurate. The skill has only `tabBarMinimizeBehavior` and `searchToolbarBehavior(.minimize)`, which minimizes the search field, not a bar. Any skill code needs an iOS 27 availability gate.

## Finding 20 — **CONFIRMED**

> Tab roles taught: only `.search`.

- **Established truth:** `static var prominent: TabRole { get }` is 27.0 on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS. TabRole itself is iOS 18.0 and has two members, `prominent` and `search`. Abstract: "The prominent role."

Discussion, verbatim: "A tab role that provides prominent visual treatment to one of the tabs in supported tab bars. Only one tab can receive the prominent treatment. When there are no tabs with an explicit `.prominent` role, then a `.search` role tab may receive the prominent visual treatment by default."

The June 2026 updates bullet is "Set the [TabRole/prominent] role on a tab to place the tab in a separate, trailing position of the tab bar." The finding's "TabRole.prominent" is that link rendered as text.

WWDC26-269 code (5:12): `TabView { Tab { EventsTab() } Tab { HolidaysTab() } Tab { FunTab() } Tab(role: .prominent) { CartTab() } }`. Transcript: "The shopping cart tab is displayed on the bottom trailing edge of the screen ... I'm using the new prominent tab role to make it stand out."
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabrole/prominent
- **Notes:** Sources:
- apple-doc JSON tabrole/prominent and tabrole (members: prominent, search; TabRole iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, watchOS 11.0).
- apple-doc updates/swiftui June 2026, Tab bars. The raw inline content is text "Set the ", then a reference to doc://.../SwiftUI/TabRole/prominent, then text " role on a tab to place the tab in a separate, trailing position of the tab bar."
- apple-video WWDC26-269.

The skill characterization is accurate: only `role: .search` is used for tabs (patterns/glass-tab-bar.md:20, references/01-api-reference.md:364, examples/09-HealthTodayScreen.swift:34).

Relevant for a rewrite: the .search tab's separate trailing treatment now interacts with .prominent, and only one tab can be prominent. Gate with `#available(iOS 27, *)`.

## Finding 21 — **CONFIRMED**

> The only sheet transition variant taught is zoom.

- **Established truth:** `static var crossFade: CrossFadeNavigationTransition { get }` is a NavigationTransition member, available when Self is CrossFadeNavigationTransition. Abstract: "A navigation transition that cross-fades between the appearing view and the disappearing view." Discussion, verbatim: "Specify this transition in a sheet to have it appear by fading in over the content, as opposed to moving upwards to cover content."

Doc sample, inside a VStack whose `Button("Show Sheet")` sets `@State showSheet`: `.sheet(isPresented: $showSheet) { Text("Sheet Content").presentationDetents([.medium]).navigationTransition(.crossFade) }`.

Availability is iOS, iPadOS, Mac Catalyst, tvOS, visionOS and watchOS 27.0, the same for `struct CrossFadeNavigationTransition`. macOS is not listed, although the NavigationTransition protocol lists macOS 15.0. So "not available on macOS" is the correct reading, even though the docs never say "unavailable" outright.

The June 2026 updates page says: "Specify the crossFade transition to have a sheet appear by fading in over content."
- **Evidence:** https://developer.apple.com/documentation/swiftui/navigationtransition/crossfade
- **Notes:** Sources:
- apple-doc JSON: navigationtransition/crossfade, crossfadenavigationtransition (conforms to NavigationTransition, Sendable, SendableMetatype), navigationtransition (built-ins: automatic, crossFade, zoom(sourceID:in:)), and updates/swiftui June 2026 Transitions.
- The WWDC26-269 transcript does not mention crossFade.
- No crossFade entry exists in the iOS 27 release notes. The only navigationTransition note is a fullScreenCover/zoom keyboard fix (178421089).

The skill characterization is accurate. Sheet transitions in the skill are zoom only: patterns/glass-modal-sheet.md:64-75, references/01-api-reference.md:443-452, and references/04-motion-and-interaction.md:181-193. Gate any use with `#available(iOS 27, *)`.

