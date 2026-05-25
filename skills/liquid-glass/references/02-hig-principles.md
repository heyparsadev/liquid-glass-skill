# HIG Principles — Liquid Glass

Apple's Human Interface Guidelines for iOS 26 are organized around three pillars: **Hierarchy**, **Harmony**, and **Consistency**. This file distills them into actionable rules you can apply while coding.

---

## The three pillars

### 1. Hierarchy
> "Establish a clear visual hierarchy where controls and interface elements elevate and distinguish the content beneath them."

- Glass belongs to the **navigation layer** — chrome that floats above content.
- The **content layer** stays solid: text, images, lists, primary surfaces.
- Glass should never compete with content for attention; it should disappear into the background until the user looks at it.

### 2. Harmony
> Your app should feel like a natural extension of the OS.

- Use system components (`NavigationStack`, `TabView`, `Toolbar`, `.searchable`) — they're glass-aware out of the box.
- Match system corner radii via `.containerConcentric`.
- Tint sparingly and semantically (primary, destructive, success), not for branding.

### 3. Consistency
> "Adopt platform conventions so the design adapts across window sizes and displays."

- Same surface should look the same everywhere — a glass tab bar in landscape iPad must feel like the one on iPhone.
- Don't invent custom glass shapes per screen. Reuse `.capsule`, `.circle`, `.containerConcentric`.
- Respect platform idioms: floating buttons on iOS, sidebars on iPad/Mac.

---

## Material properties (what makes glass *glass*)

Liquid Glass is **not** a frosted blur. It's a **lens**:

| Property | What it does |
|---|---|
| **Lensing / refraction** | Bends light from the content behind it — straight lines bow at the edges |
| **Specular highlights** | Reacts to device motion (gyroscope-driven), catching a light source |
| **Adaptive shadows** | Soft shadow underneath, tinted by the content behind |
| **Materialization** | Glass gradually appears (light modulation), not snapped in |
| **Fluidity** | Adjacent shapes morph and merge fluidly during animation |
| **Adaptivity** | Picks up color/luminance of background and tones itself to stay legible |

If your "glass" doesn't do these things, it's not Liquid Glass — it's a frosted overlay.

---

## Where glass belongs

| Layer | Examples | Glass? |
|---|---|---|
| Navigation | Nav bar, tab bar, toolbar, floating action buttons | ✅ yes |
| Controls | Buttons, segmented controls, picker overlays | ✅ usually |
| Sheets / popovers | Grabber, surrounding chrome | ✅ system handles |
| Content | List rows, cards, hero images, body text | ❌ no |
| Backgrounds | Full-screen background | ❌ never |

A useful test: **Can the user grab and move this surface?** If yes (chrome), it can be glass. If no (content), it cannot.

---

## Layering rules

1. **Maximum two glass layers stacked.** A glass card sitting on a glass nav bar = OK. Three or more = visual mud.
2. **Glass cannot sample other glass.** A glass element on top of another glass element produces flat blur — the lensing effect is lost. Use `GlassEffectContainer` to merge them into one layer.
3. **Glass needs varied content behind it.** Glass over a flat solid color looks like a gray blob. Always test over photographic / scrolling content.

---

## Concentricity

When you nest rounded glass shapes, the inner radius must be computed so the curves are concentric with the outer container (and ultimately the device corners).

```swift
// Outer card
.background(
    RoundedRectangle(cornerRadius: 28).fill(.background)
)

// Inner glass control inside the card
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))
```

Don't hardcode `cornerRadius: 12` inside a `cornerRadius: 28` container — the corners won't align visually.

---

## Tinting

Tint is a **semantic signal**, not a brand color.

| Tint | Meaning |
|---|---|
| `.blue` / accent | Primary action |
| `.red` | Destructive |
| `.green` | Success / confirmation |
| `.orange` / `.yellow` | Warning / caution |
| no tint | Neutral, secondary |

### Rules
- Subtle is correct. A saturated tint destroys refraction; you end up with a colored blob.
- For brand color, tint the **content** (icon, label), not the glass.
- Pair `.tint()` with `.buttonStyle(.glassProminent)` for primary CTAs — that's the canonical pattern.

```swift
// ✅ canonical primary
Button("Continue") { }
    .buttonStyle(.glassProminent)
    .tint(.blue)

// ❌ wrong: brand-tinted neutral glass
Button("Browse") { }
    .glassEffect(.regular.tint(.purple))   // saturated tint kills lensing
```

---

## Content first

> "Glass exists to make content shine, not to be the show."

- Never put text directly on a glass surface that floats over busy content without verifying contrast.
- Glass adapts, but it doesn't guarantee legibility — verify in light, dark, and over photos.
- If the only way to make text readable on glass is to darken/saturate the tint, the glass shouldn't be there.

---

## Motion guidance

- Use `.bouncy` or `.smooth` animations for glass state changes.
- Always wrap glass-affecting state mutations in `withAnimation { }`.
- Don't animate `opacity` on glass elements — use `.glassEffect(... isEnabled: false)` or swap to `.identity` so the system handles materialization.

Full guidance: `04-motion-and-interaction.md`.

---

## Accessibility commitments

- Respect `accessibilityReduceTransparency` — glass densifies automatically when the user enables Reduce Transparency, but verify your custom backgrounds also adapt.
- Maintain WCAG **4.5:1** contrast for body text over glass; **3:1** for large text.
- Never use tint as the only differentiator (color-blind users) — pair with icon, label, or shape change.

Full guidance: `05-accessibility.md`.

---

## Do / Don't summary

### ✅ Do
- Reserve glass for the navigation/chrome layer
- Wrap multiple glass elements in `GlassEffectContainer`
- Use `.containerConcentric` corner radii
- Use system components (`Toolbar`, `TabView`) — they're glass by default
- Test over photographs and scrolling content
- Tint semantically, subtly

### ❌ Don't
- Glass-on-glass-on-glass (max 2 layers)
- Glass on content backgrounds (rows, cards, hero areas)
- `.ultraThinMaterial` or other legacy `Material` values (looks out of place in iOS 26)
- Heavy saturated tints (destroy refraction)
- Brand-color the glass itself (tint the content instead)
- Hardcode corner radii inside rounded containers
- Animate glass opacity (animate `isEnabled` or swap variants)

---

## Sources

- [Apple HIG — Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Liquid Glass: Redefining design through Hierarchy, Harmony and Consistency](https://www.createwithswift.com/liquid-glass-redefining-design-through-hierarchy-harmony-and-consistency/)
- WWDC25 Session 284 — *Get to know the new design system*
- WWDC25 Session 219 — *Meet Liquid Glass*
