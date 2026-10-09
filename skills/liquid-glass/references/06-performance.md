# Performance

Apple publishes **qualitative** performance guidance for Liquid Glass and no numbers. This file states that guidance, gives the structural rules that follow from it, and explains how to measure. It has no frame-time budgets or "N× cheaper" multipliers, because no Apple source supports them. Measure on your own oldest supported device.

## Contents

1. [What Apple says](#1-what-apple-says)
2. [Structural rules](#2-structural-rules)
3. [When glass is the wrong tool](#3-when-glass-is-the-wrong-tool)
4. [Measuring](#4-measuring)
5. [Device floor](#5-device-floor)
6. [Checklist](#6-checklist)

---

## 1. What Apple says

- "Use `GlassEffectContainer` when applying Liquid Glass effects on multiple views to achieve the best rendering performance." (Applying Liquid Glass to custom views)
- "SwiftUI renders the effects together, improving rendering performance." (`GlassEffectContainer`)
- "Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance. Limit the use of Liquid Glass effects onscreen at the same time." (Applying Liquid Glass to custom views)
- "Performance test your app across platforms … Profile your app." (Adopting Liquid Glass)

---

## 2. Structural rules

1. **Group neighbors.** Two or more custom glass shapes near each other go in **one** `GlassEffectContainer`. That is better for rendering, and it's needed for correct visuals anyway, since glass can't sample other glass.
2. **Don't over-containerize.** Use one container per cluster, not one per view, and not nested containers for the same cluster.
3. **Keep the count low.** "Limit the use of Liquid Glass effects onscreen at the same time." A screen usually needs the system bars plus a handful of custom glass controls at most.
4. **No glass in repeated content.** List rows, grid cells, and cards are content layer. Glass doesn't belong there, and each row would add another effect.
5. **`.interactive()` only on things people touch.** It adds touch tracking and response. Labels and status chips don't need it.
6. **Animate glass inside its container.** Morphs and materialize transitions are designed for container children.
7. **Glass over video.** It works; video players use it. Use `.clear` with dimming over bright video. AVKit's controls bring their own dimming. Hide transient controls during playback as video apps usually do. Note that `.clear` is a *legibility* choice: Apple gives no performance reason to prefer it.

```swift
// ❌ Glass in every row: content layer, and N effects on screen
List(items) { item in
    Text(item.title).padding().glassEffect()
}

// ✅ Plain rows; the bars above provide the glass
List(items) { item in
    Text(item.title)
}
```

---

## 3. When glass is the wrong tool

| You want… | Use |
|---|---|
| A card or panel in the content | `.background(.background, in: .rect(cornerRadius: 20))`, or a standard material |
| A translucent content-layer surface | `.background(.regularMaterial, in: shape)` (standard materials are for the content layer) |
| A full-screen dimmer behind a modal | A system presentation (sheet or alert), or `Color.black.opacity(…)` |
| A decorative panel | A gradient or solid fill |
| A loading state | `ProgressView` |
| An empty state | `ContentUnavailableView` |
| A tooltip or coachmark | `.popover`, or TipKit |

---

## 4. Measuring

- **Instruments → SwiftUI.** View body updates and layout during glass-heavy interactions (WWDC25 306 *Optimize SwiftUI performance with Instruments*).
- **Instruments → Animation Hitches.** Dropped frames during morphs, materialize transitions, and scrolling under bars (Apple Tech Talks *Explore UI animation hitches and the render loop*).
- **Hangs and responsiveness.** WWDC26 268 *Profile, fix, and verify: Improve app responsiveness with Instruments*.
- **Xcode 27 Organizer.** The new *Hitches* metric "replaces the Scrolling metric in the Organizer, now displaying animation hitches for all animations in your app".

**How to profile:**
1. Use a release build on the slowest device you support.
2. Show the busiest content you have behind the glass.
3. Run the interactions that move glass: open and close menus, scroll under minimizing bars, drag.
4. Compare against the same screen with the custom glass removed. The difference is what the glass costs you.

---

## 5. Device floor

- **iPhone.** iOS 26 and iOS 27 support iPhone 11 and later (A13), and iOS 27 dropped no devices. Profile your worst screen there.
- **Apple TV.** "Apple TV 4K (2nd generation) and newer models support Liquid Glass effects. On older devices, your app maintains its current appearance."
- **Older iPhones** can't run iOS 26, so there is no "older device fallback" for you to write.

---

## 6. Checklist

```
- [ ] Every cluster of 2+ custom glass shapes is in one GlassEffectContainer
- [ ] No container per view; no nested containers for one cluster
- [ ] No glass in List/Grid rows or content cards
- [ ] .interactive() only on touchable custom glass
- [ ] Glass morphs/insertions happen inside the container, inside withAnimation
- [ ] Profiled (SwiftUI + Animation Hitches) in release on the oldest supported device
```

---

## Sources

- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views) · [`GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) · [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- WWDC25 306 · WWDC26 268 · Apple Tech Talks 10856/10857 · Xcode 27 release notes
