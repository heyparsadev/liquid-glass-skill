# Design Tokens — Liquid Glass

Conventions for spacing, radii, tinting, and typography that keep your iOS 26 app coherent with the rest of the system. These aren't hardcoded by Apple — they're the values their first-party apps converge on.

---

## Corner radii

| Surface | Radius | How to express |
|---|---|---|
| Floating button (capsule) | system | `.buttonBorderShape(.capsule)` |
| Floating icon button | system | `.buttonBorderShape(.circle)` |
| Card inside a sheet | `.containerConcentric` | `.rect(cornerRadius: .containerConcentric)` |
| Standalone card | 20–28 | `RoundedRectangle(cornerRadius: 24)` |
| Inline glass chip | 12–16 | `RoundedRectangle(cornerRadius: 14)` |
| Sheet itself | system | managed by `.sheet` |

**Rule.** Inside any rounded container, prefer `.containerConcentric` over a literal radius. Hardcode only at the outermost layer.

---

## Spacing

### Inside `GlassEffectContainer`
The `spacing:` parameter is the **morph threshold** — elements within this distance blend during transitions.

| Context | Spacing |
|---|---|
| Tight toolbar (small icons) | `8–12` |
| Standard floating controls | `16–20` |
| Expanding action menu | `24–32` |
| Distinct, non-morphing siblings | `40+` (or omit container) |

### Padding inside glass elements
| Control | Horizontal pad | Vertical pad |
|---|---|---|
| Icon button | 12 | 12 |
| Label button (`.regular`) | 16 | 10 |
| Label button (`.large`) | 20 | 14 |
| Label button (`.extraLarge`) | 28 | 18 |
| Glass card | 20 | 20 |

---

## Tint palette

Use **system colors**, never raw hex, so glass adapts to Light/Dark/Increased Contrast.

```swift
.tint(.blue)        // primary
.tint(.red)         // destructive
.tint(.green)       // success / confirmation
.tint(.orange)      // warning
.tint(.yellow)      // caution
.tint(.purple)      // creative / playful
.tint(.pink)        // social / favorites
.tint(.gray)        // neutral emphasis
.tint(.accentColor) // app-wide accent
```

### When to tint glass vs. tint content
| Goal | What to tint |
|---|---|
| Primary CTA | tint the glass (`.glassProminent.tint(.blue)`) |
| Indicate selection | tint the icon, leave glass neutral |
| Show severity (alert, error) | tint the icon, leave glass neutral; only tint glass for truly destructive primary actions |
| Brand identity | tint **content only**, never the glass |

---

## Typography on glass

iOS 26 system fonts have been retuned for better legibility over glass. Use them.

| Role | Font |
|---|---|
| Floating button label | `.body.weight(.semibold)` |
| Icon-only button | `.title3` symbol |
| Toolbar label | `.callout` |
| Nav bar title | `.largeTitle.bold()` (auto by `NavigationStack`) |
| Hint text | `.footnote` with `.secondary` |

**Always** test the smallest text size over the busiest possible background — a low-contrast `.caption` on a glass overlay over a photo is the most common ship-blocker.

---

## Background materials to pair with glass

Glass shines over varied, photographic, or scrolling content. If you need a solid backing:

| Background | When |
|---|---|
| Photographic / video | Best showcase for `.clear` glass |
| `.background(.background)` | System adaptive solid (default for content layer) |
| Gradient (subtle) | OK for hero areas; avoid harsh stops |
| Solid bright color | ❌ avoid — kills lensing |

---

## Animation timings

Standard SwiftUI presets work well; the system has been tuned for glass.

```swift
withAnimation(.bouncy) { ... }                              // default for glass morphing
withAnimation(.smooth(duration: 0.35)) { ... }              // for non-morphing chrome
withAnimation(.snappy) { ... }                              // for instantly responsive toggles
withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) // for drag returns
```

Avoid `.linear` for glass — it strips the elasticity Liquid Glass is built around.

---

## Symbols (SF Symbols 7)

iOS 26 ships **SF Symbols 7** with motion-aware variants. Pair them with glass for the canonical look:

```swift
Image(systemName: "heart")
    .symbolEffect(.bounce, value: liked)
    .symbolRenderingMode(.hierarchical)
    .font(.title2)
    .frame(width: 44, height: 44)
    .glassEffect(.regular.interactive())
```

Prefer `.hierarchical` rendering on glass — it preserves depth cues that pair with the lensing.

---

## Z-stack order

When composing a screen, this is the canonical order from back to front:

1. Content layer (image, list, scroll view) — fills the safe area, ignores it where appropriate
2. Glass chrome (nav bar, tab bar — system) — sits in the safe area
3. Floating glass overlays (action menu, FAB, now-playing strip)
4. Transient glass (sheets, alerts — system)

Don't insert custom glass between layers 1 and 2; let the system own that band.

---

## Quick reference table

| Token | Value |
|---|---|
| Default glass shape | `Capsule` |
| Default container spacing | `nil` (system optimal) |
| Default morph threshold | `16–24` |
| Concentric corner trick | `.rect(cornerRadius: .containerConcentric)` |
| Primary CTA recipe | `.buttonStyle(.glassProminent).tint(.blue).controlSize(.large)` |
| Floating FAB recipe | `.buttonStyle(.glassProminent).buttonBorderShape(.circle).controlSize(.extraLarge)` |
| Icon button recipe | `Image(systemName:).frame(44,44).glassEffect(.regular.interactive())` |
