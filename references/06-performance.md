# Performance

Liquid Glass is GPU-heavy. The system has been tuned aggressively, but on older hardware (iPhone 11, base-model iPad) and in worst-case layouts, you can still hitch. This file explains the cost model and how to stay smooth.

---

## Cost model — what's expensive

Each `.glassEffect()` is, conceptually, a **render-to-texture pass**:

1. Sample the content behind the shape
2. Apply refraction, blur, lighting, tinting
3. Composite back into the scene

| Operation | Cost |
|---|---|
| Single `.glassEffect()` | Cheap on A17 / M-series; noticeable on A13 |
| 5+ independent `.glassEffect()` siblings | Significant — they each spawn a pass |
| `.glassEffect()` over animating content | Higher — content texture changes per frame |
| `.glassEffect()` over video | Highest — full-rate texture updates |
| `GlassEffectContainer` of N children | ≈ cost of **one** glass effect — system batches them |
| `.interactive()` modifier | + per-frame gesture/highlight computation |
| Morphing between IDs | + matched-geometry layout pass per frame |

**Rule of thumb.** 1 container of 5 children is ~5× cheaper than 5 standalone glass views.

---

## The three perf commandments

### 1. Group with `GlassEffectContainer` — always
If you have ≥ 2 glass elements on screen, they belong in a container. Even if they don't morph, you get the batched render pass for free.

```swift
// ❌ five independent passes
HStack {
    Button(...).buttonStyle(.glass)
    Button(...).buttonStyle(.glass)
    Button(...).buttonStyle(.glass)
    Button(...).buttonStyle(.glass)
    Button(...).buttonStyle(.glass)
}

// ✅ one batched pass
GlassEffectContainer(spacing: 12) {
    HStack(spacing: 12) {
        Button(...).buttonStyle(.glass)
        Button(...).buttonStyle(.glass)
        Button(...).buttonStyle(.glass)
        Button(...).buttonStyle(.glass)
        Button(...).buttonStyle(.glass)
    }
}
```

### 2. Don't glass-on-glass
Glass cannot sample other glass — you get flat blur and an extra pass. If you find yourself nesting, merge with `GlassEffectContainer` or `.glassEffectUnion()`.

### 3. Glass on video/games costs real frames
A glass HUD over a 60 fps gameplay surface or a video player will eat 1–3 ms/frame on A13–A14. Either:
- Use `.clear` variant (lighter)
- Reduce overlay complexity (one container, not many shapes)
- Hide the overlay during heavy moments (`isEnabled: false`)

---

## When glass is the wrong tool

Glass is for **chrome that floats above content**. If your "glass" is:

| Use case | Better tool |
|---|---|
| Solid card with subtle blur | `.background(.background)` + shadow |
| Full-screen overlay | `.background(.regularMaterial)` (legacy) is still legal for full backgrounds where lensing has nothing to lens |
| Decorative gradient panel | `LinearGradient` |
| Loading spinner backdrop | `Color.black.opacity(0.3)` |
| Tooltip / coachmark | `.popover` with system styling |

Using glass everywhere is the iOS-26 equivalent of putting drop-shadows on everything in 2010.

---

## Animation cost

Morphing is **cheap inside** `GlassEffectContainer` (single pass), **expensive outside** (multiple passes per frame).

```swift
// ❌ 4 morphs × 60 fps = 240 glass passes/sec
ForEach(items) { item in
    Capsule().glassEffect()
        .frame(width: item.width)
        .animation(.bouncy, value: item.width)
}

// ✅ 1 batched morph per frame
GlassEffectContainer(spacing: 16) {
    ForEach(items) { item in
        Capsule().glassEffect()
            .frame(width: item.width)
    }
}
.animation(.bouncy, value: items)
```

---

## `.interactive()` is not free

Each `.interactive()` modifier installs:
- A `DragGesture` recognizer
- A per-frame transform calculation
- A specular-highlight tracker

Applying `.interactive()` to a dozen static labels is wasteful. Apply only to elements the user actually touches.

---

## Long lists

Glass cells in a `List` or `LazyVStack` are usually wrong (content layer, not chrome). But if you really need them — e.g., a section header pill that floats — make sure cells aren't applying glass per row:

```swift
// ❌ glass per row
List(items) { item in
    Text(item.title)
        .padding()
        .glassEffect()
}

// ✅ a single glass header, plain rows
List {
    Section {
        Text("Featured")
            .padding(.horizontal)
            .glassEffect()
    }
    ForEach(items) { item in
        Text(item.title)
    }
}
```

---

## Profile, don't guess

Instruments → **Metal System Trace** (Xcode 26) shows glass passes as labeled phases. Look for:
- "GlassEffect: layout" — should appear once per container per frame
- "GlassEffect: composite" — should not spike during scroll

If you see N composite phases for N glass children, you're missing a container.

The **Animation Hitch** template will surface frames where a glass animation drops below 60/120 fps.

---

## Energy

Glass over video at 120Hz on an iPad Pro is one of the more energy-hungry UI patterns. On long-running screens (a paused video, an idle media player):

```swift
.glassEffect(.regular, isEnabled: !isIdle)
```

…degrades to no-effect when the user is inactive, reclaiming GPU and battery.

---

## Older hardware

iPhone 11 / 12 mini / iPad 9th-gen can sustain a "rich" glass UI but break under:
- 4+ independent glass elements morphing simultaneously
- Glass over 4K video
- Glass + heavy `.background` blurs simultaneously

If your minimum target is iOS 26 on iPhone 11, build your worst-case screen and profile it. Either rein in the glass or accept a lower frame rate during transitions only.

---

## Quick wins checklist

- [ ] Every cluster of 2+ glass elements is in a `GlassEffectContainer`
- [ ] No glass-on-glass (nested `.glassEffect()`)
- [ ] `.interactive()` only on touchable elements
- [ ] No glass on list cells or long scroll content
- [ ] No glass during video playback unless `.clear` variant
- [ ] Profile pass under Metal System Trace before shipping
