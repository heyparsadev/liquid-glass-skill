# Pattern: glass navigation bar

## Problem
You want a navigation bar that floats above scrolling content as Liquid Glass, groups its actions sensibly, keeps the important ones visible, and gets out of the way on scroll.

## Solution (iOS 26)
`NavigationStack` is already glass, so configure it and don't add `.glassEffect()`.

```swift
struct DiscoverView: View {
    let items: [Item]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(items) { item in
                        ItemCard(item: item)                 // content layer: solid, no glass
                    }
                }
                .padding()
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {   // one shared glass group
                    Button("Filter", systemImage: "line.3.horizontal.decrease") { }
                    Button("Share", systemImage: "square.and.arrow.up") { }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Notifications", systemImage: "bell") { }
                        .badge(3)                            // status via badge, not a red tint
                }
            }
        }
    }
}
```

- The large title collapses into the bar on scroll by default, and a scroll edge effect keeps the bar legible.
- Group related items with `ToolbarItemGroup`. Adjacent groups get separate glass backgrounds.
- If the bar has a primary action (Done, Save), give it `.buttonStyle(.glassProminent)`, trailing. Use only one.

## iOS 27 variations
All of these are iOS 27.0+. On a 26 target, gate them as in [08 § 9](../references/08-system-chrome.md#9-gating-ios-27-chrome-apis-on-a-26-target).

```swift
.toolbar {
    ToolbarItem(placement: .topBarPinnedTrailing) {          // never overflows
        Button("Compose", systemImage: "square.and.pencil") { }
    }
    ToolbarItemGroup(placement: .topBarTrailing) {
        Button("Filter", systemImage: "line.3.horizontal.decrease") { }
    }
    .visibilityPriority(.high)                               // overflows last
}
.toolbarOverflowMenu {                                       // always in the system overflow menu
    Button("Select", systemImage: "checkmark.circle") { }
    Button("Sort", systemImage: "arrow.up.arrow.down") { }
}
.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
```

- **Minimizing.** `toolbarMinimizationBehavior(_:for:)` is the shipping name. `toolbarMinimizeBehavior` from the WWDC26 video doesn't compile.
- **Full-bleed media under the bar.** Add `.toolbarMinimizationSafeAreaAdjustment(.disabled, for: .navigationBar)` so content doesn't reflow as the bar shrinks.
- **Restoring at the top.** `.toolbarMinimizationRestoration(.atScrollEdge, for: .navigationBar)` brings the bar back only when the scroll reaches the top.
- **Automatic minimizing.** With `.searchable(…, placement: .toolbarPrincipal)`, the bar minimizes automatically on iOS 27. Use `.never` to opt out.

## iPhone Duo (iOS 27.1)
On iPhone Duo the bar's items can move to a vertical bar at the side:
- Give every item a title **and** a symbol: `Button("Share", systemImage: …)`.
- Group items rather than spacing them manually.
- Don't override the default placement.

## Gotchas
- **Hiding the bar background.** Use `.toolbarBackgroundVisibility(.hidden, for: .navigationBar)`. The older `.toolbarBackground(.hidden, for:)` is deprecated as of 27.2. Never set a color background on the bar.
- **Don't build a custom `HStack` "nav bar" with glass.** You lose minimization, scroll edge effects, overflow, and the iPhone Duo layout.
- **Toolbar modifiers go on the item.** `sharedBackgroundVisibility`, `visibilityPriority`, `hidden`, and `matchedTransitionSource` attach to the `ToolbarItem` or `ToolbarItemGroup`, not to the `Button` inside.
- **Overflow menu.** Replace a hand-made "…" `Menu` with `toolbarOverflowMenu` on iOS 27. The HIG reserves the ellipsis for the system overflow.
