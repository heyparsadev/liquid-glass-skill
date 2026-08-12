# Pattern — Glass Search Field

## Problem
A native iOS 26 search field that lives in the nav bar, collapses to an icon when not in use, and supports tokens / suggestions.

## Solution — basic

```swift
struct LibraryView: View {
    @State private var query = ""
    @State private var results: [Track] = []

    var body: some View {
        NavigationStack {
            List(results) { track in
                TrackRow(track: track)
            }
            .navigationTitle("Library")
            .searchable(text: $query, prompt: "Search tracks, albums, artists")
            .searchToolbarBehavior(.minimize)
            .onChange(of: query) { _, new in
                results = lookup(new)
            }
        }
    }
}
```

The system renders the glass search field with proper iOS 26 styling automatically.

## Variations

### Search scope picker (tabs above results)
```swift
@State private var scope: Scope = .all

.searchable(text: $query)
.searchScopes($scope, activation: .onSearchPresentation) {
    Text("All").tag(Scope.all)
    Text("Songs").tag(Scope.songs)
    Text("Albums").tag(Scope.albums)
}
```

### Search suggestions (typeahead)
```swift
.searchable(text: $query)
.searchSuggestions {
    ForEach(suggestions) { s in
        Label(s.title, systemImage: s.icon)
            .searchCompletion(s.title)
    }
}
```

### Search field in the bottom toolbar
```swift
.toolbar {
    ToolbarItem(placement: .bottomBar) {
        DefaultToolbarItem(kind: .search, placement: .bottomBar)
    }
}
.searchable(text: $query)
```

This pins the search field above the tab bar — common in media apps where search is a destination rather than a global tool.

### Dedicated search tab
```swift
TabView {
    Tab("Home", systemImage: "house") { Home() }
    Tab("Search", systemImage: "magnifyingglass", role: .search) {
        NavigationStack { SearchResults() }
    }
}
.searchable(text: $query)
```

When the search tab is active, the search field automatically takes prominence in the nav layer.

## Gotchas

- Don't wrap a `TextField` and apply `.glassEffect()` to roll your own search field — you'll miss the system's adaptive Reduce Transparency / Tinted Mode handling.
- `.searchToolbarBehavior(.minimize)` is the right default for content-heavy screens. Use the standard (non-minimized) behavior when search is the primary task on the screen.
- `searchSuggestions` views inherit glass when wrapped in a system surface — don't add `.glassEffect()` to them.
