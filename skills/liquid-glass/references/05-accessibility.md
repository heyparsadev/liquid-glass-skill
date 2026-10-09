# Accessibility

Liquid Glass adapts to the main accessibility settings without any code. You still own contrast, labels, color semantics, custom backgrounds, custom motion, and the edges of custom controls.

## Contents

1. [What the system adapts](#1-what-the-system-adapts)
2. [What you own](#2-what-you-own)
3. [Environment values](#3-environment-values)
4. [Contrast](#4-contrast)
5. [Color is never the only signal](#5-color-is-never-the-only-signal)
6. [VoiceOver](#6-voiceover)
7. [Dynamic Type and hit targets](#7-dynamic-type-and-hit-targets)
8. [The Liquid Glass look setting](#8-the-liquid-glass-look-setting)
9. [Smart Invert](#9-smart-invert)
10. [Audit checklist](#10-audit-checklist)

---

## 1. What the system adapts

> "Reduced Transparency makes Liquid Glass frostier and obscures more of the content behind it. Increased contrast makes elements predominantly black or white and highlights them with a contrasting border, and Reduced Motion decreases the intensity of some effects and disables any elastic properties for the material. These are available automatically whenever you use the new material." (WWDC25 219)

| Setting | What happens to glass | Your code |
|---|---|---|
| Reduce Transparency | Frostier, so less of the content shows through. On iPhone Duo, vertical bars gain a background. | None for glass. Make **custom** translucent backgrounds more opaque. |
| Increase Contrast | Elements become predominantly black or white, with a contrasting border | None for glass. Provide higher-contrast colors in your own content. |
| Reduce Motion | Some effects are less intense, and the material loses its elastic properties | None for glass. Calm your **custom** animations ([04 § 8](04-motion-and-interaction.md#8-reduce-motion-and-reduce-bright-effects)). |
| Show Borders | System controls show borders | Stroke **custom** glass controls ([§3](#3-environment-values)) |
| Reduce Bright Effects (26.4) | — | Turn off custom shimmer and glow |
| Differentiate Without Color | — | Add shapes or symbols next to color ([§5](#5-color-is-never-the-only-signal)) |

This adaptation works for `glassEffect`, the glass button styles, and all system chrome. WWDC26: "Liquid Glass seamlessly adapts to a variety of accessibility settings users may choose, such as reducing transparency or increasing contrast."

> **Don't swap glass for `.identity` under Reduce Transparency.** `.identity` means "your content remains unaffected as if no glass effect was applied", so your labels lose their backing and sit straight on busy content. That's the opposite of what the user asked for. The system already makes the glass frostier.

---

## 2. What you own

- **Text contrast** over whatever can appear behind the glass.
- **Labels** for icon-only controls.
- **Color semantics.** Color is never the only signal.
- **Custom backgrounds and overlays** you draw behind or around glass: gradients, photos, translucent fills.
- **Custom motion**, including drags, springs, and parallax.
- **Custom highlights** such as shimmer, glow, and pulses.
- **Custom controls' edges** when Show Borders is on.

---

## 3. Environment values

```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
@Environment(\.colorSchemeContrast) private var contrast              // .standard | .increased
@Environment(\.accessibilityShowBorders) private var showBorders      // renamed from accessibilityShowButtonShapes
// iOS 26.4+: on a 26.0 target, read it from a type marked @available(iOS 26.4, *)
@Environment(\.accessibilityReduceHighlightingEffects) private var reduceBrightEffects
```

**A custom background under glass, with Reduce Transparency:**

```swift
ZStack {
    if reduceTransparency {
        Rectangle().fill(.background)          // solid, adapts to Light and Dark
    } else {
        Image("hero").resizable().scaledToFill()
    }
}
.ignoresSafeArea()
```

**A custom glass control, with Show Borders.** "When this value is true, draw interactive custom controls such as buttons with clearly visible edges." The system button styles already do this.

```swift
Button { addItem() } label: {
    Image(systemName: "plus").frame(width: 44, height: 44)
}
.buttonStyle(.plain)
.glassEffect(.regular.interactive(), in: .circle)
.overlay {
    if showBorders {
        Circle().strokeBorder(.primary.opacity(0.6), lineWidth: 1)
    }
}
.accessibilityLabel("Add item")
```

On macOS 27 there is a dedicated Show Borders setting. Earlier macOS versions report `true` when Increase Contrast is on. Xcode 27 previews can override *Control Borders* and *Color Scheme Contrast*.

---

## 4. Contrast

Liquid Glass adapts to keep text legible, but it doesn't guarantee your contrast ratios. Apple's targets, which Accessibility Inspector uses (HIG Accessibility, WCAG AA):

| Text size | Weight | Minimum ratio |
|---|---|---|
| Up to 17 pt | All | **4.5 : 1** |
| 18 pt and larger | All | **3 : 1** |
| All sizes | Bold | **3 : 1** |

For non-text UI (icons, control edges), use at least 3 : 1 (WCAG 2.1). The HIG adds: "If your app doesn't provide this minimum contrast by default, ensure it at least provides a higher contrast color scheme when the system setting Increase Contrast is turned on."

**How to check:**
1. Run on a device with the **brightest, busiest** content that can sit behind the glass.
2. Measure with Xcode's Accessibility Inspector (Color Contrast Calculator).
3. Repeat in Dark Mode, with Increase Contrast on, and at both ends of the Liquid Glass slider (iOS 27).

**If contrast fails,** try these in order:
1. Strengthen the foreground: a heavier weight, or `.primary` instead of `.secondary`.
2. Use `.regular` instead of `.clear`.
3. With clear glass over bright media, add a dimming layer beneath it (about 35% black).
4. Reconsider placement: glass over high-contrast content may not belong there.

---

## 5. Color is never the only signal

"Avoid relying solely on color to differentiate between objects" (HIG Color). For Differentiate Without Color: "Offer visual indicators, like distinct shapes or icons, in addition to color."

```swift
// ❌ Only the red says "destructive"
Button("Delete") { delete() }
    .buttonStyle(.glassProminent)
    .tint(.red)

// ✅ Role + symbol + text; not the prominent primary
Button(role: .destructive) { delete() } label: {
    Label("Delete", systemImage: "trash")
}
.buttonStyle(.glass)
```

`role: .destructive` gives system red. HIG Buttons: "Don't assign the primary role to a button that performs a destructive action."

---

## 6. VoiceOver

Glass is visual. VoiceOver users need the same things they always need:

- **Every control has a label.** `Button("Share", systemImage: "square.and.arrow.up")` provides one, even with `.labelStyle(.iconOnly)`. For image-only labels, add `.accessibilityLabel(_:)`.
- **Hints are optional.** "You should provide a hint only when the results of an action are not obvious from the element's label" (Apple Accessibility Programming Guide).
- **Selection.** Mark a selected state with `.accessibilityAddTraits(.isSelected)`.
- **Decorative glass** that isn't a control gets `.accessibilityHidden(true)`.
- **Expanding menus.** Newly revealed buttons need labels too. Check that the focus order still makes sense after a morph.
- **Content-switching pickers.** On iOS 27, `.pickerStyle(.tabs)` makes VoiceOver announce the options as tabs.

---

## 7. Dynamic Type and hit targets

Let content set the size. Fixed heights clip large text inside glass capsules.

```swift
// ❌
Text(title).frame(width: 200, height: 44).glassEffect()

// ✅
Text(title)
    .padding(.horizontal, 16).padding(.vertical, 10)
    .glassEffect()
```

- **Hit region.** "A button needs a hit region of at least 44x44 pt — in visionOS, 60x60 pt" (HIG Buttons). Frame the *label* of icon-only buttons at 44 pt or more.
- **Spacing.** HIG Accessibility asks for about 12 pt around bezeled controls and about 24 pt around controls without a bezel.
- **Test** at the largest accessibility text sizes. Glass bars and tab bars adapt; custom floating glass must too.

---

## 8. The Liquid Glass look setting

Users choose a preferred look for Liquid Glass in Settings: **Clear or Tinted** in iOS 26.1, and in iOS 27 a slider "anywhere from ultra clear to fully tinted". Standard glass follows it automatically.

- **No API reads the setting.** Don't invent one.
- **Test at both ends.** Legibility is weakest at ultra clear. At fully tinted, check that prominent and tinted controls still stand out.
- **It is separate from Reduce Transparency.** That accessibility setting still applies on top of the look setting.

---

## 9. Smart Invert

Smart Invert inverts colors "except for images, media, and some apps that use dark color styles" (Apple Support). System colors are not exempt.

- Mark photos, video, maps, and brand artwork with `.accessibilityIgnoresInvertColors()` so they don't invert.
- Turn Smart Invert on and check that the primary actions are still legible and that glass over media still reads.

---

## 10. Audit checklist

```
- [ ] Reduce Transparency ON: glass frosts; custom backgrounds become opaque; text readable
- [ ] Increase Contrast ON: borders appear; your colors meet the higher-contrast scheme
- [ ] Reduce Motion ON: custom animations calmer (less bounce, fades); morphs still complete
- [ ] Show Borders ON: custom glass controls draw a visible edge
- [ ] Reduce Bright Effects ON (26.4+): custom shimmer/glow suppressed
- [ ] Liquid Glass slider at ultra clear and fully tinted (iOS 27)
- [ ] Largest accessibility text size: nothing clipped inside glass
- [ ] VoiceOver: every control labeled; hints only where needed; selection traits set
- [ ] Color Filters / grayscale check: no meaning carried by color alone
- [ ] Smart Invert: media marked accessibilityIgnoresInvertColors; CTAs legible
- [ ] Contrast: ≤17 pt text ≥ 4.5:1, ≥18 pt or bold ≥ 3:1, non-text UI ≥ 3:1
```

---

## Sources

- WWDC25 219 *Meet Liquid Glass* · WWDC26 102 *Platforms State of the Union*
- HIG: [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) · [Color](https://developer.apple.com/design/human-interface-guidelines/color) · [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) · [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- SwiftUI: [`accessibilityShowBorders`](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityshowborders) · [`accessibilityReduceHighlightingEffects`](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducehighlightingeffects) · [`accessibilityIgnoresInvertColors(_:)`](https://developer.apple.com/documentation/swiftui/view/accessibilityignoresinvertcolors(_:)) · [`Glass.identity`](https://developer.apple.com/documentation/swiftui/glass/identity)
