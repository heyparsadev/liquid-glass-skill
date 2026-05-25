# Pattern — Glass Tab Bar

## Problem
A tab bar that floats above content as a glass slab, collapses on scroll, and supports a persistent bottom accessory (Now Playing strip, mini-player).

## Solution

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
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                NavigationStack { SearchView() }
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                NavigationStack { ProfileView() }
            }
        }
        .searchable(text: $query)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
```

## Variations

### Persistent bottom accessory (Now Playing)
```swift
TabView { /* tabs */ }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory {
        NowPlayingStrip()
    }
```

Inside the accessory, react to whether it's expanded or collapsed:

```swift
struct NowPlayingStrip: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement

    var body: some View {
        HStack {
            Image("artwork").resizable().frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            if placement == .expanded {
                VStack(alignment: .leading) {
                    Text("Track name").bold()
                    Text("Artist").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: {}) { Image(systemName: "play.fill") }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
        }
        .padding(.horizontal)
    }
}
```

### Force tab bar to stay full size
```swift
.tabBarMinimizeBehavior(.never)
```

### Hide tab bar within a deep navigation
```swift
NavigationStack {
    HomeView()
        .toolbar(.hidden, for: .tabBar)   // hides only within this stack
}
```

## Gotchas

- The `role: .search` tab is special: it surfaces the system search field at the top of the screen automatically. Don't put a custom search field inside it.
- `.tabBarMinimizeBehavior(.onScrollDown)` only works inside a tab whose root is a scrollable view (`ScrollView`, `List`, etc.).
- `.tabViewBottomAccessory` must be applied to the `TabView` itself, not to a child.
