# Pattern: glass tab bar

## Problem
You want a tab bar that floats above content as glass, includes system search, can minimize on scroll, and can carry a persistent accessory such as a mini player.

## Solution (iOS 26)

```swift
struct AppShell: View {
    @State private var query = ""

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack { HomeView() }
            }
            Tab("Library", systemImage: "books.vertical") {
                NavigationStack { LibraryView() }
            }
            Tab(role: .search) {                         // system label, trailing position
                NavigationStack { SearchView() }
            }
        }
        .searchable(text: $query)                        // on the TabView
        .tabBarMinimizeBehavior(.onScrollDown)           // iPhone only
        .tabViewStyle(.sidebarAdaptable)                 // sidebar on iPad and Mac
    }
}
```

- **Search tab.** On iPhone, selecting it makes "a search field take the place of the tab bar". On iPad and Mac the field "appears centered above your app's browsing suggestions". The system separates the search tab and places it at the trailing end.
- **Minimize behavior.** `TabBarMinimizeBehavior` has `.automatic`, `.never`, `.onScrollDown`, and `.onScrollUp`. "Minimizing is supported for tab bars on only iPhone." It follows the scroll view in the selected tab.

## Variation: persistent bottom accessory

```swift
TabView { … }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory {                            // iOS, iPadOS, Mac Catalyst
        NowPlayingBar()
    }

struct NowPlayingBar: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement   // Optional

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6).fill(.tint).frame(width: 32, height: 32)
            if placement == .expanded {                  // .inline: shares the row with the minimized tab bar
                VStack(alignment: .leading) {
                    Text("Track title").font(.subheadline.weight(.semibold))
                    Text("Artist").font(.caption).foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }
            Spacer()
            Button("Play", systemImage: "play.fill") { }
                .labelStyle(.iconOnly)                   // plain: the accessory is already glass
        }
        .padding(.horizontal)
    }
}
```

- `TabViewBottomAccessoryPlacement` has two cases: `.expanded` ("expanded on top of the bottom tab bar") and `.inline` ("in line with the bottom tab bar"). There is no `.collapsed`.
- **iOS 26.1+.** `tabViewBottomAccessory(isEnabled: player.hasItem) { … }` shows and hides the accessory without wrapping it in an `if`.

## iOS 27 variation: a prominent tab

```swift
TabView {
    Tab("Shop", systemImage: "bag") { ShopView() }
    Tab("Orders", systemImage: "shippingbox") { OrdersView() }
    Tab("Cart", systemImage: "cart", role: cartRole) { CartView() }   // separate, trailing
}

private var cartRole: TabRole? {                         // gate for a 26.0 target
    if #available(iOS 27.0, *) { return .prominent }
    return nil
}
```

- Only one tab can be prominent.
- Without an explicit `.prominent`, a `.search` tab "may receive the prominent visual treatment by default".
- Use a prominent tab instead of a floating glass button that imitates a separate tab.

## iPhone Duo (iOS 27.1)
The tab bar moves to a vertical bar at the side, except on the inner display in portrait. Keep the default placement. `.toolbarVerticalBehavior(.disabled)` (27.1, beta) exists for the cases Apple lists, such as full-screen video.

## Gotchas
- Don't put a custom search field inside the `.search` tab. Put `.searchable` on the `TabView`.
- Apply `.tabViewBottomAccessory` to the `TabView` itself.
- Controls inside the accessory use plain styles. `.buttonStyle(.glass)` there would be glass on glass.
- To hide the tab bar inside a stack, use `.toolbarVisibility(.hidden, for: .tabBar)`. The older `.toolbar(.hidden, for: .tabBar)` is deprecated as of 27.2.
- **iOS 27 SDK.** Never bind `TabView(selection:)` to a tab that is hidden or conditional. Apple says it "might crash".
