# Pattern — Floating Glass Toolbar

## Problem
A horizontal cluster of glass icon buttons that floats above content (think: photo editing tools, drawing palette, map controls). Buttons should morph together when one is added/removed.

## Solution

```swift
struct EditorToolbar: View {
    @State private var showColorOptions = false
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                tool("paintbrush") { }
                    .glassEffectID("brush", in: ns)

                tool("pencil") { }
                    .glassEffectID("pencil", in: ns)

                if showColorOptions {
                    tool("paintpalette") { }
                        .glassEffectID("palette", in: ns)
                    tool("eyedropper") { }
                        .glassEffectID("eyedropper", in: ns)
                }

                tool(showColorOptions ? "xmark" : "ellipsis") {
                    withAnimation(.bouncy) {
                        showColorOptions.toggle()
                    }
                }
                .glassEffectID("more", in: ns)
            }
            .padding(8)
        }
    }

    private func tool(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}
```

## Variations

### Vertical floating palette
Swap `HStack` for `VStack`. Same `GlassEffectContainer` rules apply.

### Toolbar that hugs an edge
Wrap in a `.safeAreaInset` to pin it without overlapping content:
```swift
ContentView()
    .safeAreaInset(edge: .bottom) {
        EditorToolbar()
            .padding(.bottom, 24)
    }
```

### Long-press to reveal secondary actions
```swift
tool("paintbrush") { }
    .glassEffectID("brush", in: ns)
    .contextMenu {
        Button("Thick brush", systemImage: "circle.fill") { }
        Button("Thin brush", systemImage: "circle") { }
    }
```

## Gotchas

- Every icon button **must** have a `glassEffectID` for the morph to work — even the ones that are always visible.
- Padding on the container itself (`.padding(8)`) affects how morphing reads at the edges. Tune by eye.
- For >5 buttons, consider a `ToolbarItemGroup` inside a `Toolbar` instead — system tooling is more efficient at that count.
