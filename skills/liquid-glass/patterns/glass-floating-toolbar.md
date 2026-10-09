# Pattern: floating glass toolbar

## Problem
You need a cluster of glass controls that floats above content and isn't a system toolbar, such as photo editing tools, a drawing palette, or map controls. The controls should morph when one is added or removed.

First check whether a system `.toolbar` with `ToolbarItemGroup` (top or `.bottomBar`) would do. It gets overflow, minimization, and the iPhone Duo layout for free. Build a custom cluster only when the controls belong to the canvas, not to navigation.

## Solution

```swift
struct EditorToolbar: View {
    @State private var showsColorTools = false
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 12) {                 // one container for the whole cluster
            HStack(spacing: 12) {                           // container spacing == layout gap: separate at rest
                tool("paintbrush", "Brush") { }
                    .glassEffectID("brush", in: ns)
                tool("pencil", "Pencil") { }
                    .glassEffectID("pencil", in: ns)

                if showsColorTools {
                    tool("paintpalette", "Colors") { }
                        .glassEffectID("palette", in: ns)
                    tool("eyedropper", "Eyedropper") { }
                        .glassEffectID("eyedropper", in: ns)
                }

                tool(showsColorTools ? "xmark" : "ellipsis",
                     showsColorTools ? "Hide color tools" : "Show color tools") {
                    withAnimation { showsColorTools.toggle() }
                }
                .glassEffectID("more", in: ns)
            }
        }
    }

    private func tool(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}
```

## Pin it to an edge with `safeAreaBar`

```swift
CanvasView()
    .safeAreaBar(edge: .bottom) {                           // takes part in scroll edge effects
        EditorToolbar()
            .padding(.bottom, 8)
    }
```

Unlike `safeAreaInset`, `safeAreaBar` also extends the scroll edge effect under your bar, so scrolling content stays legible. One exception: if the bar contains a focused `TextField`, use `safeAreaInset`. The iOS 26.1 release notes list a known issue that `@FocusState` doesn't work in `safeAreaBar`.

## Variations

- **Vertical palette.** Use a `VStack` with the same container rules.
- **Secondary actions on long-press.** Add `.contextMenu { … }` to a tool. The menu expands out of the glass button.
- **A clear variant over photos.** Use `.buttonStyle(.glass(.clear))` (iOS 26.1+), but only with bold symbols and a dimming layer when the photo is bright ([02 § 4](../references/02-hig-principles.md#4-regular-or-clear)).

## iPhone Duo (iOS 27.1)
On iPhone Duo, system bars can sit on a side edge. Read `@Environment(\.toolbarVerticalEdge)` (27.1, beta; `nil` where no vertical bar is used) and place a custom palette on the opposite edge, clear of the hinge's reserved region.

## Gotchas
- Every view that appears or disappears needs a `glassEffectID` in the same namespace. Give the always-visible tools IDs too, so the new tools can grow out of them.
- Toggle inside `withAnimation`, or the morph becomes a cut.
- A container spacing larger than the `HStack` spacing fuses the tools into one blob at rest. That's fine if you want it, and a bug if you don't.
- Don't put the cluster on top of another glass surface, such as a glass panel, because that is glass on glass.
- With more than about five tools, or when they're really navigation, use a system toolbar.
