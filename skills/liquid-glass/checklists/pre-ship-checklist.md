# Pre-ship checklist: Liquid Glass

Run this before submitting a build. Copy it into your response, check each item, fix what fails, and re-run the linter until it's clean.

```
python3 <skill-dir>/scripts/check_glass.py <sources> --target <deployment target>
```

---

## Layering

- [ ] Glass appears only on controls and navigation floating above content.
- [ ] No glass on cards, list rows, tags or chips, heroes, empty or error states, or backgrounds. Those use solid colors or standard materials.
- [ ] No glass on glass. Anything on a glass surface uses fills or vibrant foreground styles.
- [ ] No `.glassEffect()` on system bars, toolbar items, tab bars, search fields, sheets, or the tab bar accessory's controls.
- [ ] No custom bar backgrounds (`toolbarBackground(Color…)`, colored appearance proxies).

## API correctness

- [ ] Linter reports no `error`.
- [ ] No invented parameters or names: `isEnabled:` on `glassEffect` or `glassEffectTransition`, `.containerConcentric`, `scrollExtensionMode`, `toolbarMinimizeBehavior`, `.collapsed`, `.minimized`.
- [ ] `DefaultToolbarItem` sits directly in `.toolbar { }`. `ToolbarContent` modifiers are applied to `ToolbarItem` / `ToolbarItemGroup`.
- [ ] Nearby custom glass shares one `GlassEffectContainer`, with container spacing ≤ layout spacing unless the shapes should fuse.
- [ ] Morphing views have IDs in one `@Namespace`, live in one container, and change inside `withAnimation`.
- [ ] Glass is inserted or removed (materialize), never faded with `.opacity`.
- [ ] `.interactive()` only on custom glass that responds to touch. Buttons use `.buttonStyle(.glass)` or `.glassProminent`.

## Shapes

- [ ] Inner shapes inside rounded containers use `ConcentricRectangle` / `.rect(corners: .concentric…)`, and the parent declares `.containerShape(_:)`.
- [ ] Capsules for label buttons, circles for icon-only buttons. Custom shapes only with a reason.

## Color

- [ ] One prominent primary action per view, at most two: `.buttonStyle(.glassProminent)`, tinted with the accent color.
- [ ] Bar items and secondary glass buttons are untinted. Tints convey meaning, not decoration.
- [ ] Brand color is in the content layer.
- [ ] Destructive actions use `role: .destructive` and aren't the prominent primary.
- [ ] System colors only, with no hard-coded hex on glass.

## Variants and backgrounds

- [ ] `.regular` by default.
- [ ] `.clear` only over media-rich content, with bold content on top and a dimming layer (about 35%) over bright media.
- [ ] No mix of `.clear` and `.regular` within a group.
- [ ] Tested over the busiest and brightest real content, in Light and Dark.
- [ ] iOS 27: tested at both ends of the Liquid Glass slider (ultra clear and fully tinted).

## Motion

- [ ] Every custom glass change happens inside an animation, so morphs and materializations complete.
- [ ] Under Reduce Motion, custom animations get calmer (less bounce, fades instead of movement) rather than disappearing.

## Accessibility

- [ ] **Reduce Transparency**: glass frosts by itself (no `.identity` swap), and custom backgrounds become opaque.
- [ ] **Increase Contrast**: your own colors meet the higher-contrast scheme.
- [ ] **Show Borders**: custom glass controls draw a visible edge.
- [ ] **Reduce Bright Effects** (26.4+): custom shimmer and glow are suppressed.
- [ ] **Largest accessibility text size**: no clipped text in glass, and sizes come from content, not fixed heights.
- [ ] **VoiceOver**: every control has a label, hints appear only where the result isn't obvious, and selection traits are set.
- [ ] **Smart Invert**: media is marked `accessibilityIgnoresInvertColors()`, and primary actions stay legible.
- [ ] **Color**: meaning never relies on color alone (check with Color Filters or grayscale).
- [ ] **Contrast**: text up to 17 pt ≥ 4.5:1; 18 pt or bold ≥ 3:1; non-text UI ≥ 3:1.
- [ ] Hit regions are at least 44 × 44 pt.

## Chrome

- [ ] Sheets have no `presentationBackground`. Their buttons follow the HIG: Close ✕ for informational sheets; Cancel on the leading edge and Done on the trailing edge for task sheets.
- [ ] Dialogs are attached to the buttons that present them.
- [ ] Toolbar items are grouped with `ToolbarItemGroup`, and fixed `ToolbarSpacer`s are used only where needed.
- [ ] Tab bar: search uses `Tab(role: .search)` + `.searchable` on the `TabView`. `TabView(selection:)` never targets a hidden tab.
- [ ] Scroll edge effects: `.automatic`, with any `.soft` override re-checked on iOS 27, and no hand-made scrims under bars.

## Performance

- [ ] One container per cluster, with no extra containers. Few glass effects on screen at once.
- [ ] No glass in list or grid rows.
- [ ] Profiled with the SwiftUI and Animation Hitches instruments, in a release build, on the oldest supported device (iPhone 11 / A13 for iOS 26–27).

## Devices and layouts

- [ ] iPhone, in portrait and landscape.
- [ ] iPad, with the tab bar as a sidebar (`.sidebarAdaptable`) and resizable windows (opted in automatically with the 27 SDK).
- [ ] iPhone Duo in Device Hub (iOS 27.1): vertical side bars, folded poses, and custom floating glass clear of the bars and reserved regions.
- [ ] Mac or Mac Catalyst, if shipped.

## Build and availability

- [ ] Built with Xcode 27 (iOS 27 SDK). App Store uploads require it from April 2027.
- [ ] `UIDesignRequiresCompatibility` removed. It is ignored for 27-SDK builds.
- [ ] Deployment target 26.x: every iOS 27 API is behind `#available(iOS 27.0, *)`. Linter `info` items reviewed.
- [ ] Deployment target below 26: custom glass is behind `#available(iOS 26.0, *)`, with a material fallback.
- [ ] Deprecated-in-27.2 calls replaced, or scheduled for replacement (`toolbarBackground(.hidden…)`, `toolbar(.hidden…)`, `ScrollView(showsIndicators:)`, view-argument `overlay` / `background`, `.roundedBorder`).
- [ ] The app has a launch screen and uses the scene life cycle. `#Preview` instead of `PreviewProvider`.

---

## If something looks wrong

| Symptom | Likely cause | Fix |
|---|---|---|
| Glass doesn't morph and cuts instead | Missing container, ID, or `withAnimation` | Add all three ([04 § 3](../references/04-motion-and-interaction.md#3-morphing)) |
| Neighboring buttons fuse into one blob | Container spacing > layout spacing | Lower the container spacing |
| Glass looks inconsistent between neighbors | They're in different containers | Use one container |
| A toolbar item looks doubled or too bright | `.glassEffect()` added on system glass | Remove it |
| Text on glass is hard to read | `.clear` over bright content, a thin weight, or text-heavy glass | Use `.regular`, a heavier weight, or dimming beneath |
| Inner corners don't line up | No `containerShape` on the parent | Add `.containerShape(.rect(cornerRadius: R))` |
| A sheet lost its glass | `presentationBackground` is set | Remove it |
| Build error: "only available in iOS 27.0 or newer" | Ungated iOS 27 API on a 26 target | Gate it ([08 § 9](../references/08-system-chrome.md#9-gating-ios-27-chrome-apis-on-a-26-target)) |
| `toolbarMinimizeBehavior` not found | The WWDC26 video spelling | `toolbarMinimizationBehavior(_:for:)` |
| Controls in a sheet lost their size or shape | The iOS 27 SDK resets control environment in sheets | Set them inside the sheet |
