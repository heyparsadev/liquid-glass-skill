# Pre-Ship Checklist — Liquid Glass

Run this before submitting any iOS 26 build to App Store Connect. Each item is a 30-second check; collectively they catch ~95% of glass-related ship issues.

---

## API correctness

- [ ] No `.ultraThinMaterial` / `.regularMaterial` / `.thinMaterial` left in iOS 26 code paths
- [ ] No manual `Blur` / `VisualEffectView` wrappers — using `.glassEffect()` instead
- [ ] No `.glassEffect()` applied **inside** another `.glassEffect()` (glass-on-glass)
- [ ] Every cluster of ≥ 2 glass elements is wrapped in `GlassEffectContainer`
- [ ] Morphing elements have `.glassEffectID(_, in:)` + a shared `@Namespace`
- [ ] State changes that drive morphing are wrapped in `withAnimation { }`
- [ ] `.interactive()` only on tappable / draggable elements, not static labels

## Layering

- [ ] Glass lives only on the chrome / navigation layer
- [ ] No glass on `List` rows, card bodies, hero backgrounds, or full-screen backdrops
- [ ] Maximum two glass layers stacked anywhere in the view tree
- [ ] System-provided glass (nav bar, tab bar, toolbar items) isn't being double-wrapped

## Corners & shapes

- [ ] Inner glass shapes inside rounded containers use `.containerConcentric` radii
- [ ] Default `Capsule` shape used for label buttons; `Circle` for icon buttons
- [ ] Custom shapes used only with reason; documented in code

## Tinting

- [ ] Tints are system colors (`.blue`, `.red`, `.accentColor`), not raw hex
- [ ] No saturated tint that kills refraction (verified visually)
- [ ] Brand color is tinting **content**, not glass surface
- [ ] Destructive actions use `role: .destructive`, not tint alone

## Backgrounds

- [ ] Glass tested over: photographic content, white background, dark gradient, full-color brand background
- [ ] Glass over flat color cases either replaced or background varied with subtle gradient
- [ ] `NavigationStack` content has `.scrollContentBackground(.hidden)` where appropriate

## Motion

- [ ] No `.linear` animations applied to glass state changes
- [ ] `.bouncy` for morphs, `.smooth` for nav collapses, `.snappy` for instant toggles
- [ ] Animations gated by `accessibilityReduceMotion` where custom-driven

## Accessibility

- [ ] **Reduce Transparency** ON → glass densifies, text remains legible, layout intact
- [ ] **Increase Contrast** ON → borders appear, no surprise dark blobs
- [ ] **Reduce Motion** ON → no morph/shimmer, controls still work
- [ ] **Smart Invert** ON → primary CTAs still legible (system colors used)
- [ ] **Largest Dynamic Type** → no clipped text in glass pills (intrinsic sizing used)
- [ ] **Color Vision tests** (Xcode) → tint isn't the only signal
- [ ] **VoiceOver** sweep → every interactive glass element has label + hint
- [ ] Body text contrast ≥ 4.5:1 on busiest background

## Performance

- [ ] Metal System Trace shows one composite phase per `GlassEffectContainer` per frame
- [ ] No glass on long scrollables (lists, lazy grids) with > 20 cells visible
- [ ] No glass over `AVPlayer` 4K content unless `.clear` variant
- [ ] Animation Hitch template shows no frame drops during glass morph transitions
- [ ] `.interactive()` not applied to > 8 elements simultaneously

## Devices

- [ ] Tested on **iPhone 11** (oldest supported) — confirms acceptable frame rate
- [ ] Tested on **iPad Pro 13"** — confirms layout adapts (esp. `NavigationSplitView`)
- [ ] Tested in **Light** + **Dark** mode side-by-side
- [ ] Tested in **landscape** on iPhone — toolbar / tab bar still glass

## State

- [ ] Loading states have no glass spinners (use system `ProgressView`)
- [ ] Error states show solid surfaces, not glass (legibility first)
- [ ] Empty states use `ContentUnavailableView`, not custom glass cards

## Build

- [ ] `IPHONEOS_DEPLOYMENT_TARGET = 26.0` (or higher) in build settings
- [ ] Built with **Xcode 26+**
- [ ] No `@available(iOS 26.0, *)` left over from migration (entire target is 26+)
- [ ] No `#if compiler(...)` flags around glass code

---

## If you find a problem

| Symptom | Likely cause | Fix |
|---|---|---|
| Glass looks gray/flat | Background is solid color | Add varied content behind, or remove glass |
| Glass doesn't morph | Missing `GlassEffectContainer` or `glassEffectID` | Add both |
| Hard cut during animation | Missing `withAnimation` | Wrap state mutation |
| Toolbar item too bright | Adding `.glassEffect()` over system glass | Remove the manual `.glassEffect()` |
| Hitchy scroll | Glass on list rows | Move glass to chrome only |
| Tint reads wrong in Light/Dark | Used raw hex | Switch to system color |
| Text unreadable on glass | Insufficient contrast | Strengthen weight, switch variant, or add scrim behind |
