# Accessibility

Liquid Glass is built to adapt automatically to most accessibility settings, but "automatic" doesn't mean "free." You still own contrast, custom backgrounds, and color semantics. This file covers the system adaptations, the parts you must verify, and the parts you must hand-code.

---

## System-managed adaptations

When the user enables one of these settings, the OS modifies glass rendering for you:

| Setting | What changes |
|---|---|
| **Reduce Transparency** | Glass densifies into an opaque material with subtle border; lensing disabled |
| **Increase Contrast** | Stark border added, tints saturate, text contrast strengthened |
| **Reduce Motion** | Specular tracking off, morphing replaced with cross-fade or hard cut, materialize transitions suppressed |
| **Differentiate Without Color** | Adds shape/icon cues alongside tint-based meaning (in system components) |
| **Tinted Mode (iOS 26.1+)** | User-controlled opacity multiplier applied globally |
| **Smart Invert** | Glass tint inverts; background image stays |

You don't need to opt into any of these. The system handles them for `.glassEffect()`, `.buttonStyle(.glass)`, `TabView`, `Toolbar`, and `NavigationStack`.

**But:** custom backgrounds you stack *behind* glass don't get any of these adaptations for free. If you're drawing a custom photo or gradient under glass, you must check those settings yourself.

---

## Reading accessibility environment values

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion)       var reduceMotion
@Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
@Environment(\.colorSchemeContrast)             var colorSchemeContrast  // .standard | .increased
```

### Opting out of glass entirely
```swift
view.glassEffect(reduceTransparency ? .identity : .regular)
```

`.identity` produces no glass effect — useful when you have a custom rendering that doesn't degrade gracefully under densified glass.

### Adapting custom backgrounds
```swift
ZStack {
    if reduceTransparency {
        Color.black.opacity(0.85)     // opaque fallback
    } else {
        Image("hero").resizable().scaledToFill()
    }
}
```

---

## Contrast

Liquid Glass refracts and dims its background to keep text legible, but it doesn't guarantee contrast — you do.

| Text role | Minimum ratio (WCAG AA) |
|---|---|
| Body text (< 18pt regular, < 14pt bold) | **4.5 : 1** |
| Large text (≥ 18pt regular, ≥ 14pt bold) | **3 : 1** |
| Non-text UI (icons, borders) | **3 : 1** |

### How to verify
1. Build & run on device with the **busiest, brightest** background your app will display behind glass (white photos, neon UI, etc.).
2. Use Xcode → Accessibility Inspector → Color Contrast Calculator.
3. Repeat in Dark Mode and with Increase Contrast enabled.

### Common fix
If contrast fails:
1. Strengthen the foreground (heavier weight, `.primary` instead of `.secondary`).
2. Add a subtle scrim *behind* the glass, not on it: `Color.black.opacity(0.15).blendMode(.plusDarker)`.
3. As last resort, switch the glass variant: `.regular` is denser than `.clear`.

---

## Tint should never be the only signal

If you use `.tint(.red)` to mean "destructive" or `.tint(.green)` to mean "success," users with color blindness or `Differentiate Without Color` enabled won't get the message.

### ❌ tint-only
```swift
Button("Delete") { delete() }
    .buttonStyle(.glassProminent)
    .tint(.red)
```

### ✅ tint + icon + label
```swift
Button(role: .destructive) { delete() } label: {
    Label("Delete", systemImage: "trash")
}
.buttonStyle(.glassProminent)
.tint(.red)
```

Using `role: .destructive` is the canonical way — the system applies the right tint *and* shape cues across accessibility modes.

---

## VoiceOver

Glass is purely visual; VoiceOver users get no benefit and no penalty from it. But the controls inside glass surfaces need normal accessibility treatment:

```swift
Button { } label: {
    Image(systemName: "trash")
}
.buttonStyle(.glass)
.buttonBorderShape(.circle)
.accessibilityLabel("Delete photo")
.accessibilityHint("Removes this photo from your library")
```

For glass elements that are decorative only (a background blob, a non-interactive chip):
```swift
.accessibilityHidden(true)
```

---

## Dynamic Type

Glass containers must grow with text. If you've hardcoded heights, your `.glassEffect(in: .capsule)` will clip giant text.

### ❌
```swift
Text(label)
    .frame(width: 200, height: 44)
    .glassEffect()
```

### ✅
```swift
Text(label)
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .glassEffect()
```

Let intrinsic content drive size. The glass shape grows with it.

---

## Hit targets

Apple's minimum tappable area is **44 × 44 points**. Glass shouldn't change that — the visual size of a glass pill ≠ its hit target. For icon buttons:

```swift
Button { } label: {
    Image(systemName: "x.circle")
        .font(.title2)
        .frame(width: 44, height: 44)  // hit target
}
.buttonStyle(.glass)
.buttonBorderShape(.circle)
.contentShape(Circle())                 // ensures circle hit shape
```

---

## Tinted Mode (iOS 26.1+)

Users can globally reduce app glassiness via Settings → Accessibility → Display. The system applies the chosen opacity to all `.glassEffect` automatically. You don't write code for this — but verify your design still reads at maximum opacity (essentially solid).

---

## Smart Invert

Smart Invert flips foreground colors but preserves images and media. Your glass tint will invert; your background photo won't. Test by enabling Settings → Accessibility → Display & Text Size → Smart Invert.

Common breakage:
- `.tint(.white)` becomes `.tint(.black)` — primary action disappears against dark UI
- Solution: use **system colors** (`.tint(.blue)`, `.tint(.accentColor)`), which Smart Invert leaves alone

---

## Accessibility audit checklist

Before shipping a screen with glass:

- [ ] Toggle **Reduce Transparency** → glass becomes opaque, text still readable
- [ ] Toggle **Increase Contrast** → borders appear, no unintended dark blobs
- [ ] Toggle **Reduce Motion** → no morphs/shimmers, controls still work
- [ ] Test largest **Dynamic Type** size → no clipped labels in glass pills
- [ ] **VoiceOver** sweep → every glass control has a label & hint
- [ ] **Smart Invert** → primary CTAs still legible
- [ ] **Color blind simulators** (Xcode → Color Vision Tests) → tint isn't the only cue
- [ ] Contrast ≥ 4.5:1 on body text, ≥ 3:1 on large text & icons
