# Pattern: card stack (content cards, glass controls)

## Problem
You have a scrolling column of cards with cover images, tags, and actions, and you want it to feel at home in the Liquid Glass design.

**Cards are content.** "Don't use Liquid Glass in the content layer … use standard materials for elements in the content layer" (HIG Materials). So the card and its tag chips get solid or material backgrounds. Glass is used only for **controls** that float over the card's media.

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
    @State private var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(item.cover)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(item.tag)                          // a content tag: material, not glass
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: .capsule)
                        .padding(12)
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {                                // a control over media: glass is right
                        saved.toggle()
                    } label: {
                        Image(systemName: saved ? "bookmark.fill" : "bookmark")
                            .contentTransition(.symbolEffect(.replace))
                            .font(.title3)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel(saved ? "Remove bookmark" : "Bookmark")
                    .padding(12)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title).font(.headline)
                Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(.background, in: .rect(cornerRadius: 24))   // solid content surface
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}
```

## Variations

- **Two controls over the cover.** Put them in one `GlassEffectContainer`:
  ```swift
  GlassEffectContainer(spacing: 8) {
      HStack(spacing: 8) { shareButton; bookmarkButton }
  }
  ```
- **Several tags.** Use plain `HStack`s of material capsules. Tags are content and don't need a container.
- **Over imagery, the card body itself** can use `.background(.regularMaterial, in: .rect(cornerRadius: 24))`.

## Gotchas
- Don't glass the card, the tag chips, or the title area. That puts glass in the content layer, and in a `LazyVStack` it also multiplies the number of effects on screen.
- One glass control per card is plenty. The navigation bar above is where the real glass lives.
- The bookmark's glass sits over the photo, so make sure the symbol reads over the brightest cover. Use `.regular` glass here, not `.clear`.
- If a card nests rounded elements, declare the card's shape with `.containerShape(.rect(cornerRadius: 24))` and use concentric shapes inside.
