# Design tokens

Shapes, spacing, dimming, color, type, and motion values for glass UI.

Apple publishes **few numeric tokens** for Liquid Glass. Each value below is marked either **Apple** (from Apple's documentation or a session, with its source) or **suggested** (a starting value this skill recommends; tune it by eye).

## Contents

1. [Shapes and radii](#1-shapes-and-radii)
2. [Spacing and hit targets](#2-spacing-and-hit-targets)
3. [Container spacing (blend distance)](#3-container-spacing-blend-distance)
4. [Dimming for clear glass](#4-dimming-for-clear-glass)
5. [Color](#5-color)
6. [Typography and symbols](#6-typography-and-symbols)
7. [Animation](#7-animation)
8. [Layer order](#8-layer-order)
9. [Quick reference](#9-quick-reference)

---

## 1. Shapes and radii

| Element | Shape | Source |
|---|---|---|
| Glass default | Capsule (`DefaultGlassEffectShape()`) | Apple |
| Icon-only floating button | `.buttonBorderShape(.circle)` | Apple style; suggested use |
| Label button | `.buttonBorderShape(.capsule)` or `.automatic` (the default) | Apple |
| Element inside a rounded container | `.rect(corners: .concentric(minimum: …), isUniform: true)` + `.containerShape(_:)` on the parent | Apple API |
| Top-level card or panel (content layer) | Fixed radius, about **20–28 pt**, continuous corners | Suggested |
| Small chip or tag (content layer) | Capsule, or about **12–16 pt** | Suggested |
| Sheet, window, device corners | System-managed | Apple |

Apple's rule of thumb (WWDC25 356):
- **Fixed** corners keep a constant radius.
- **Capsules** use half the container height.
- **Concentric** corners subtract the padding from the parent's radius.

Declare the top-level radius once, as the container shape, and let inner shapes derive theirs. A concentric radius can resolve to zero if no container shape is found, so give it a `minimum`.

---

## 2. Spacing and hit targets

| Token | Value | Source |
|---|---|---|
| Hit region | **44 × 44 pt** minimum for a tappable control (60 × 60 pt in visionOS) | Apple (HIG Buttons) |
| Default / minimum control size, iOS | 44 × 44 pt default, 28 × 28 pt minimum | Apple (HIG Accessibility) |
| Space around bezeled elements | about **12 pt** | Apple (HIG Accessibility) |
| Space around elements without a bezel | about **24 pt** | Apple (HIG Accessibility) |
| Padding inside an icon button label | Frame the symbol at 44–52 pt | Suggested |
| Padding inside a custom glass label | 16 horizontal × 10 vertical | Suggested |
| Padding inside a content card | 16–20 | Suggested |
| Gap between floating glass controls | 8–16 | Suggested |

Let content set the size: padding plus intrinsic size, not fixed heights, so Dynamic Type can grow ([05 § 7](05-accessibility.md#7-dynamic-type-and-hit-targets)).

---

## 3. Container spacing (blend distance)

`GlassEffectContainer(spacing:)` sets when shapes start to blend: "The higher the spacing, the sooner blending begins". If it is **larger than the layout spacing** inside, shapes "blend together at rest" (Apple).

| Intent | Container `spacing` | Layout `spacing` |
|---|---|---|
| Separate controls that morph only while animating | Equal to the layout gap (e.g. 12) | 12 |
| Controls that should read as one fused bar at rest | Larger than the layout gap (e.g. 24) | 8 |
| An expanding menu whose items grow out of the toggle | About 16–30 | The same or smaller |
| `nil` | System default | — |

These are suggested values. The relationship (container spacing compared with layout spacing) comes from Apple.

---

## 4. Dimming for clear glass

| Situation | Token | Source |
|---|---|---|
| Clear glass over **bright** media | A dark dimming layer of about **35%** (`Color.black.opacity(0.35)`) between the media and the controls | Apple (HIG Materials) |
| Clear glass over sufficiently **dark** media | No dimming | Apple |
| AVKit playback controls | No extra dimming. They provide their own. | Apple |
| Regular glass | No dimming | — |

The `Glass.clear` documentation: "ensure content remains legible by adding a dimming layer or other treatment beneath the glass."

---

## 5. Color

Use system colors so glass adapts to Light, Dark, Increase Contrast, and the Liquid Glass look setting.

| Role | Token | Rule |
|---|---|---|
| Primary action | `.buttonStyle(.glassProminent).tint(.accentColor)` | One or two per view (HIG Buttons). Color goes on the background (HIG Color). |
| Destructive | `Button(role: .destructive)` → system red | Not the prominent primary (HIG Buttons) |
| Status | `.badge(n)`, accent-colored selected-tab icon | HIG Branding |
| Brand | The content layer: headers, artwork, backgrounds | HIG Branding (Sept 2026) |
| Bar items and secondary glass buttons | Untinted (monochrome) | HIG Color, WWDC25 323 |
| Text on glass | `.primary`, `.secondary` (vibrant) | Suggested |

Don't build a palette that maps hues to moods (purple for creative, pink for social, and so on). Apple's rule is fewer tints, with meaning.

---

## 6. Typography and symbols

- **Type.** Use Dynamic Type text styles (`.body`, `.headline`, `.callout`, `.footnote`, …), never fixed sizes. Apple's 26-era change: "Typography has been refined to strengthen clarity and structure, now bolder and left-aligned to improve readability in key moments like alerts and onboarding" (WWDC25 356).
- **Suggested roles.**
  - Floating button label: `.body.weight(.semibold)`
  - Icon-only button symbol: `.title3`
  - Hint text: `.footnote` with `.secondary`
  - Navigation titles: let `NavigationStack` set them.
- **Symbols.** SF Symbols 7 shipped with iOS 26 and SF Symbols 8 ships with iOS 27. On bars, symbols use monochrome rendering and "automatically receive appropriate coloring and vibrancy" (HIG Toolbars). Keep the default there. Use `.hierarchical` or palette rendering when it helps a custom control, not as a rule.
- **Toolbar items.** On iPhone Duo, "provide both a title and a symbol for each toolbar item that isn't text-only." `Button("Share", systemImage: "square.and.arrow.up")` does both.

---

## 7. Animation

Apple's glass samples use a plain `withAnimation { … }`. No curve is required for glass. The table below lists **suggested** curves:

```swift
withAnimation { … }                                   // system default: fine for morphs
withAnimation(.bouncy) { … }                          // playful morphs (menus, toggles)
withAnimation(.smooth) { … }                          // calmer state changes
withAnimation(.snappy) { … }                          // quick selection changes
withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { … }   // returning a dragged element
```

- Glass changes must happen **inside an animation** to morph or materialize. Without one, they cut.
- Under **Reduce Motion**, use a calmer curve: tighter springs with less bounce, or fades instead of movement (HIG Accessibility). For example, `withAnimation(reduceMotion ? .smooth : .bouncy)`. Don't drop the animation entirely.

---

## 8. Layer order

From back to front:

1. **Content.** Images, lists, scroll views. Often extends under the bars (`ignoresSafeArea`, `backgroundExtensionEffect`).
2. **Scroll edge effect.** System-drawn under the bars. Don't add your own scrim.
3. **System bars.** Navigation bar, toolbars, tab bar. On iPhone Duo these can be a vertical bar at the side.
4. **Custom floating glass.** Action buttons, palettes, accessories. Keep it clear of the system bars and of reserved regions.
5. **Presentations.** Sheets, popovers, menus, alerts (system glass).

---

## 9. Quick reference

| Token | Value |
|---|---|
| Default glass | `.regular`, capsule |
| Concentric inner shape | `.rect(corners: .concentric(minimum: 12), isUniform: true)` + parent `.containerShape(.rect(cornerRadius: R))` |
| Primary CTA | `.buttonStyle(.glassProminent).tint(.accentColor).controlSize(.large)` |
| Icon button | `Button { } label: { Image(systemName:).frame(width: 44, height: 44) }.buttonStyle(.glass).buttonBorderShape(.circle)` |
| Clear glass over bright media | `.clear` + `Color.black.opacity(0.35)` beneath |
| Hit region | ≥ 44 × 44 pt |
| Container spacing | ≤ layout gap (separate at rest), > layout gap (fused at rest) |
