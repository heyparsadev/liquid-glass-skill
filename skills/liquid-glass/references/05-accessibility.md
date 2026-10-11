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

### Measured on iOS 27

These ratios were measured, not published by Apple. They come from a travel app built with this skill (six screens and a scrolled variant) and captured on the iOS 27.0 simulator in October 2026, light and dark, using the WCAG 2.x formula. The app, its 14 screenshots, and the measuring script are in [liquid-glass-showcase](https://github.com/heyparsadev/liquid-glass-showcase).

| Foreground | Background | Measured | Text up to 17 pt |
|---|---|---|---|
| `.secondary` | Regular glass (sheets, controls) over photos and maps | 2.3–3.9 : 1 | Fails |
| `.secondary` | Light grouped background | 3.3 : 1 | Fails |
| `.primary` | Regular glass over photos and maps (dark mode: backdrop dimmed under sheets) | 4.8 : 1 and up | Passes |
| `.primary` | A sheet over bright imagery, dark mode | 4.2 : 1 | Fails until the backdrop is dimmed |
| White label | `.glassProminent` on the system blue | 3.2–3.5 : 1 | Fails (3 : 1 is enough only for bold labels) |
| White label | `.glassProminent` on an accent of `#0066CC` | 5.6 : 1 | Passes |
| White bar and status bar glyphs | Pale sky photo, dark mode | 2.1–2.4 : 1 | Fails (icons need 3 : 1) |

Text that iOS draws stays at system contrast, because `foregroundStyle` on its `Text` is ignored: the `.searchable` prompt measured 3.8 : 1 (light) and 2.6 : 1 (dark) over a map, and `navigationSubtitle` 3.3–3.4 : 1 on the light background. When the title is inline, a `ToolbarItem(placement: .subtitle)` replaces the subtitle with your own `Text`, which you can style (Apple; not measured here). MapKit's "Legal" link measured 2.5 : 1 over satellite imagery.

What fixed the failures:
- **Text on glass.** Use `.primary` and carry the hierarchy with size and weight. Don't use `.secondary` on glass at any size: it measured as low as 2.3 : 1, under the 3 : 1 that 18 pt or bold text needs.
- **Secondary text on opaque content.** The system `.secondary` measured 3.3 : 1 on the light grouped background. If you hold small text to 4.5 : 1, use a stronger color, for example black at 72% opacity in light mode and white at 88% in dark. Keep it off glass, which needs the vibrant styles.
- **Section headers in a sheet.** A `Section` header dims `.foregroundStyle(.primary)` along with the rest of the header. `Color.primary` keeps full strength.
- **Prominent buttons.** Set the app's AccentColor asset to a blue dark enough for a white label (`#0066CC` measured 5.6 : 1). The cost: as an icon color on dark cards that accent measured 3.1–3.3 : 1, just over the 3 : 1 icons need. With that accent, a `.glassProminent` button in a toolbar drew its label black in dark mode (4.0 : 1), so set `.foregroundStyle(.white)` on the label's `Text`.
- **Bar glyphs over a pale photo.** `.toolbarColorScheme(.light, for: .navigationBar, .statusBar)` keeps them dark in both appearances. `.statusBar` is iOS 27 ([08 §3](08-system-chrome.md#status-bar-toolbarplacementstatusbar)).
- **A sheet over bright imagery in dark mode.** Dim the backdrop under the sheet, not the sheet ([08 §7](08-system-chrome.md#7-sheets-popovers-and-dialogs)).

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
- Measured: [liquid-glass-showcase](https://github.com/heyparsadev/liquid-glass-showcase), iOS 27.0 simulator, October 2026 (§4, *Measured on iOS 27*)
- HIG: [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) · [Color](https://developer.apple.com/design/human-interface-guidelines/color) · [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) · [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- SwiftUI: [`accessibilityShowBorders`](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityshowborders) · [`accessibilityReduceHighlightingEffects`](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducehighlightingeffects) · [`accessibilityIgnoresInvertColors(_:)`](https://developer.apple.com/documentation/swiftui/view/accessibilityignoresinvertcolors(_:)) · [`Glass.identity`](https://developer.apple.com/documentation/swiftui/glass/identity)
