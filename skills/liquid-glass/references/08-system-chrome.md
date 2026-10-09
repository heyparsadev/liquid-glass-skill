# System chrome: toolbars, tab bars, search, and sheets

Navigation bars, toolbars, tab bars, search fields, sheets, popovers, menus, and alerts adopt Liquid Glass automatically when you build with the iOS 26 or 27 SDK. Your job is to **configure** them, not to re-glass them. This file lists the configuration APIs, with exact declarations from Apple's documentation (October 2026), for iOS 26 and the iOS 27 additions.

## Contents

1. [Ground rules](#1-ground-rules)
2. [Toolbars and the navigation bar (iOS 26)](#2-toolbars-and-the-navigation-bar-ios-26)
3. [Toolbars in iOS 27](#3-toolbars-in-ios-27)
4. [Tab bars](#4-tab-bars)
5. [Search](#5-search)
6. [Scroll edge effects](#6-scroll-edge-effects)
7. [Sheets, popovers, and dialogs](#7-sheets-popovers-and-dialogs)
8. [iPhone Duo and vertical bars (iOS 27.1)](#8-iphone-duo-and-vertical-bars-ios-271)
9. [Gating iOS 27 chrome APIs on a 26 target](#9-gating-ios-27-chrome-apis-on-a-26-target)

---

## 1. Ground rules

- **Never add `.glassEffect()` to a bar, toolbar item, tab bar, or sheet.** It produces glass on glass.
- **Remove custom bar backgrounds.** Delete `toolbarBackground(Color…)`, colored `UINavigationBarAppearance`, and the like. Apple: "Reduce the use of toolbar backgrounds and tinted controls" (HIG Toolbars).
- **Keep bar items monochrome.** Apple's toolbar symbols "automatically receive appropriate coloring and vibrancy". Tint icons only "to convey meaning, like a call to action or next step, but not just for visual effect" (WWDC25 323).
- **Use at most one primary action per bar,** on the trailing side, styled prominent.
- **Toolbar modifiers belong on toolbar content, not on the button inside it.** `sharedBackgroundVisibility`, `visibilityPriority`, `hidden`, `matchedTransitionSource`, and `contentMarginsRemoved` all return `some ToolbarContent`, so apply them to the `ToolbarItem` or `ToolbarItemGroup`.

---

## 2. Toolbars and the navigation bar (iOS 26)

### Grouping

Items in the same placement share one glass background. Group related actions with `ToolbarItemGroup`. Groups "provide space between items and other groups automatically, and adapt as the available space changes" (HIG).

```swift
NavigationStack {
    NoteEditor()
        .navigationTitle("Note")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Share", systemImage: "square.and.arrow.up") { }
                Button("Favorite", systemImage: "heart") { }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { }
                    .buttonStyle(.glassProminent)          // the one primary action
            }
        }
}
```

Placements the skill uses are `.topBarLeading`, `.topBarTrailing`, `.bottomBar`, `.principal`, `.confirmationAction`, and `.cancellationAction`. iOS 26 adds `.largeTitle` and `.subtitle` placements on iOS, iPadOS, and Mac Catalyst.

### `ToolbarSpacer`

```swift
nonisolated init(_ sizing: SpacerSizing = .flexible, placement: ToolbarItemPlacement = .automatic)
// SpacerSizing: .fixed, .flexible     iOS, iPadOS, Mac Catalyst, macOS 26.0 (no tvOS, watchOS, visionOS)
```

A spacer splits items that share a placement into separate glass groups. Prefer `ToolbarItemGroup` to manual spacing. Apple asks you to audit "your use of fixed spacers", and on iPhone Duo fixed spacers keep their size even in vertical bars. Reserve `.fixed` for separating adjacent text-labeled buttons.

```swift
ToolbarSpacer(.fixed, placement: .topBarTrailing)
```

### `sharedBackgroundVisibility(_:)`

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
// iOS, iPadOS, Mac Catalyst, macOS 26.0
```

"Hiding the effect will cause the item to be placed in its own grouping." Apply it to the `ToolbarItem`:

```swift
ToolbarItem(placement: .topBarTrailing) {
    AvatarButton()
}
.sharedBackgroundVisibility(.hidden)
```

### Badges

Badges "appear in list rows, tab bars, toolbar items, and menus". Put `.badge` on the item's content. The badge carries the status, so don't also tint the icon red.

```swift
ToolbarItem(placement: .topBarTrailing) {
    Button("Notifications", systemImage: "bell") { }
        .badge(unreadCount)
}
```

### Hiding items: `ToolbarContent.hidden(_:)` (iOS 26.4)

This hides an item without leaving an empty glass slot behind. Apple recommends it in *Adopting Liquid Glass*.

```swift
nonisolated func hidden(_ hidden: Bool = true) -> some ToolbarContent
// iOS, iPadOS, Mac Catalyst, visionOS 26.4; macOS 15.0
```

### Zoom from a toolbar item: `ToolbarContent.matchedTransitionSource(id:in:)`

```swift
nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some ToolbarContent
// iOS, iPadOS, Mac Catalyst 26.0
```

```swift
@Namespace private var ns
@State private var showNew = false

content
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button("New", systemImage: "plus") { showNew = true }
        }
        .matchedTransitionSource(id: "new", in: ns)
    }
    .sheet(isPresented: $showNew) {
        NewItemView()
            .navigationTransition(.zoom(sourceID: "new", in: ns))
    }
```

### Hiding a bar's background and the bar itself

Two older spellings carry `deprecatedAt: 27.2` and are renamed:

| Deprecated (27.2) | Use (iOS 18+) |
|---|---|
| `.toolbarBackground(.hidden, for: .navigationBar)` | `.toolbarBackgroundVisibility(.hidden, for: .navigationBar)` |
| `.toolbar(.hidden, for: .tabBar)` | `.toolbarVisibility(.hidden, for: .tabBar)` |

The `toolbarBackground(_ style: some ShapeStyle, for:)` overload is not deprecated. Still, don't use it to color glass bars.

---

## 3. Toolbars in iOS 27

All of these are **iOS 27.0+**. On a 26 deployment target, gate them as shown in [§9](#9-gating-ios-27-chrome-apis-on-a-26-target).

### Navigation bar minimization: `toolbarMinimizationBehavior(_:for:)`

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior,
                                             for bars: ToolbarPlacement...) -> some View
// ToolbarMinimizationBehavior: .automatic, .never, .onScrollDown, .onScrollUp
// iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS, watchOS 27.0
```

"The supported placement is navigationBar. When the navigation bar minimizes, an integrated top tab bar will also minimize."

> ⚠️ The WWDC26 session video spells it `toolbarMinimizeBehavior(_:for:)`. That name does not exist in the shipping SDK. The release notes say the new modifier "replaces toolbarMinimizeBehavior".

```swift
NavigationStack {
    List(messages) { MessageRow(message: $0) }
        .navigationTitle("Inbox")
        .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
}
```

- **`.automatic`** lets the system decide. On iOS, navigation bars minimize by default when the view has `.searchable(…, placement: .toolbarPrincipal)`. Opt out with `.never`.
- **`toolbarMinimizationRestoration(_:for:)`** takes `.automatic` or `.atScrollEdge`. By default, the bar comes back when the scroll direction reverses. `.atScrollEdge` waits until the content reaches the edge. It applies only to `navigationBar` with `.onScrollDown`.
- **`toolbarMinimizationSafeAreaAdjustment(_:for:)`** takes `.automatic`, `.disabled`, or `.enabled`. By default, the safe area adjusts as the bar minimizes. Use `.disabled` for full-bleed media that shouldn't reflow. Only `navigationBar` is supported.
- For tab bars, keep using `tabBarMinimizeBehavior(_:)` ([§4](#4-tab-bars)). It is not deprecated.

### Keeping key items visible: `visibilityPriority(_:)`

```swift
@MainActor func visibilityPriority(_ priority: ToolbarItemVisibilityPriority) -> some ToolbarContent
// ToolbarItemVisibilityPriority: .automatic, .low, .high, init(lowerThan:), init(higherThan:)
// iOS, iPadOS, Mac Catalyst, tvOS, visionOS, watchOS 27.0; macOS 26.1
```

"When toolbar space is limited, items with a lower priority move into the overflow menu before items with a higher priority."

```swift
.toolbar {
    ToolbarItemGroup(placement: .topBarTrailing) {
        Button("Undo", systemImage: "arrow.uturn.backward") { }
        Button("Redo", systemImage: "arrow.uturn.forward") { }
    }
    .visibilityPriority(.high)
}
```

### Overflow menu: `ToolbarOverflowMenu` and `toolbarOverflowMenu(content:)`

```swift
nonisolated struct ToolbarOverflowMenu<Content> where Content : View        // ToolbarContent
nonisolated func toolbarOverflowMenu<C>(@ContentBuilder content: () -> C) -> some View where C : View
// iOS, iPadOS, Mac Catalyst, visionOS 27.0 (not macOS, tvOS, watchOS)
```

These hold actions that "are always placed in the toolbar's overflow menu, regardless of the toolbar mode, platform, or customizability." On iOS this is the overflow menu in the navigation bar. Move a hand-made "…" `Menu` into it. The HIG says to "use the system overflow menu" and to reserve the ellipsis symbol for overflow.

```swift
List(messages) { MessageRow(message: $0) }
    .toolbarOverflowMenu {
        Button("Select Messages", systemImage: "checkmark.circle") { }
        Button("Mark All as Read", systemImage: "envelope.open") { }
    }
```

Inside a `.toolbar { }` builder, use the struct. Its `init(@ContentBuilder content:)` takes several items:

```swift
.toolbar {
    ToolbarOverflowMenu {
        Button("Archive", systemImage: "archivebox") { }
        Button("Move to Junk", systemImage: "xmark.bin") { }
    }
}
```

### Pinned trailing item: `.topBarPinnedTrailing`

```swift
static let topBarPinnedTrailing: ToolbarItemPlacement      // iOS, iPadOS, Mac Catalyst, visionOS 27.0
```

"Pinned items only move to the overflow menu when search is active and there isn't enough room." Use it for the one action that must stay put, such as Compose.

```swift
ToolbarItem(placement: .topBarPinnedTrailing) {
    Button("Compose", systemImage: "square.and.pencil") { }
}
```

### Edge-to-edge item content: `contentMarginsRemoved(_:)`

```swift
nonisolated func contentMarginsRemoved(_ removed: Bool = true) -> some ToolbarContent   // 27.0, all platforms
```

This removes the default padding inside a toolbar item, for avatars or progress rings that should fill the glass item. Use it instead of negative padding.

### Status bar: `ToolbarPlacement.statusBar`

```swift
static var statusBar: ToolbarPlacement { get }              // iOS, iPadOS, Mac Catalyst 27.0
```

It works only with `toolbarVisibility(_:for:)` and `toolbarColorScheme(_:for:)`:

```swift
.toolbarVisibility(isImmersive ? .hidden : .automatic, for: .statusBar)
.toolbarColorScheme(.dark, for: .statusBar)
```

`statusBarHidden(_:)` carries `deprecatedAt: 27.2` ("Use .toolbarVisibility(_, for: .statusBar) instead").

### `ContentBuilder` (Xcode 27)

`typealias ContentBuilder = ViewBuilder` is "the unified replacement for type-specific builders like ToolbarContentBuilder". Existing `@ToolbarContentBuilder` and `@ViewBuilder` code keeps compiling. Apple's technote TN3211 covers the few source breaks.

---

## 4. Tab bars

### The `Tab` API and the search tab

```swift
TabView {
    Tab("Home", systemImage: "house") { NavigationStack { HomeView() } }
    Tab("Library", systemImage: "books.vertical") { NavigationStack { LibraryView() } }
    Tab(role: .search) { NavigationStack { SearchView() } }   // system label
}
.searchable(text: $query)                                     // on the TabView
.tabBarMinimizeBehavior(.onScrollDown)
```

- **Setup.** Set `role: .search` on one tab and put `.searchable` on the `TabView` (WWDC25 323). Don't build a custom search field inside that tab.
- **iPhone.** "When someone selects this tab, a search field takes the place of the tab bar, and the content of the tab is shown."
- **iPad and Mac.** "The search field appears centered above your app's browsing suggestions."
- **Position.** "The system automatically separates the search tab from other tabs and places it at the trailing end."
- **Styles (HIG Search fields, June 2026).** A *standard tab* opens a search landing page with the field at the top, which is best for exploratory content. A *button appearance* focuses the field and shows the keyboard, which is best for quick lookup. In iOS 27, a `.search` tab "may receive the prominent visual treatment by default" when no tab is explicitly `.prominent`.
- **`tabViewSearchActivation(_:)`** (`TabSearchActivation`, 26.0) configures "the activation behavior of search in the search tab". `.searchTabSelection` "links the search tab's selection to search activation"; `.automatic` is the default.

### Minimizing: `tabBarMinimizeBehavior(_:)`

```swift
nonisolated func tabBarMinimizeBehavior(_ behavior: TabBarMinimizeBehavior) -> some View
// TabBarMinimizeBehavior: .automatic, .never, .onScrollDown, .onScrollUp     26.0
```

"Minimizing is supported for tab bars on only iPhone." Minimizing follows the scroll view in the selected tab, so it needs scrollable content.

### Bottom accessory: `tabViewBottomAccessory`

```swift
nonisolated func tabViewBottomAccessory<Content: View>(@ContentBuilder content: () -> Content) -> some View
// iOS, iPadOS, Mac Catalyst 26.0
nonisolated func tabViewBottomAccessory<Content: View>(isEnabled: Bool, @ContentBuilder content: () -> Content) -> some View
// iOS, iPadOS, Mac Catalyst 26.1

var tabViewBottomAccessoryPlacement: TabViewBottomAccessoryPlacement? { get }   // environment
// TabViewBottomAccessoryPlacement: .expanded, .inline        (Optional: nil = undefined)
```

```swift
TabView { … }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory {
        NowPlayingBar()
    }

struct NowPlayingBar: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        HStack {
            Artwork().frame(width: 32, height: 32)
            if placement == .expanded {          // .expanded: above the tab bar; .inline: in line with the tab bar
                Text("Track title").lineLimit(1)
            }
            Spacer()
            Button("Play", systemImage: "play.fill") { }
                .labelStyle(.iconOnly)           // plain button: the accessory is already glass
        }
        .padding(.horizontal)
    }
}
```

- Apply the accessory to the `TabView` itself.
- The accessory is drawn on glass by the system. Controls inside it use plain or borderless styles, never `.buttonStyle(.glass)` or `glassEffect` (that would be glass on glass).
- On iOS 26.1+, prefer `isEnabled:` to an `if` around the content when the accessory comes and goes.

### Sidebar on iPad and Mac

Use `.tabViewStyle(.sidebarAdaptable)` (iOS 18+) so the tab bar can turn into a sidebar. Apple recommends it in *Adopting Liquid Glass*.

### iOS 27: prominent tab, `TabRole.prominent`

```swift
static var prominent: TabRole { get }                      // all platforms 27.0
```

"Set the prominent role on a tab to place the tab in a separate, trailing position of the tab bar." Only one tab can be prominent. In UIKit, "the prominent tab is always visible, even when the tab bar collapses during scrolling."

```swift
Tab("Cart", systemImage: "cart", role: .prominent) { CartView() }
```

Use it instead of a hand-made floating glass button that imitates a separated tab.

### iOS 27 SDK: selection must be visible

"A TabView enforces that its selection is set to a visible tab. TabView might crash when its selection is set to a hidden or otherwise unavailable tab." Never bind `TabView(selection:)` to a tab you hide conditionally.

---

## 5. Search

```swift
NavigationStack {
    ResultsList()
        .navigationTitle("Library")
}
.searchable(text: $query, prompt: "Songs, artists, albums")
.searchToolbarBehavior(.minimize)                // place after .searchable
```

- **Placement.** Toolbar search sits at the **bottom** on iPhone. "Place search at the bottom if there's room" (HIG). The top toolbar is the alternative.
- **`searchToolbarBehavior(_:)`** (`SearchToolbarBehavior`: `.automatic`, `.minimize`, 26.0). `.minimize` collapses search into a toolbar button until tapped. Use it when search isn't the main task on the screen. The member is `.minimize`, not `.minimized`, even though one Apple sample misspells it.
- **A field in the scroll content** gets standard content styling, not glass: "Depending on where your Search Field is placed, it will automatically adopt the correct presentation style" (WWDC26).
- **iOS 27.** `.searchable(…, placement: .toolbarPrincipal)` makes the navigation bar minimize automatically ([§3](#3-toolbars-in-ios-27)).

### Search among other bottom-bar items

`DefaultToolbarItem` is itself `ToolbarContent`. Put it **directly** in `.toolbar { }`, never inside a `ToolbarItem`:

```swift
// nonisolated init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)   26.0
.toolbar {
    ToolbarItem(placement: .bottomBar) {
        Button("Filter", systemImage: "line.3.horizontal.decrease") { }
    }
    ToolbarSpacer(.flexible, placement: .bottomBar)
    DefaultToolbarItem(kind: .search, placement: .bottomBar)
}
.searchable(text: $query)
```

### Scopes and suggestions

These work as before (iOS 16+) and render in the system's glass search UI.

```swift
.searchable(text: $query)
.searchScopes($scope, activation: .onSearchPresentation) {
    Text("All").tag(Scope.all)
    Text("Songs").tag(Scope.songs)
}
.searchSuggestions {
    ForEach(suggestions) { s in
        Label(s.title, systemImage: s.symbol).searchCompletion(s.title)
    }
}
```

### Custom text fields next to glass buttons (iOS 27)

To match a text field's border to capsule glass buttons, use `textInputBorderShape(_:)` (`TextInputBorderShape`: `.automatic`, `.capsule`, `.roundedRectangle`) with `.textFieldStyle(.bordered)`. All are 27.0. Don't hand-roll a glass `TextField` for search.

```swift
HStack {
    TextField("Search", text: $text)
    Button("Go", action: search)
}
.textFieldStyle(.bordered)
.buttonBorderShape(.capsule)
.textInputBorderShape(.capsule)
```

`.roundedBorder` and `.squareBorder` carry `deprecatedAt: 27.2` ("Use `textFieldStyle(.bordered)` with `textInputBorderShape(.roundedRectangle)`").

---

## 6. Scroll edge effects

When content scrolls under floating glass bars, a **scroll edge effect** keeps the bar legible. Standard bars get it automatically.

```swift
nonisolated func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View
nonisolated func scrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View
// ScrollEdgeEffectStyle: .automatic, .hard, .soft
// iOS, iPadOS, Mac Catalyst, macOS, tvOS, watchOS 26.0
```

HIG Scroll views (June 2026) gives four rules:
- "Prefer the automatic scroll edge effect style." If you use `.soft`, test it thoroughly.
- "Only use a scroll edge effect when a scroll view is behind floating interface elements."
- "Apply one scroll edge effect per view."
- Scroll edge effects aren't decorative.

**iOS 27.** "The .automatic style no longer switches between the existing soft and hard styles but provides its own visuals." A uniform toolbar appears across the top when content scrolls under floating bars. Re-evaluate any `.soft` override, which "no longer matches the default system appearance."

For custom floating bars, attach them with `safeAreaBar(edge:)` ([01 §9](01-api-reference.md#9-background-extension-and-custom-bars)) so they join the scroll edge effect. Don't paint your own gradient scrim under bars.

---

## 7. Sheets, popovers, and dialogs

Sheets have a Liquid Glass background. At partial-height detents they float inset from the screen edges.

```swift
.sheet(isPresented: $showDetails) {
    NavigationStack {
        DetailsList()
            .scrollContentBackground(.hidden)              // List and Form only: lets the sheet's glass show
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }     // standard Close (xmark), iOS 26
                }
            }
    }
    .presentationDetents([.medium, .large])
    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
}
```

- **Don't set `presentationBackground(_:)`.** A custom background replaces the system glass. Apple's guidance is to remove custom presentation backgrounds.
- **`scrollContentBackground(.hidden)`** only matters on `List`, `Form`, and other views with a system background. A plain `ScrollView` has none.
- **Background interaction.** `.presentationBackgroundInteraction(.enabled(upThrough: .medium))` only works if `.medium` is one of the detents.
- **Button placement (HIG Sheets, March 2026).**
  - Single-view sheet: Cancel goes on the leading edge, Done on the trailing edge.
  - Informational sheet: use the standard Close (✕) button.
  - Always pair Done with Cancel, or with Back in a multi-step sheet. Never show all three.
- **Dialogs morph out of their button.** "In the new design, dialogs also automatically morph out of the buttons that present them" (WWDC25 323). Attach `.confirmationDialog` or `.alert` to the presenting `Button`, not to the whole list or screen.
- **Zoom transitions.** Use `matchedTransitionSource(id:in:)` on a button, or on a `ToolbarItem` ([§2](#2-toolbars-and-the-navigation-bar-ios-26)), plus `.navigationTransition(.zoom(sourceID:in:))` on the sheet content.

### iOS 27 additions

```swift
// Fade the sheet in over content instead of sliding up (27.0; not macOS)
.sheet(isPresented: $showFilters) {
    FiltersView()
        .presentationDetents([.medium])
        .navigationTransition(.crossFade)
}

// Place the sheet on the leading or trailing edge. Only sheets respect it (27.0).
// PresentationPlacement: .automatic, .center, .leading, .trailing
.sheet(item: $place) { place in
    PlaceDetail(place)
        .presentationDetents([.medium, .large])
        .presentationPlacement(.leading)
}
```

- **Control styling resets in sheets.** In apps built with the 27 SDK, `controlSize`, `buttonSizing`, `buttonRepeatBehavior`, `menuIndicatorVisibility`, and `ButtonBorderShape` reset to their defaults inside sheets and popovers. Set them inside the presented content.
- **Data-driven dialogs.** `alert(_:item:actions:)`, `alert(error:actions:)`, `confirmationDialog(_:item:titleVisibility:actions:)`, and their `message:` variants are new in the Xcode 27 SDK. Most of them back-deploy to iOS 15.

---

## 8. iPhone Duo and vertical bars (iOS 27.1)

iPhone Duo is Apple's first folding iPhone. Apple announced it for October 23, 2026, running iOS 27.1. Starting April 2027, App Store submissions need iPhone Duo screenshots.

The HIG page *Designing for iPhone Duo* (September 2026) explains how bars move: "On iPhone Duo, toolbars, tab bars, and navigation controls that are typically at the top and bottom of the display move to the side … The exception is the inner display in portrait." Its rules for chrome:

- "In general, don't override the default bar placement."
- "Provide both a title and a symbol for each toolbar item that isn't text-only." Text-only labels stay in a horizontal bar.
- Group items with `ToolbarItemGroup`; "avoid adding fixed spacing yourself".
- Use `visibilityPriority(_:)` and the system overflow menu ([§3](#3-toolbars-in-ios-27)).
- Keep custom floating glass (palettes, action buttons) clear of the side bars and the hinge region.
- Preview the app in Device Hub in Xcode.

These APIs are **iOS/iPadOS 27.1, marked beta**:

```swift
var toolbarVerticalEdge: HorizontalEdge? { get }                        // environment; nil where no vertical bar is used
nonisolated func toolbarVerticalBehavior(_ behavior: ToolbarVerticalBehavior) -> some View   // .automatic, .disabled
nonisolated func axisBehavior(_ behavior: ToolbarItemAxisBehavior) -> some ToolbarContent    // .automatic, .horizontalOnly, .verticalPreferred
nonisolated func toolbarVerticalCompressionBehavior(_ behavior: ToolbarVerticalCompressionBehavior) -> some View
                                                                         // .automatic, .prefersTabBar, .prefersToolbarItems
struct ReservedRegion                                                    // GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)
```

Use `toolbarVerticalEdge` to place a custom floating glass palette on the side opposite the system bar. Opt out with `toolbarVerticalBehavior(.disabled)` only for the cases Apple names, such as full-screen video or calculator-like layouts.

---

## 9. Gating iOS 27 chrome APIs on a 26 target

There are three techniques, depending on what the API is.

**a. Value-level gate.** Use this when the *type* already exists and only a member is new: `TabRole`, `ToolbarItemPlacement`.

```swift
private var cartRole: TabRole? {
    if #available(iOS 27.0, *) { return .prominent }
    return nil
}
private var composePlacement: ToolbarItemPlacement {
    if #available(iOS 27.0, *) { return .topBarPinnedTrailing }
    return .topBarTrailing
}

Tab("Cart", systemImage: "cart", role: cartRole) { CartView() }
ToolbarItem(placement: composePlacement) { ComposeButton() }
```

**b. View-level gate** for new view modifiers. `ViewBuilder` handles `if #available`.

```swift
extension View {
    @ViewBuilder
    func minimizingNavigationBarOnScroll() -> some View {
        if #available(iOS 27.0, *) {
            toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
        } else {
            self
        }
    }
}
```

**c. Whole-toolbar gate** for new `ToolbarContent` modifiers, such as `visibilityPriority` and `contentMarginsRemoved`. Branch where the toolbar is attached, in a `ViewModifier`, instead of inside the toolbar builder.

```swift
struct EditorToolbar: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 27.0, *) {
            content.toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) { UndoRedoButtons() }
                    .visibilityPriority(.high)
            }
        } else {
            content.toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) { UndoRedoButtons() }
            }
        }
    }
}
```

For multiplatform targets, list every platform in the check: `#available(iOS 27.0, macOS 27.0, *)`. If the deployment target is already 27, skip the gates.

---

## Sources

- HIG: [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) · [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) · [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields) · [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets) · [Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views) · [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- SwiftUI docs: [`toolbarMinimizationBehavior(_:for:)`](https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)) · [`ToolbarOverflowMenu`](https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu) · [`TabRole.prominent`](https://developer.apple.com/documentation/swiftui/tabrole/prominent) · [`DefaultToolbarItem`](https://developer.apple.com/documentation/swiftui/defaulttoolbaritem) · [`tabViewBottomAccessory`](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(content:))
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) · [iOS & iPadOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes) · WWDC25 323 · WWDC26 269, 278, 292 · Tech talk 111462 *Raise the bar with iPhone Duo*
