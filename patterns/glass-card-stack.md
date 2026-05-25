# Pattern — Glass Card Stack

## Problem
A scrollable column of cards where the *headers* (or pinned chips on top of each card) are glass, while the card body stays solid content. Glass marks the chrome; the card itself doesn't try to be glass.

## Solution

```swift
struct CardStack: View {
    let items: [Item]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    Card(item: item)
                }
            }
            .padding()
        }
    }
}

struct Card: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(item.cover)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(item.tag)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .glassEffect()
                        .padding(12)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title).font(.headline)
                Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}
```

The glass tag chip is the **only** glass on the card — it sits over photographic content (the cover image) where lensing actually has something to lens.

## Variations

### Action button overlaid on cover
```swift
.overlay(alignment: .bottomTrailing) {
    Button(action: {}) {
        Image(systemName: "plus")
            .font(.title2)
            .frame(width: 44, height: 44)
    }
    .buttonStyle(.glassProminent)
    .buttonBorderShape(.circle)
    .tint(.blue)
    .padding(12)
}
```

### Multiple chips on one cover — group them
```swift
.overlay(alignment: .topLeading) {
    GlassEffectContainer(spacing: 6) {
        HStack(spacing: 6) {
            Text("New").chipStyle()
            Text("Featured").chipStyle().tint(.orange)
        }
    }
    .padding(12)
}
```

## Gotchas

- The card body uses `.background(.background)` — a system **solid**, not glass. Resist the urge to glass-ify it.
- Shadows on cards: subtle (`opacity 0.08`, radius 12). Anything heavier looks pre-iOS-26.
- The chip's corner is implied by `.glassEffect()`'s default `.capsule`. If the chip wraps to two lines, switch to `.rect(cornerRadius: .containerConcentric)`.
