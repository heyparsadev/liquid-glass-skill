# Motion and interaction

How Liquid Glass moves, what is automatic, and how to animate custom glass correctly.

## Contents

1. [What is automatic](#1-what-is-automatic)
2. [Interactive glass](#2-interactive-glass)
3. [Morphing](#3-morphing)
4. [Glass transitions](#4-glass-transitions)
5. [Symbol effects on glass](#5-symbol-effects-on-glass)
6. [Drag](#6-drag)
7. [Presentations that grow out of controls](#7-presentations-that-grow-out-of-controls)
8. [Reduce Motion and Reduce Bright Effects](#8-reduce-motion-and-reduce-bright-effects)
9. [Recipes](#9-recipes)

---

## 1. What is automatic

Glass is meant to be **quiet at rest and alive on touch**. Apple: "This lets the resting state stay visually quiet, while it comes to life on touch" (WWDC25 219). Most system glass, such as toolbars and tab bars, never morphs, and that is correct. Whether something should be glass depends on its layer, not on whether it moves.

| Motion | Trigger | What you write |
|---|---|---|
| Highlights | Geometry and interaction; "in some cases" device motion | Nothing |
| Touch feedback (scale, bounce, shimmer) | Touching a glass button or interactive glass | `.buttonStyle(.glass)` / `.glassProminent`, or `.interactive()` on custom glass |
| Morphing | Glass views appearing, disappearing, or changing inside one container | `GlassEffectContainer` + `glassEffectID` + `withAnimation` |
| Materialize | Glass inserted or removed | Insert or remove inside `withAnimation`; optionally `.glassEffectTransition(.materialize)` |
| Dialogs, menus, sheets | Presented from a control | Attach the presentation to the control ([§7](#7-presentations-that-grow-out-of-controls)) |

---

## 2. Interactive glass

`Glass.interactive(_:)` gives a custom glass view "the same responsive and fluid reactions" that the glass button style gives buttons.

```swift
// A custom control that isn't a standard button shape
Button { recenter() } label: {
    Image(systemName: "location.fill").frame(width: 44, height: 44)
}
.buttonStyle(.plain)
.glassEffect(.regular.interactive(), in: .circle)
.accessibilityLabel("Show my location")
```

- **Turn it on for** custom glass that people tap, press, or drag.
- **Turn it off for** labels, status chips, and decoration. Interactivity on something that does nothing misleads.
- **Buttons.** Use `.buttonStyle(.glass)` or `.glassProminent`, which are already interactive.
- **Don't add your own press effect** (`scaleEffect` on a zero-distance `DragGesture`) on top of interactive glass. The effect would double, and the gesture can steal taps and scrolls.

---

## 3. Morphing

A complete example is in [01 § 4](01-api-reference.md#4-glasseffectid_in). The parts and what breaks without each:

| Piece | Without it |
|---|---|
| One `GlassEffectContainer` around the morphing views | Shapes appear and disappear on their own. No blending. |
| `@Namespace` + a unique `.glassEffectID(_:in:)` on each view | The system can't pair the before and after shapes |
| The state change inside `withAnimation { }` | A hard cut. "Only affect their content during view hierarchy transitions or animations." |
| Container `spacing` that reaches the neighbors | Distant shapes materialize instead of growing out of each other |

Morphing fails silently: there is no error, only a cut. Check all four pieces when a morph doesn't happen.

**Changing size or content of one glass view.** A glass view that changes size inside an animation animates its shape. You don't need an ID for that:

```swift
struct UndoPill: View {
    @State private var showsTitle = false

    var body: some View {
        Button {
            withAnimation(.bouncy) { showsTitle.toggle() }
        } label: {
            HStack {
                Image(systemName: "arrow.uturn.backward")
                if showsTitle { Text("Undo Delete") }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive())
        .accessibilityLabel("Undo Delete")
    }
}
```

---

## 4. Glass transitions

```swift
.glassEffectTransition(.matchedGeometry)   // default within the container's spacing: grows out of a nearby shape
.glassEffectTransition(.materialize)       // for distant shapes, or a simpler transition
.glassEffectTransition(.identity)          // no glass transition
```

- Apple: "For effects you want to add or remove that are positioned within the container's assigned spacing, the default transition type is matchedGeometry." "Use the materialize transition for effects you want to add or remove that are farther from each other than the container's assigned spacing."
- Glass "materializes in and out by gradually modulating the light bending and lensing", which means it doesn't fade. **Don't use `.opacity` or `.transition(.opacity)` on glass views.** Keep those for non-glass content.
- "To provide people with a consistent experience, use matchedGeometry and materialize transitions across your apps."

---

## 5. Symbol effects on glass

Animate the **symbol**. Glass buttons give touch feedback by themselves.

```swift
struct LikeButton: View {
    @State private var liked = false

    var body: some View {
        Button {
            liked.toggle()
        } label: {
            Image(systemName: liked ? "heart.fill" : "heart")
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: liked)
                .font(.title2)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .foregroundStyle(liked ? Color.red : Color.primary)    // red carries meaning here: liked
        .accessibilityLabel(liked ? "Unlike" : "Like")
    }
}
```

Both forms are iOS 17+: `contentTransition(.symbolEffect(.replace))` swaps the symbol, and `symbolEffect(_:options:value:)` plays a one-shot effect.

---

## 6. Drag

Interactive glass reacts to touch while it's being dragged. Spring it back when the drag ends:

```swift
struct DraggableChip: View {
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
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { offset = .zero }
                    }
            )
            .accessibilityHidden(true)      // decorative demo; give real draggables an accessible alternative
    }
}
```

---

## 7. Presentations that grow out of controls

- **Dialogs** "automatically morph out of the buttons that present them" (WWDC25 323), so attach `.confirmationDialog` or `.alert` to the presenting `Button`.
- **Zoom sheets.** Put `matchedTransitionSource(id:in:)` on the button, or on the `ToolbarItem` (26.0, iOS/iPadOS/Catalyst), and `.navigationTransition(.zoom(sourceID:in:))` on the sheet content.
- **Cross-fade sheets (iOS 27).** `.navigationTransition(.crossFade)` on the sheet content fades the sheet in over the content instead of sliding it up. It isn't available on macOS.
- **Menus** from glass buttons expand out of the button automatically.

Code is in [08 § 7](08-system-chrome.md#7-sheets-popovers-and-dialogs).

---

## 8. Reduce Motion and Reduce Bright Effects

**System glass.** "Reduced Motion decreases the intensity of some effects and disables any elastic properties for the material" (WWDC25 219). This is automatic.

**Your own animations.** HIG Accessibility asks you to reduce "automatic and repetitive animations, including zooming, scaling, and peripheral motion". Tighten springs to reduce bounce, and replace movement transitions with fades. Make the motion calmer; don't remove the animation, because morphs and materialization rely on one.

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

Button("Edit", systemImage: "slider.horizontal.3") {
    withAnimation(reduceMotion ? .smooth : .bouncy) { expanded.toggle() }
}
```

**Reduce Bright Effects (iOS 26.4).** When `accessibilityReduceHighlightingEffects` is true, controls "should be drawn in such a way that minimizes highlighting and flashing". Turn off custom shimmer, glow, or pulsing highlights you've added to glass controls.

---

## 9. Recipes

**Add a glass element:**
```swift
GlassEffectContainer(spacing: 16) {
    HStack(spacing: 16) {
        primaryControl.glassEffectID("primary", in: ns)
        if showsSecondary {
            secondaryControl
                .glassEffectID("secondary", in: ns)   // grows out of "primary" (within spacing)
        }
    }
}
// withAnimation { showsSecondary.toggle() }
```

**Show a far-away glass element:**
```swift
if showsHint {
    HintBubble()
        .glassEffect()
        .glassEffectTransition(.materialize)
}
// withAnimation { showsHint = true }
```

**Switch glass off without removing the view.** The variant swap isn't documented to animate:
```swift
.glassEffect(isHighlighted ? .regular : .identity)
```

**Move non-glass content.** Ordinary transitions are fine there:
```swift
Text("Saved").transition(.move(edge: .top).combined(with: .opacity))
```
