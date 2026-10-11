# Pattern: search

## Problem
You want native Liquid Glass search: in the right place on each device, collapsible when it isn't the main task, and with scopes and suggestions.

## Solution: basic

```swift
struct LibraryView: View {
    @State private var query = ""
    let tracks: [Track]

    var results: [Track] {
        query.isEmpty ? tracks : tracks.filter { $0.title.localizedStandardContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(results) { track in
                TrackRow(track: track)
            }
            .navigationTitle("Library")
        }
        .searchable(text: $query, prompt: "Songs, artists, albums")
        .searchToolbarBehavior(.minimize)                 // collapses to a button until tapped
    }
}
```

- **Where it goes.** Toolbar search sits at the **bottom** of the screen on iPhone. "Place search at the bottom if there's room" (HIG). The top toolbar is the alternative.
- **`.minimize`** (`SearchToolbarBehavior`: `.automatic`, `.minimize`) suits screens where search is secondary. Leave it out when search is the main task. Apply it after `.searchable`. The member is `.minimize`, not `.minimized`.
- **A search field in the scroll content** gets standard content styling, not glass. That is expected.

## Variation: search among bottom-bar items

`DefaultToolbarItem` is `ToolbarContent`. Put it directly in `.toolbar { }`:

```swift
.toolbar {
    ToolbarItem(placement: .bottomBar) {
        Button("New Playlist", systemImage: "plus") { }
    }
    ToolbarSpacer(.flexible, placement: .bottomBar)
    DefaultToolbarItem(kind: .search, placement: .bottomBar)
}
.searchable(text: $query)
```

## Variation: a search tab

```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab(role: .search) {
        NavigationStack { SearchLanding() }
    }
}
.searchable(text: $query)                                 // on the TabView
```

- **iPhone.** The search field "takes the place of the tab bar".
- **iPad and Mac.** The field appears centered above the browsing suggestions.
- **Choosing a style (HIG, June 2026).** Use a standard tab when the landing page is worth exploring. Use the button appearance, which focuses the field and shows the keyboard, for quick lookup.
- **iOS 27.** A `.search` tab may get the prominent treatment when no tab is explicitly `.prominent`.

## Variation: scopes and suggestions

```swift
@State private var scope: Scope = .all

.searchable(text: $query)
.searchScopes($scope, activation: .onSearchPresentation) {
    Text("All").tag(Scope.all)
    Text("Songs").tag(Scope.songs)
    Text("Albums").tag(Scope.albums)
}
.searchSuggestions {
    ForEach(suggestions) { s in
        Label(s.title, systemImage: s.symbol).searchCompletion(s.title)
    }
}
```

## iOS 27 notes
- `.searchable(text:placement: .toolbarPrincipal)` makes the navigation bar minimize automatically. Opt out with `.toolbarMinimizationBehavior(.never, for: .navigationBar)`.
- A custom field next to capsule glass buttons, such as a filter bar, can use `.textFieldStyle(.bordered)` with `.textInputBorderShape(.capsule)` to match.

## Gotchas
- Don't hand-roll a glass search field (`TextField` plus `.glassEffect()`). You lose placement, minimization, the search tab, keyboard handling, and accessibility.
- Don't add `.glassEffect()` to suggestions or scope bars. They render inside the system's glass.
- `DefaultToolbarItem` inside `ToolbarItem { }` doesn't compile.
