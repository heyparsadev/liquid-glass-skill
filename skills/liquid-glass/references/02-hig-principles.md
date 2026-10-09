# HIG principles for Liquid Glass

Apple's design guidance for Liquid Glass, turned into rules you can apply while writing code. Quotations are Apple's; everything else is this skill's summary.

## Contents

1. [What Liquid Glass is for](#1-what-liquid-glass-is-for)
2. [Where glass belongs](#where-glass-belongs)
3. [No glass on glass](#3-no-glass-on-glass)
4. [Regular or clear](#4-regular-or-clear)
5. [Color: tint, accent, and brand](#5-color-tint-accent-and-brand)
6. [Legibility](#6-legibility)
7. [Shape and concentricity](#7-shape-and-concentricity)
8. [What the material does by itself](#8-what-the-material-does-by-itself)
9. [Design principles (2026)](#9-design-principles-2026)
10. [Do and don't](#10-do-and-dont)

---

## 1. What Liquid Glass is for

Apple's [Liquid Glass overview](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) says the material helps you "create beautiful interfaces that establish hierarchy, create harmony, and maintain consistency across devices and platforms." In practice:

- **Hierarchy.** Controls and navigation float in their own layer above the content and stay distinct from it.
- **Harmony.** Shapes follow the hardware and window corners, and the content's color shows through the controls.
- **Consistency.** Standard components look and behave the same across platforms and window sizes. Prefer them to custom chrome.

---

<a id="where-glass-belongs"></a>
## 2. Where glass belongs

> "Liquid Glass forms a distinct functional layer for controls and navigation elements — like tab bars and sidebars — that floats above the content layer." (HIG Materials)

> "Don't use Liquid Glass in the content layer. … Instead, use standard materials for elements in the content layer, such as app backgrounds. An exception to this is for controls in the content layer with a transient interactive element like sliders and toggles." (HIG Materials)

> "Use Liquid Glass effects sparingly. … Limit these effects to the most important functional elements in your app." (HIG Materials)

| Layer | Examples | Treatment |
|---|---|---|
| Functional: navigation | Navigation bar, toolbar, tab bar, sidebar, search | System glass, automatic. Configure it; don't re-glass it. |
| Functional: floating controls | Floating action button, editing palette, map controls, media transport over video | `.buttonStyle(.glass)` / `.glassProminent`, or `glassEffect` in a `GlassEffectContainer` |
| Content: transient controls | `Slider`, `Toggle` | The system handles it. No code. |
| Content | List rows, cards, tags and chips, heroes, body text, empty and error states | Solid colors or standard materials (`.ultraThinMaterial` … `.thickMaterial`) |
| Background | The app or screen background | Never glass. Use color, imagery, gradients, or materials. |

**The layer test.** Ask whether the element is a control or navigation element floating above content. If so, it gets glass, preferably a system component. Otherwise, style it as content.

---

## 3. No glass on glass

> "Always avoid glass on glass. Stacking Liquid Glass elements on top of each other can quickly make the interface feel cluttered and confusing. When placing elements on top of Liquid Glass, avoid applying the material to both layers. Instead, use fills, transparency, and vibrancy for the top elements to make them feel like a thin overlay that is part of the material." (WWDC25 219)

```swift
// A count badge on a glass button: a fill, not another glass shape.
Button { } label: {
    Image(systemName: "bell").frame(width: 44, height: 44)
}
.buttonStyle(.glass)
.buttonBorderShape(.circle)
.overlay(alignment: .topTrailing) {
    Text("3")
        .font(.caption2.bold())
        .padding(4)
        .background(.red, in: .circle)       // fill
        .foregroundStyle(.white)
}
```

For a toolbar item, prefer `.badge(3)` ([08 § 2](08-system-chrome.md#badges)).

Glass elements **side by side** are a different problem. "Glass can not sample other glass", so put neighbors in **one** `GlassEffectContainer` to share their sampling region (WWDC25 323).

---

## 4. Regular or clear

> "Use the regular variant when background content might create legibility issues, or when components have a significant amount of text, such as alerts, sidebars, or popovers." (HIG Materials)

> "Only use clear Liquid Glass for components that appear over visually rich backgrounds." "If the underlying content is bright, consider adding a dark dimming layer of 35% opacity. … If the underlying content is sufficiently dark, or if you use standard media playback controls from AVKit that provide their own dimming layer, you don't need to apply a dimming layer." (HIG Materials)

WWDC25 219 allows clear glass only when all three hold:
1. The element is over media-rich content.
2. The content layer won't be harmed by a dimming layer.
3. The content on top of the glass is bold and bright.

Regular and clear "should never be mixed."

```swift
ZStack(alignment: .bottom) {
    PhotoView(photo)                         // bright, media-rich content
    Color.black.opacity(0.35)                // dimming layer beneath the glass
        .ignoresSafeArea()
        .allowsHitTesting(false)
    GlassEffectContainer(spacing: 12) {
        HStack(spacing: 12) {
            mediaButton("backward.fill", "Previous")
            mediaButton("play.fill", "Play")
            mediaButton("forward.fill", "Next")
        }
    }
    .padding(.bottom, 24)
}

func mediaButton(_ symbol: String, _ label: String) -> some View {
    Button { } label: {
        Image(systemName: symbol).font(.title2.bold()).frame(width: 52, height: 52)
    }
    .buttonStyle(.glass(.clear))             // iOS 26.1+; on 26.0 use .plain + .glassEffect(.clear.interactive(), in: .circle)
    .buttonBorderShape(.circle)
    .foregroundStyle(.white)
    .accessibilityLabel(label)
}
```

---

## 5. Color: tint, accent, and brand

**Tint is about hierarchy.** Tinting "is natively compatible with all the behaviors of glass", so it doesn't spoil the material. Apple limits it to keep hierarchy clear: "Tinting should only be used to bring emphasis to primary elements and actions in the UI. Avoid tinting all your elements. When every element is tinted, nothing stands out." (WWDC25 219)

- **Primary actions get a colored background.** "To emphasize primary actions, apply color to the background rather than to symbols or text." "Refrain from adding color to the background of multiple controls." (HIG Color) In SwiftUI, that means `.buttonStyle(.glassProminent).tint(…)`. "Keep the number of prominent buttons to one or two per view." (HIG Buttons)
- **Bars stay monochrome.** "If your app features colorful backgrounds or visually rich content, prefer a monochromatic appearance for toolbars and tab bars." (HIG Color) Tint icons only "to convey meaning, like a call to action or next step, but not just for visual effect." (WWDC25 323)
- **Brand color lives in the content.** "Apply your app's accent color judiciously … Minimize its use on controls and instead use it intentionally for primary actions or status indicators, like badges for unread content or an icon for the selected tab in a tab bar. To express your brand through color, consider moving it into the content layer, where it scrolls beneath Liquid Glass controls and gets picked up dynamically." (HIG Branding, September 2026)
- **Destructive actions** use `role: .destructive`, which gives system red. "Don't assign the primary role to a button that performs a destructive action." (HIG Buttons)
- **Color is never the only signal.** Pair it with a symbol, label, or shape.
- **Use system colors** (`.accentColor`, `.blue`, `.red`, …). They adapt to Light, Dark, and Increase Contrast.

| Goal | Do |
|---|---|
| Make the primary action stand out | `.buttonStyle(.glassProminent).tint(.accentColor)` on one button |
| Show the brand | Color the content layer (headers, artwork, backgrounds). Leave bar items monochrome. |
| Show status | Use a badge or a selected-tab icon in the accent color |
| Show destructive intent | `Button(role: .destructive)`, non-prominent, ideally with a confirmation |
| Tint secondary glass buttons in different hues | Don't. Keep them neutral. |

---

## 6. Legibility

- **Check the resting state.** Glass must be legible without the user interacting with it. Test over the busiest and brightest content your app shows, in Light and Dark appearance, and at both ends of the Liquid Glass slider.
- **The material adapts by itself.** Small elements such as toolbars and tab bars switch between light and dark based on the content behind them. "Liquid Glass appears more opaque in larger elements like sidebars to preserve legibility." (HIG Color) Shadows grow stronger over text and lighter over plain light backgrounds.
- **Text on glass** uses the system's vibrant hierarchical styles (`.primary`, `.secondary`), not fixed grays. If text only reads with a heavy tint or scrim, the glass doesn't belong there.
- **Use the right variant.** Use `.regular` wherever legibility matters. `.clear` needs a dimming layer over bright media ([§4](#4-regular-or-clear)).
- **Contrast targets and testing** are in [05-accessibility.md](05-accessibility.md#4-contrast).

---

## 7. Shape and concentricity

WWDC25 356 describes three kinds of shape:
- **Fixed** corners keep a constant radius.
- **Capsules** use "a radius that's half the height of the container".
- **Concentric** shapes "calculate their radius by subtracting padding from the parent's".

| Element | Shape |
|---|---|
| Controls in bars, standalone buttons | Capsule (the glass default) or circle for icon-only |
| Elements nested inside a rounded container | Concentric: `ConcentricRectangle` / `.rect(corners: .concentric)` |
| Top-level cards and panels | A fixed radius, declared as the container shape for what's inside |

```swift
VStack(spacing: 12) {
    Text("Storage almost full").font(.headline)
    Button("Manage") { }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .glassEffect(.regular.interactive(),
                     in: .rect(corners: .concentric(minimum: 12), isUniform: true))
}
.padding(12)
.background(.background, in: .rect(cornerRadius: 28))
.containerShape(.rect(cornerRadius: 28))     // without this, "concentric" resolves against the sheet/window/device
```

Don't hard-code `cornerRadius: 12` inside a `cornerRadius: 28` container. Details are in [01 § 8](01-api-reference.md#8-shapes-and-concentric-corners).

---

## 8. What the material does by itself

You don't write code for any of this, and you shouldn't imitate it:

| Behavior | What happens |
|---|---|
| Lensing | Glass bends and concentrates light from the content behind it instead of scattering it like a blur |
| Highlights | Highlights respond to the element's geometry and to interaction. "In some cases, the lighting responds to device motion." |
| Adaptive shadow | Shadow opacity rises over text and falls over plain light backgrounds |
| Adaptivity | Small elements flip light/dark with the content behind them. Larger ones become more opaque. |
| Interaction | Interactive glass scales, bounces, and shimmers on touch (`interactive()`, glass button styles) |
| Materialization | Glass "materializes in and out by gradually modulating the light bending and lensing" instead of fading |
| iOS 27 refinement | More diffusion of complex content, a darkened edge, brighter specular highlights. It follows the user's Liquid Glass slider. |

A blur, a translucent white fill, or a stroke is not Liquid Glass. Use the real material, or a standard material if the element is content.

---

## 9. Design principles (2026)

On June 8, 2026 the HIG reintroduced design principles: **Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, and Delight**. They apply to all design, not just glass. The rules in this file are the glass-specific application of *Familiarity* (use the system's components and conventions) and *Simplicity* (glass sparingly, one primary action).

---

## 10. Do and don't

### Do
- Put glass only on controls and navigation floating above content.
- Use system components first. They're already glass.
- Group nearby custom glass in one `GlassEffectContainer`.
- Use concentric shapes inside rounded containers, and declare `containerShape`.
- Use `.regular` by default. Use `.clear` only over rich media, with dimming when the media is bright.
- Tint one primary action. Put brand color in the content.
- Test over busy, bright content, in both appearances, and at both slider ends.

### Don't
- Put glass on cards, rows, chips, heroes, or backgrounds.
- Stack glass on glass.
- Put glass on system bars, toolbar items, or sheets.
- Use `Material` or blur to fake glass on controls.
- Tint every button, or tint icons for decoration.
- Hard-code inner corner radii inside rounded containers.
- Fade glass with `.opacity`. Insert or remove it and let it materialize.

---

## Sources

- HIG: [Materials](https://developer.apple.com/design/human-interface-guidelines/materials) · [Color](https://developer.apple.com/design/human-interface-guidelines/color) · [Branding](https://developer.apple.com/design/human-interface-guidelines/branding) · [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) · [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) · [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Liquid Glass overview](https://developer.apple.com/documentation/technologyoverviews/liquid-glass) · [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- WWDC25 219 *Meet Liquid Glass* · 323 *Build a SwiftUI app with the new design* · 356 *Get to know the new design system*. WWDC26 102 *Platforms State of the Union* · 251 *Communicate your brand identity on iOS*.
