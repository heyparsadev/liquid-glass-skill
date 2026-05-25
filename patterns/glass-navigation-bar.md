# Pattern — Glass Navigation Bar

## Problem
A navigation bar that feels native to iOS 26: floats above content, lenses what's behind it, collapses gracefully on scroll.

## Solution
Use `NavigationStack` — it's glass by default. Don't add `.glassEffect()` to it.

```swift
NavigationStack {
    ScrollView {
        LazyVStack(spacing: 16) {
            ForEach(items) { item in
                Card(item: item)
            }
        }
        .padding()
    }
    .navigationTitle("Discover")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Filter", systemImage: "line.3.horizontal.decrease") { }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Profile", systemImage: "person.crop.circle") { }
        }
    }
}
```

## Variations

### Tinted nav bar items
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button("Save", systemImage: "checkmark") { }
            .buttonStyle(.glassProminent)
            .tint(.blue)
    }
}
```

### Search in nav bar
```swift
NavigationStack { ContentView() }
    .searchable(text: $query)
    .searchToolbarBehavior(.minimized)
```

### Large title that fades into glass on scroll
This is the default `NavigationStack` behavior — no extra code needed.

## Gotchas

- **Don't** apply `.glassEffect()` to a custom `HStack` you're using as a nav bar — you'll get glass-on-glass when paired with a real nav bar elsewhere.
- **Don't** use `.toolbarBackground(.regularMaterial, ...)` — that's the legacy material API. The iOS 26 default already gives you Liquid Glass.
- For a full-bleed image (no nav bar background), use `.toolbarBackground(.hidden, for: .navigationBar)` — items still float as glass shapes individually.
