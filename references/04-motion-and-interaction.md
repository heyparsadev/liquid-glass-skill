# Motion & Interaction

Liquid Glass is animated by design. Static glass is a code smell — if a glass element never moves, refracts, or morphs, you're probably using glass where a solid surface would do.

---

## The three motion modes

| Mode | Trigger | API |
|---|---|---|
| **Specular highlights** | Device gyroscope | Automatic — no code |
| **Interactive feedback** | Touch / drag | `.glassEffect(.regular.interactive())` |
| **Morphing** | State change (view appear/disappear) | `GlassEffectContainer` + `.glassEffectID` |

---

## Interactive glass

Adds touch-driven scaling, gentle bounce, specular highlight that follows the touch point, and drag awareness.

```swift
Button("Tap me") { /* … */ }
    .glassEffect(.regular.interactive())
```

### When to enable
- Any glass surface the user can tap, long-press, or drag
- Icon buttons in a glass toolbar
- Cards that respond to gestures

### When NOT to enable
- Non-interactive chrome (nav bar background, decorative pill)
- Static labels or badges
- Elements behind a modal (would suggest interactivity that isn't there)

---

## Morphing — the canonical recipe

```swift
struct MorphingMenu: View {
    @State private var expanded = false
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 24) {
            VStack(spacing: 24) {
                if expanded {
                    icon("crop").glassEffectID("crop", in: ns)
                    icon("rotate.right").glassEffectID("rotate", in: ns)
                    icon("flip.horizontal").glassEffectID("flip", in: ns)
                }
                icon(expanded ? "xmark" : "wand.and.stars") {
                    withAnimation(.bouncy) { expanded.toggle() }
                }
                .glassEffectID("toggle", in: ns)
            }
        }
    }

    func icon(_ name: String, action: (() -> Void)? = nil) -> some View {
        Button { action?() } label: {
            Image(systemName: name)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}
```

### Why each piece is required

| Piece | Without it |
|---|---|
| `GlassEffectContainer` | Glass shapes pop in/out instead of morphing |
| `@Namespace` | No identity → matched geometry can't pair the source and destination |
| `.glassEffectID` | SwiftUI doesn't know which glass element corresponds across the state change |
| `withAnimation(.bouncy)` | State changes apply instantly — no animation curve to morph along |

Miss any of these and morphing silently fails (no error, no warning — just hard cuts).

---

## Animation curves for glass

```swift
.bouncy                              // default — playful, elastic
.smooth(duration: 0.35)              // for nav-bar collapses, less elasticity
.snappy                              // for instant toggles (selected ↔ unselected)
.spring(response: 0.4, dampingFraction: 0.7)  // for drag returns

.easeInOut(duration: 0.25)           // OK for non-glass; weak for glass morphs
.linear                              // ❌ never for glass — kills the material feel
```

---

## Transitions on individual glass views

```swift
.glassEffectTransition(.materialize)      // "gel forms from nothing"
.glassEffectTransition(.matchedGeometry)  // default with glassEffectID
.glassEffectTransition(.identity)         // disable transition entirely
```

`.materialize` is the right choice when a glass element appears for the first time with no corresponding source — e.g., a notification badge popping into existence.

---

## Distance and `spacing`

The `spacing:` value on `GlassEffectContainer` controls **how close two glass shapes need to be to morph into one body**.

```swift
GlassEffectContainer(spacing: 8)   // morph aggressively — overlaps merge
GlassEffectContainer(spacing: 24)  // typical floating menu
GlassEffectContainer(spacing: 80)  // distant siblings still attract during transitions
```

If two elements should stay distinct, place them in **separate** containers.

---

## Symbol effects + glass

Liquid Glass pairs natively with SF Symbols 7 motion. The pattern:

```swift
struct LikeButton: View {
    @State private var liked = false

    var body: some View {
        Button {
            withAnimation(.bouncy) { liked.toggle() }
        } label: {
            Image(systemName: liked ? "heart.fill" : "heart")
                .symbolEffect(.bounce, value: liked)
                .font(.title2)
                .frame(width: 48, height: 48)
        }
        .glassEffect(.regular.interactive())
        .tint(liked ? .red : .primary)
        .contentTransition(.symbolEffect(.replace))
    }
}
```

`contentTransition(.symbolEffect(.replace))` morphs between `heart` and `heart.fill` while the glass beneath morphs at the same time — the layered choreography is what makes iOS 26 feel alive.

---

## Drag interactions

```swift
struct DraggableGlassChip: View {
    @State private var offset: CGSize = .zero

    var body: some View {
        Text("Drag me")
            .padding()
            .glassEffect(.regular.interactive())
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { offset = $0.translation }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            offset = .zero
                        }
                    }
            )
    }
}
```

Interactive glass picks up drag automatically — the specular highlight tracks the touch point.

---

## Zoom (matched) transitions for sheets and navigation

```swift
@Namespace var ns

// Source
Button("Details") { showDetails = true }
    .matchedTransitionSource(id: "details", in: ns)

// Destination
.sheet(isPresented: $showDetails) {
    DetailsView()
        .navigationTransition(.zoom(sourceID: "details", in: ns))
}
```

The source button visually expands into the sheet — glass on the button morphs into the glass on the sheet's chrome.

---

## Performance side of motion

- Morphing inside `GlassEffectContainer` is **cheap** — one render pass.
- Independent `.glassEffect()` siblings each take a render pass; many simultaneously animating can hitch on older devices.
- `.interactive()` adds a per-frame gesture computation. Don't sprinkle it on dozens of static labels.

Details: `06-performance.md`.

---

## Reduce Motion

When the user enables Reduce Motion, the system automatically:
- Disables specular highlight tracking
- Kills morphing animations (state changes still happen, but instantly)
- Suppresses materialization transitions

You generally **don't** need to write code for this — the system handles it. But if you're driving a custom animation:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

withAnimation(reduceMotion ? nil : .bouncy) {
    state.toggle()
}
```

---

## Recipe library

### Pop in
```swift
.transition(.scale.combined(with: .opacity))
.animation(.bouncy, value: visible)
```

### Slide up from bottom (floating accessory)
```swift
.transition(.move(edge: .bottom).combined(with: .opacity))
.animation(.smooth, value: visible)
```

### Morph between two glass states (selected toggle)
```swift
GlassEffectContainer(spacing: 16) {
    if selected {
        glassChip("Selected").glassEffectID("chip", in: ns)
    } else {
        glassChip("Tap to select").glassEffectID("chip", in: ns)
    }
}
```

### Press feedback (manual, for non-Button glass)
```swift
@State private var pressed = false

view
    .glassEffect(.regular.interactive())
    .scaleEffect(pressed ? 0.96 : 1.0)
    .gesture(
        DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.snappy) { pressed = true } }
            .onEnded   { _ in withAnimation(.snappy) { pressed = false } }
    )
```
