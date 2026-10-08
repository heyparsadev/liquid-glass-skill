# audit-references

_Phase: Audit_

## Summary

Audited every line of SKILL.md, references/02–07 and checklists/pre-ship-checklist.md. Sources checked: Apple DocC JSON (Glass, glassEffect(_:in:), GlassEffectContainer, Glass.clear/identity, ConcentricRectangle, accessibilityIgnoresInvertColors, UIDesignRequiresCompatibility, the Applying Liquid Glass and Adopting Liquid Glass articles, SwiftUI updates); HIG JSON (Materials, Color, Branding, Toolbars, Tab bars, Buttons, Accessibility, VoiceOver, Motion, Scroll views, Design principles, Designing for iPhone Duo, What's new); WWDC25 transcripts 219/323/356; WWDC26 transcripts 102 (State of the Union), 251, 269, 278. I found 43 problems.

MOST SEVERE
1. **Glass on glass.** "Maximum two glass layers" (SKILL L85, 02 L65/L160, checklist L21) contradicts Apple's "always avoid glass on glass". It also contradicts the skill's own checklist L11 and 02 L56.
2. **Material ban.** The blanket ban (SKILL L88/L12, 07 #2, checklist L9) contradicts HIG Materials, which says to use standard materials in the content layer. 06 L74 contradicts the ban.
3. **Reduce Transparency.** Swapping to Glass.identity removes the backing entirely ("content remains unaffected as if no glass effect was applied"). The system already makes glass "frostier".
4. **Tint rationale.** "Tint destroys refraction" is contradicted by WWDC25 219: tinting "is natively compatible with all the behaviors of glass".
5. **Brand color.** Guidance is inverted. HIG Branding (Sept 9, 2026), Toolbars and Color, plus WWDC26 251, put brand color in the content layer and accent color on the background of the one primary action. The skill puts it on control labels.
6. **Accessibility table.** It misstates what Increase Contrast, Reduce Motion and Reduce Transparency do.
7. **"Tinted Mode".** It is wrong in name, version, settings path and mechanics. iOS 27 replaced the iOS 26.1 Clear/Tinted choice with a slider "from ultra clear to fully tinted".
8. **Smart Invert.** It does not leave system colors alone. accessibilityIgnoresInvertColors is the opt-out.
9. **Container spacing.** GlassEffectContainer spacing is backwards (04 L116, 03 L32). "Use separate containers" contradicts WWDC25 323.
10. **Concentric corners.** The examples never declare containerShape, so the inner corners won't match the card.
11. **isEnabled fixes.** They rely on an isEnabled parameter that the documented glassEffect(_:in:) does not have.
12. **Numbers.** None of the performance numbers or thresholds has an Apple source: 5×, 1–3 ms, sub-30fps, >8, >20, 95%. Neither do the Instruments phases "GlassEffect: layout" and "GlassEffect: composite".

OTHER ISSUES
- Wrong session number: 284 should be 356.
- Unsourced quotes at 02 L10, L24 and L121.
- "HIG organized around Hierarchy/Harmony/Consistency" is wrong. Those words come from the Liquid Glass overview, and the HIG reintroduced eight design principles on June 8, 2026.
- visionOS is listed, but the Glass APIs list no visionOS availability.
- Hints are required on every control, which Apple does not ask for.
- SF Symbols 7 should become 8 for the 27 releases.
- Unsourced claims about gyroscope-driven highlights, tinted shadows and "flat color = blob".
- "Static glass is a code smell".
- The recipe library uses opacity transitions on glass, which the skill bans elsewhere.

iOS 27 CHANGES TO ADD
- The material was retuned: more diffusion, a darkened edge and brighter specular highlights. Apps get this automatically without recompiling.
- The Liquid Glass slider. Custom glass responds to it automatically.
- UIDesignRequiresCompatibility is ignored when building for 27, and the opt-out is removed with Xcode 27.
- iPhone Duo (Sept 2026): bars move to the vertical axis, plus ReservedRegion and testing in Device Hub.
- The automatic scroll edge effect visuals changed (re-evaluate `.soft` overrides).
- The SwiftUI June and Sept 2026 updates add no new glassEffect APIs. They add toolbar APIs, TabRole.prominent, NavigationTransition.crossFade and iPhone Duo APIs.
- HIG Materials is unchanged since Sept 2025.

CORRECT AND IMPORTANT (no finding needed)
- Glass belongs only on the controls/navigation layer (HIG Materials).
- Use GlassEffectContainer for nearby glass. The sentence "glass can not sample other glass" is Apple's wording (WWDC25 323).
- Don't re-glass system bars; remove custom bar backgrounds.
- Prefer system colors.
- Tint sparingly for primary actions (one or two prominent buttons).
- Never rely on color alone.
- 44×44 pt hit region (HIG Buttons).
- Morphing needs a container, glassEffectID and an animation.
- Sheets can morph out of toolbar buttons with matchedTransitionSource and navigationTransition(.zoom).
- Glass "materializes instead of fading".
- WWDC25 session 219 is correctly cited.
- iPhone 11 is still the oldest supported iPhone on iOS 27 (secondary source: AppleInsider). "Built with Xcode 26+" matches the App Store requirement in force since April 28, 2026.

## Findings (43)

### 0. `factually-wrong` — "Never glass-on-glass-on-glass. Maximum two layers." Repeated at 02-hig-principles.md L65 ("Maximum two glass layers stacked. A glass card sitting on a glass nav bar = OK"), L160 ("max 2 layers"), and pre-ship-checklist.md L21 ("Maximum two glass layers stacked anywhere").  
_skills/liquid-glass/SKILL.md:85_

- **Correct / new info:** Apple allows zero stacked glass layers. WWDC25 219 "Meet Liquid Glass": "Similarly, always avoid glass on glass. Stacking Liquid Glass elements on top of each other can quickly make the interface feel cluttered and confusing." and "When placing elements on top of Liquid Glass, avoid applying the material to both layers. Instead, use fills, transparency, and vibrancy for the top elements to make them feel like a thin overlay that is part of the material." The skill also contradicts itself. Checklist L11 bans glass inside glass, and 02 L56 says cards get no glass, yet 02 L65 approves a glass card on a glass nav bar.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence high)
- **Action:** Replace with: "No glass on glass. Anything placed on a glass surface uses fills, transparency or vibrant foreground styles, never another .glassEffect()." Update 02 L65 and L160 and checklist L21 to match checklist L11. Delete "glass card on glass nav bar = OK".

### 1. `factually-wrong` — "Never use .ultraThinMaterial or other legacy Material values in iOS 26+. They look out of place." The same rule appears at SKILL L12 ("No legacy Material fallbacks"), 02 L162, 07 #2 L40-56 ("renders as the old material ... looks out of place") and checklist L9. 06-performance L74 contradicts it (".regularMaterial (legacy) is still legal").  
_skills/liquid-glass/SKILL.md:88_

- **Correct / new info:** Standard materials are current guidance for the content layer, not legacy. HIG Materials (updated Sep 9, 2025, and unchanged for the 27 releases) says: "Don't use Liquid Glass in the content layer. ... Instead, use standard materials for elements in the content layer, such as app backgrounds." Its iOS/iPadOS section adds: "In addition to Liquid Glass, iOS and iPadOS continue to provide four standard materials — ultra-thin, thin, regular (default), and thick — which you can use in the content layer to help create visual distinction." The correct rule depends on the layer. Glass goes on floating controls and navigation; Material goes on content-layer surfaces.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Rewrite golden rule 5: "Floating controls/navigation → glass, not Material. Content-layer surfaces (cards, app backgrounds) → standard materials or solid colors, not glass." Remove the "legacy" wording in SKILL L12, 02 L162, 06 L74 and 07 #2. Change checklist L9 to "No Material on floating chrome; no glass on content surfaces".

### 2. `bad-practice` — "Respect accessibilityReduceTransparency — pass .identity to glassEffect to opt out." 05-accessibility L37 does the same: `view.glassEffect(reduceTransparency ? .identity : .regular)`.  
_skills/liquid-glass/SKILL.md:90_

- **Correct / new info:** Glass.identity doc: "The identity variant of glass. When applied, your content remains unaffected as if no glass effect was applied." So under Reduce Transparency, labels lose their backing and sit directly on busy content. That is the opposite of what the user asked for. Apple (WWDC25 219): "Reduced Transparency, makes Liquid Glass frostier and obscures more of the content behind it ... These are available automatically whenever you use the new material." WWDC26 State of the Union: "Liquid Glass seamlessly adapts to a variety of accessibility settings users may choose, such as reducing transparency or increasing contrast." The skill's own 02 L141 says glass densifies automatically, which contradicts SKILL L90. 05 L46 also labels `Color.black.opacity(0.85)` an "opaque fallback", but it is 85% opacity and ignores Light Mode.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass/identity (apple-doc, confidence high)
- **Action:** Change rule 7 to: "No code needed. The system makes glass frostier under Reduce Transparency. If you deliberately drop glass (.identity), replace it with an opaque backing such as .background(.background, in: shape)." Fix 05 L35-46 to match, using a system background color instead of black at 0.85.

```swift
static var identity: Glass { get }
```

### 3. `factually-wrong` — "Heavy color destroys refraction." Also 02 L102 ("A saturated tint destroys refraction; you end up with a colored blob"), 02 L114 ("saturated tint kills lensing"), 02 L163 and 07 L93-96 ("The lensing effect ... is gone").  
_skills/liquid-glass/SKILL.md:89_

- **Correct / new info:** WWDC25 219: "Selecting a color generates a range of tones that are mapped to content brightness underneath the tinted element. It draws inspiration from how colored glass works in reality ... What's great is that tinting is natively compatible with all the behaviors of glass." Apple's reason to limit tint is hierarchy, not optics: "Tinting should only be used to bring emphasis to primary elements and actions in the UI. Avoid tinting all your elements. When every element is tinted, nothing stands out." The Applying Liquid Glass to custom views article says: "Assign a tint color to suggest prominence." HIG Buttons: "Keep the number of prominent buttons to one or two per view."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence high)
- **Action:** Keep "tint sparingly" but replace the optical rationale with Apple's (tint signals prominence; tint one or two primary actions). Remove "destroys refraction", "kills lensing" and "colored blob" everywhere.

### 4. `design-guidance` — "Brand identity | tint content only, never the glass", where "content" means the control's icon or label (02 L21, L103, L164; checklist L34). The 07 #4 "Right" fix brand-tints every toolbar label with `NavigationStack { ... }.tint(.purple)` and `.buttonStyle(.glass).tint(.purple)`. The palette at 03 L50-58 also assigns meanings such as purple = creative and pink = social.  
_skills/liquid-glass/references/03-design-tokens.md:67_

- **Correct / new info:** In Apple's guidance, "content" means the content layer under the controls, not a control's label. HIG Branding (refined Sep 9, 2026): "Apply your app's accent color judiciously. Using your brand color too broadly can overwhelm your interface and dilute its impact. Minimize its use on controls and instead use it intentionally for primary actions or status indicators, like badges for unread content or an icon for the selected tab in a tab bar. To express your brand through color, consider moving it into the content layer, where it scrolls beneath Liquid Glass controls and gets picked up dynamically." HIG Toolbars: "Reduce the use of toolbar backgrounds and tinted controls." HIG Color: "To emphasize primary actions, apply color to the background rather than to symbols or text. For example, the system applies the app accent color to the background in prominent buttons ... Refrain from adding color to the background of multiple controls." WWDC26 251: "our recommendation is to move color into the content area of your app ... Liquid Glass controls sit above the content layer and pick up your brand color dynamically."
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/branding (apple-other, confidence high)
- **Action:** Rewrite the brand rule: brand color lives in the content layer; the brand/accent color may fill the background of the one prominent primary action; other toolbar and tab labels stay monochrome (a selected tab icon may use accent). Replace the 07 #4 "Right" example. Drop the invented semantic palette, or label it a non-Apple convention.

### 5. `factually-wrong` — System-adaptation table: "Increase Contrast | Stark border added, tints saturate, text contrast strengthened"; L13 "Reduce Transparency | Glass densifies into an opaque material with subtle border; lensing disabled"; L15 "Reduce Motion | Specular tracking off, morphing replaced with cross-fade or hard cut, materialize transitions suppressed"; L16 Differentiate Without Color "adds shape/icon cues (in system components)".  
_skills/liquid-glass/references/05-accessibility.md:14_

- **Correct / new info:** WWDC25 219, verbatim: "Reduced Transparency, makes Liquid Glass frostier and obscures more of the content behind it. Increased contrast, makes elements predominantly black or white and highlights them with a contrasting border and Reduced Motion decreases the intensity of some effects and disables any elastic properties for the material." Apple says nothing about tints saturating, borders under Reduce Transparency, lensing being disabled, specular tracking turning off, or morphs becoming cross-fades or hard cuts. For Differentiate Without Color the HIG puts the work on the app: "Offer visual indicators, like distinct shapes or icons, in addition to color."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence high)
- **Action:** Replace rows L13-15 with Apple's wording. Remove "tints saturate". Reword the L16 row as the app's responsibility. Update the audit checklist lines L183-185 to match.

### 6. `factually-wrong` — Under Reduce Motion the system "Disables specular highlight tracking; Kills morphing animations (state changes still happen, but instantly); Suppresses materialization transitions". The snippet at L223 is `withAnimation(reduceMotion ? nil : .bouncy)`. Checklist L53 says "no morph/shimmer".  
_skills/liquid-glass/references/04-motion-and-interaction.md:213_

- **Correct / new info:** Apple (WWDC25 219): "Reduced Motion decreases the intensity of some effects and disables any elastic properties for the material." It does not remove morphs. The claim also contradicts 05 L15 ("cross-fade or hard cut"). For custom motion, HIG Accessibility recommends "Tightening animation springs to reduce bounce effects" and "Replacing transitions in x-, y-, and z-axes with fades", not removing animation, which produces the hard cuts the skill elsewhere calls a bug.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/accessibility (apple-other, confidence high)
- **Action:** Use Apple's wording. Change the snippet to a non-bouncy curve or fade, e.g. withAnimation(reduceMotion ? .smooth : .bouncy). Change checklist L53 to "motion reduced and non-elastic; controls still work".

### 7. `behavior-change` — "Tinted Mode (iOS 26.1+)": "Users can globally reduce app glassiness via Settings → Accessibility → Display. The system applies the chosen opacity to all .glassEffect automatically ... verify your design still reads at maximum opacity (essentially solid)." L17 calls it a "User-controlled opacity multiplier".  
_skills/liquid-glass/references/05-accessibility.md:165_

- **Correct / new info:** This is not an accessibility setting. HIG Materials: "people choose a preferred look for Liquid Glass in their device's settings". iOS 26.1 added a binary Clear/Tinted choice (Settings > Display & Brightness > Liquid Glass, per secondary sources). iOS 27 replaced it with a slider. WWDC26 Platforms State of the Union: "We also made it more personalizable with a new slider in settings to adjust Liquid Glass anywhere from ultra clear to fully tinted". WWDC26 What's new in SwiftUI: "Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint." Secondary sources put the slider at Settings > Appearance > Liquid Glass, centered by default. Legibility risk is greatest at the ultra-clear end, not only the tinted end.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/102/ (apple-video, confidence high)
- **Action:** Rename the section to "Liquid Glass look setting (iOS 26.1 Clear/Tinted → iOS 27 slider)". Remove the Accessibility path and the "opacity multiplier" wording. Require testing at both extremes, ultra clear and fully tinted. Keep it separate from Reduce Transparency.

### 8. `factually-wrong` — "Solution: use system colors (.tint(.blue), .tint(.accentColor)), which Smart Invert leaves alone". L18: "Smart Invert | Glass tint inverts; background image stays".  
_skills/liquid-glass/references/05-accessibility.md:175_

- **Correct / new info:** Apple Support's wording (HT207025, quoted by secondary sources): Smart Invert "reverses the colors on the display, except for images, media, and some apps that use dark color styles". System colors are not exempt. The documented per-view opt-out is accessibilityIgnoresInvertColors(_:): "Sets whether this view should ignore the system Smart Invert setting. ... Use this modifier to suppress Smart Invert in a view that shouldn't be inverted."
- **Availability:** iOS 14.0, iPadOS 14.0, Mac Catalyst 14.0, macOS 11.0, tvOS 14.0, visionOS 1.0, watchOS 7.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/accessibilityignoresinvertcolors(_:) (apple-doc, confidence medium)
- **Action:** Remove the claim that system colors are exempt. Recommend testing with Smart Invert on and marking photos, video and brand artwork with .accessibilityIgnoresInvertColors(). Phrase the L18 row as something to test, not a guaranteed behavior.

```swift
nonisolated func accessibilityIgnoresInvertColors(_ active: Bool = true) -> some View
```

### 9. `factually-wrong` — `GlassEffectContainer(spacing: 8) // morph aggressively — overlaps merge`. Also 03 L32 ("Distinct, non-morphing siblings | 40+ (or omit container)"), 03 L25 (spacing is the threshold within which elements "blend during transitions"), and 03 L151 ("Default morph threshold 16–24", next to L150 "nil (system optimal)").  
_skills/liquid-glass/references/04-motion-and-interaction.md:116_

- **Correct / new info:** The direction is backwards. GlassEffectContainer docs: "As shapes near one another, their paths start to blend into one another. The higher the spacing, the sooner blending begins as the shapes approach each other." Applying Liquid Glass to custom views: "The larger the spacing value on the container, the sooner the Liquid Glass effects behind views blend together and merge the shapes during a transition. A spacing value on the container that's larger than the spacing of an interior HStack, VStack, or other layout container causes Liquid Glass effects to blend together at rest because the views are too close to each other." So spacing 8 is the least aggressive. Spacing of 40+ merges siblings at rest unless their layout gap is larger, and spacing affects resting shapes, not only transitions. No Apple source gives a 16–24 default.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/glasseffectcontainer (apple-doc, confidence high)
- **Action:** Fix the comments: small spacing merges only when shapes nearly touch; large spacing merges sooner and can merge at rest. For distinct siblings, set container spacing below the layout gap. Delete "Default morph threshold 16–24".

```swift
init(spacing: CGFloat?, content: () -> Content)
```

### 10. `bad-practice` — "If two elements should stay distinct, place them in separate containers."  
_skills/liquid-glass/references/04-motion-and-interaction.md:121_

- **Correct / new info:** WWDC25 323: "glass can not sample other glass, so having nearby glass elements in different containers will result in inconsistent behavior. Using a glass container allows these elements to share their sampling region, providing a consistent visual result." Applying Liquid Glass to custom views: "Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence high)
- **Action:** Replace with: "Keep nearby glass in one container. To keep shapes distinct, give the container a spacing smaller than their layout gap."

### 11. `unverifiable-claim` — "Glass cannot sample other glass. A glass element on top of another glass element produces flat blur — the lensing effect is lost. Use GlassEffectContainer to merge them into one layer." Also 06 L57 ("you get flat blur and an extra pass") and 07 L24 ("Each layer flattens into blur ... you pay for three render passes").  
_skills/liquid-glass/references/02-hig-principles.md:66_

- **Correct / new info:** The first sentence is Apple's (WWDC25 323: "glass can not sample other glass"), but Apple says it about nearby side-by-side elements in different containers, which give "inconsistent behavior". The container fix shares their sampling region. Apple sources never mention "flat blur", "lensing is lost" or render-pass counts. For stacked glass, Apple's fix is not a container but "use fills, transparency, and vibrancy for the top elements" (WWDC25 219). WWDC25 323 also gives the container's main purpose: "This grouping is essential for visual correctness."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence medium)
- **Action:** Quote Apple's sentence in context and cite WWDC25 323. For stacking, point to fills and vibrancy. Drop the "flat blur" and render-pass claims. Add "visual correctness" to the reasons for GlassEffectContainer in SKILL L63 and L86.

### 12. `unverifiable-claim` — "1 container of 5 children is ~5× cheaper than 5 standalone glass views". Related numbers presented as fact: L17 ("Cheap on A17 / M-series; noticeable on A13"), L21 (container "≈ cost of one glass effect"), L60 ("1–3 ms/frame on A13–A14"), L88 ("240 glass passes/sec"), L109-114 (.interactive() "installs a DragGesture recognizer, per-frame transform, specular-highlight tracker"), L171-174, 04 L203-205, 07 L173 ("sub-30fps"), 07 L222/L226, checklist L63 (">20 cells") and L66 (">8 elements").  
_skills/liquid-glass/references/06-performance.md:25_

- **Correct / new info:** Apple publishes only qualitative performance guidance. GlassEffectContainer: "SwiftUI renders the effects together, improving rendering performance". Applying Liquid Glass to custom views: "Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance. Limit the use of Liquid Glass effects onscreen at the same time." Adopting Liquid Glass: "Performance test your app across platforms ... Profile your app". Apple gives no multipliers, millisecond budgets, device tiers, fps outcomes, count thresholds or internals of interactive().
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence high)
- **Action:** Remove these numbers or label them as unmeasured rules of thumb. Replace with Apple's qualitative rules plus "profile on your oldest supported device".

### 13. `unverifiable-claim` — "Instruments → Metal System Trace (Xcode 26) shows glass passes as labeled phases. Look for: 'GlassEffect: layout' ... 'GlassEffect: composite'". Checklist L62: "Metal System Trace shows one composite phase per GlassEffectContainer per frame". L153: "The Animation Hitch template".  
_skills/liquid-glass/references/06-performance.md:147_

- **Correct / new info:** I found no Apple documentation, release note or WWDC session describing Liquid Glass–labelled phases in Metal System Trace. These labels look invented. The real Instruments template is "Animation Hitches" (Apple Tech Talks 10856/10857). Apple's SwiftUI profiling guidance is in WWDC25 306 "Optimize SwiftUI performance with Instruments" and WWDC26 268 "Profile, fix, and verify: Improve app responsiveness with Instruments".
- **Evidence:** https://developer.apple.com/videos/play/tech-talks/10856/ (apple-video, confidence medium)
- **Action:** Delete the phase labels and checklist L62. Recommend the Animation Hitches template and the SwiftUI and Hangs/Hitches instruments to find hitches during glass morphs and scrolling.

### 14. `design-guidance` — "Photographic / video | Best showcase for .clear glass", with no dimming requirement. Also 06 L61 ("Use .clear variant (lighter)" for performance), 06 L186 and checklist L64 ("No glass during video playback unless .clear variant"), and 05 L73-74 (a 15% plusDarker scrim; switching to .regular is the "last resort").  
_skills/liquid-glass/references/03-design-tokens.md:93_

- **Correct / new info:** Glass.clear doc: "When using clear glass, ensure content remains legible by adding a dimming layer or other treatment beneath the glass." HIG Materials: "Only use clear Liquid Glass for components that appear over visually rich backgrounds", and "If the underlying content is bright, consider adding a dark dimming layer of 35% opacity ... If ... you use standard media playback controls from AVKit that provide their own dimming layer, you don't need to apply a dimming layer." WWDC25 219: "Regular is the most versatile and the one you will be using the most". Use Clear only when all three hold: "over media-rich content", "your content layer won't be negatively affected by introducing a dimming layer", and "the content sitting above it is bold and bright"; the two variants "should never be mixed". No Apple source says .clear is cheaper.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass/clear (apple-doc, confidence high)
- **Action:** Make .regular the default and .clear the exception, with the three conditions and a dimming layer (about 35% black over bright content). Remove the performance rationale for .clear and the "no glass over video unless .clear" rule. Reorder the 05 L70-74 fixes.

```swift
static var clear: Glass { get }
```

### 15. `factually-wrong` — The concentricity example: an inner `.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))` inside a card drawn with `.background(RoundedRectangle(cornerRadius: 28))` (L78) is said to compute curves "concentric with the outer container". The same pattern appears at 07 L150-158, SKILL L87 and 03 L18.  
_skills/liquid-glass/references/02-hig-principles.md:82_

- **Correct / new info:** ConcentricRectangle docs: "A containing shape could be a view that extends to the device's rounded corners, or any view that sets containerShape(_:)." and "To allow ConcentricRectangle to resolve corner radii based on concentricity in your custom view, use containerShape(_:) to specify a container shape". A .background shape does not declare a container shape, so the inner corners resolve against the sheet, window or device, not the 28 pt card. The docs also warn: "the corner radius the system calculates may be zero ... use concentric(minimum:)". The API spelling is a separate problem: WWDC25 323 shows `.rect(corner: .containerConcentric)`, and Adopting Liquid Glass lists `Shape.rect(corners:isUniform:)` and `ConcentricRectangle`. `.rect(cornerRadius: .containerConcentric)` matches neither, so the symbol audit should confirm.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/concentricrectangle (apple-doc, confidence high)
- **Action:** Add .containerShape(.rect(cornerRadius: 28)) to the outer card in both examples. Use a concentric corner style with a minimum radius. Fix the API spelling per the symbol audit.

```swift
struct ConcentricRectangle
```

### 16. `nonexistent-api` — Anti-pattern #5 "Right" fix: `view.glassEffect(.regular, isEnabled: visible)`. Also 02 L133 and L166 ("use .glassEffect(... isEnabled: false)" / "animate isEnabled"), 06 L63 ("isEnabled: false") and 06 L162 (`.glassEffect(.regular, isEnabled: !isIdle)`).  
_skills/liquid-glass/references/07-anti-patterns.md:127_

- **Correct / new info:** The documented modifier has a single overload with no isEnabled parameter. The documented way to add or remove glass with a system transition is to insert or remove the view inside a GlassEffectContainer under withAnimation, using glassEffectTransition(.materialize) or .matchedGeometry. "The system applies more than opacity changes with the available transition types." Glass.identity ("content remains unaffected as if no glass effect was applied") is another option, but whether switching to it animates is undocumented.
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Replace every isEnabled-based fix with conditional insertion plus glassEffectTransition inside a container, or with .identity. Coordinate with the 01-api-reference symbol audit.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 17. `inconsistency` — The recipe library uses opacity transitions on glass views: L234 "Pop in" `.transition(.scale.combined(with: .opacity))` and L240 `.move(edge: .bottom).combined(with: .opacity)`. Examples 04, 06 and 09 do the same.  
_skills/liquid-glass/references/04-motion-and-interaction.md:234_

- **Correct / new info:** This contradicts 02 L133 and 07 #5 ("Don't animate opacity on glass elements") and Apple. WWDC25 219: "Instead of fading, Liquid Glass objects materialize in and out by gradually modulating the light bending and lensing". Applying Liquid Glass to custom views: "To provide people with a consistent experience, use matchedGeometry and materialize transitions across your apps."
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence high)
- **Action:** For glass views, use glassEffectTransition(.materialize) or .matchedGeometry inside a GlassEffectContainer. Keep opacity transitions for non-glass content only, and align the examples.

### 18. `bad-practice` — "Static glass is a code smell — if a glass element never moves, refracts, or morphs, you're probably using glass where a solid surface would do."  
_skills/liquid-glass/references/04-motion-and-interaction.md:3_

- **Correct / new info:** Apple wants glass to be quiet at rest. WWDC25 219: "This lets the resting state stay visually quiet, while it comes to life on touch." Most system glass, such as toolbars and tab bars, never morphs. Apple decides where glass goes by layer, not motion. HIG Materials: Liquid Glass "forms a distinct functional layer for controls and navigation elements ... that floats above the content layer".
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence high)
- **Action:** Remove the sentence. Use the layer test instead: controls or navigation floating above content get glass; content does not.

### 19. `unverifiable-claim` — "Specular highlights | Device gyroscope | Automatic — no code". Also SKILL L97 ("picks up specular highlights from device motion") and 02 L39 ("Reacts to device motion (gyroscope-driven)").  
_skills/liquid-glass/references/04-motion-and-interaction.md:11_

- **Correct / new info:** WWDC25 219: "Light sources inside of this environment shine on the material producing highlights that respond to geometry ... On interactions, such as locking and unlocking your phone, these lights move in space" and "in some cases, the lighting responds to device motion". Apple does not say app glass highlights are gyroscope-driven in general, nor that Reduce Motion turns off "specular tracking". For iOS 27, the WWDC26 State of the Union says "we also introduced a darkened edge along with brighter specular highlights."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence medium)
- **Action:** Reword: highlights respond to geometry and interaction, and in some system contexts to device motion. This is system behavior, not an app-controllable mode.

### 20. `factually-wrong` — "Adaptive shadows | Soft shadow underneath, tinted by the content behind"  
_skills/liquid-glass/references/02-hig-principles.md:40_

- **Correct / new info:** Shadows adapt in opacity, not tint. WWDC25 219: "The element is aware of what's behind it and increases the opacity of its shadow when it is over text. Conversely, it lowers the opacity of its shadow when it is over a solid light background."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence medium)
- **Action:** Change to "shadow opacity adapts to what's behind (stronger over text, lighter over solid light backgrounds)".

### 21. `unverifiable-claim` — "Glass over a flat color = blob." Also 02 L67 ("looks like a gray blob"), 03 L96 ("Solid bright color ❌ avoid — kills lensing") and 07 L66/L71 ("just flat color again").  
_skills/liquid-glass/SKILL.md:91_

- **Correct / new info:** WWDC25 219 says the regular variant "works in any size, over any content and anything can be placed on top of it". Its shadows also adapt over solid light backgrounds. The real reasons not to glass a background are layering (HIG: "Don't use Liquid Glass in the content layer") and legibility. Testing over busy content is still right. HIG Color: "make sure its default or resting state ... maintains clear legibility."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence medium)
- **Action:** Keep "test over real, busy, bright content". Drop the "blob" and "kills lensing" claims and give the layering reason instead.

### 22. `factually-wrong` — "Apple's Human Interface Guidelines for iOS 26 are organized around three pillars: Hierarchy, Harmony, and Consistency", with quoted text at L10 ("Establish a clear visual hierarchy where controls and interface elements elevate and distinguish the content beneath them."), L17 (Harmony, formatted as a quote) and L24 ("Adopt platform conventions so the design adapts across window sizes and displays.").  
_skills/liquid-glass/references/02-hig-principles.md:3_

- **Correct / new info:** The trio comes from Apple's Liquid Glass technology overview ("create beautiful interfaces that establish hierarchy, create harmony, and maintain consistency across devices and platforms"). It is not how the HIG is organized. On June 8, 2026 the HIG "Reintroduced design principles" with eight principles: Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft and Delight (WWDC26 session 250 "Principles of great design"). I could not find the L10 and L24 sentences on any current Apple page I checked: the overview, Adopting Liquid Glass, the HIG landing page, Design principles, and developer.apple.com/design. L17 is a paraphrase formatted as a quote.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/design-principles (apple-other, confidence high)
- **Action:** Reframe as "Apple's stated Liquid Glass goals" and quote the overview sentence. Remove or source the L10, L17 and L24 quotes. Mention the June 2026 HIG design principles.

### 23. `unverifiable-claim` — Presented as a quotation: "Glass exists to make content shine, not to be the show."  
_skills/liquid-glass/references/02-hig-principles.md:121_

- **Correct / new info:** Not found in any Apple source or in web search. Apple's own wording: HIG Materials, "Liquid Glass seeks to bring attention to the underlying content, and overusing this material in multiple custom controls can provide a subpar user experience by distracting from that content." Liquid Glass overview: "Be judicious with your use of color in controls and navigation so they stay legible and allow your content to infuse them and shine through."
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence medium)
- **Action:** Replace with the real HIG sentence, or remove the quotation marks so it reads as the skill's own summary.

### 24. `factually-wrong` — "WWDC25 Session 284 — Get to know the new design system"  
_skills/liquid-glass/references/02-hig-principles.md:174_

- **Correct / new info:** "Get to know the new design system" is WWDC25 session 356. Session 284 is "Build a UIKit app with the new design". The source of "glass can not sample other glass" is session 323, "Build a SwiftUI app with the new design", which the skill does not cite. The createwithswift.com link (L173) is a secondary source.
- **Evidence:** https://developer.apple.com/documentation/technologyoverviews/liquid-glass (apple-doc, confidence high)
- **Action:** Fix the number to 356. Add 323 plus HIG Color, Branding and Toolbars. Label createwithswift as a secondary source.

### 25. `bad-practice` — "A useful test: Can the user grab and move this surface? If yes (chrome), it can be glass. If no (content), it cannot."  
_skills/liquid-glass/references/02-hig-principles.md:59_

- **Correct / new info:** Nav bars, tab bars and toolbars can't be grabbed or moved, yet they are Apple's canonical glass, so this test gives the wrong answer for them. Apple's test is the functional layer. HIG Materials: "Liquid Glass forms a distinct functional layer for controls and navigation elements — like tab bars and sidebars — that floats above the content layer". It makes an exception for content-layer controls "with a transient interactive element like sliders and toggles".
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence medium)
- **Action:** Replace with: "Is this a control or navigation element floating above content? Then glass. Otherwise, content-layer styling."

### 26. `bad-practice` — "VoiceOver sweep → every glass control has a label & hint". Checklist L57: "every interactive glass element has label + hint".  
_skills/liquid-glass/references/05-accessibility.md:187_

- **Correct / new info:** Apple's Accessibility Programming Guide for iOS: "You should provide a hint only when the results of an action are not obvious from the element's label." and "few controls and views need hints". The HIG VoiceOver page requires labels ("Provide alternative labels for all key interface elements") and does not require hints.
- **Evidence:** https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/Making_Application_Accessible/Making_Application_Accessible.html (apple-doc, confidence medium)
- **Action:** Change to: "every control has a meaningful label; add a hint only when the result isn't obvious from the label".

### 27. `other` — "iOS 26 ships SF Symbols 7 with motion-aware variants" (also L115 and 04 L127). L128: "Prefer .hierarchical rendering on glass — it preserves depth cues that pair with the lensing."  
_skills/liquid-glass/references/03-design-tokens.md:117_

- **Correct / new info:** This is outdated for iOS 27. SF Symbols 7 is the iOS 26-era release; Apple released "SF Symbols 8 beta" on June 8, 2026 with the 27 releases (HIG What's new). "Motion-aware variants" is not Apple terminology. No Apple guidance prefers .hierarchical on glass. HIG Color: on toolbars and tab bars "symbols and text on these elements follow a monochromatic color scheme". HIG Toolbars: system symbols "automatically receive appropriate coloring and vibrancy".
- **Evidence:** https://developer.apple.com/design/whats-new/ (apple-other, confidence medium)
- **Action:** Write "SF Symbols 7 (iOS 26) / SF Symbols 8 (iOS 27)". Drop "motion-aware variants". Recommend the default monochrome rendering for symbols on glass chrome, and keep .hierarchical as an option, not a rule.

### 28. `unverifiable-claim` — "These aren't hardcoded by Apple — they're the values their first-party apps converge on." This covers the radii (L11-16), padding (L37-41), spacing (L29-32) and font roles (L77-81).  
_skills/liquid-glass/references/03-design-tokens.md:3_

- **Correct / new info:** No Apple source publishes these tokens, and the "first-party apps converge on" claim has no measurement behind it. Apple's own guidance is shape types plus a few spacing numbers. WWDC25 356: "fixed shapes have a constant corner radius ... Capsules use a radius that's half the height of the container ... concentric shapes calculate their radius by subtracting padding from the parent's". HIG Accessibility: "about 12 points of padding around elements that include a bezel ... about 24 points ... without a bezel".
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/356/ (apple-video, confidence medium)
- **Action:** Label the tables "suggested starting values (not Apple-specified)" and cite Apple's shape-type and padding guidance.

### 29. `unverifiable-claim` — "iOS 26 system fonts have been retuned for better legibility over glass."  
_skills/liquid-glass/references/03-design-tokens.md:73_

- **Correct / new info:** WWDC25 356 says something different: "Typography has been refined to strengthen clarity and structure, now bolder and left-aligned to improve readability in key moments like alerts and onboarding." HIG What's new (Dec 16, 2025): Typography "Added emphasized weights to the Dynamic Type style specifications". Nothing about retuning for glass.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/356/ (apple-video, confidence medium)
- **Action:** Replace with Apple's statement, or delete.

### 30. `unverifiable-claim` — "withAnimation(.bouncy) // default for glass morphing". Also L102 ("the system has been tuned for glass"), L111 and 04 L94 (".linear ❌ never for glass"), 07 #13, and checklist L45-46 as hard rules.  
_skills/liquid-glass/references/03-design-tokens.md:105_

- **Correct / new info:** Apple's glass morph examples use plain withAnimation { } with the default animation. The docs say only that glassEffectID and glassEffectTransition "only affect their content during view hierarchy transitions or animations". No Apple guidance makes .bouncy the default for glass or forbids .linear. For Reduce Motion, the HIG advises "Tightening animation springs to reduce bounce effects".
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence medium)
- **Action:** Present the animation curves as a stylistic preference. Remove "default" and "never", and drop the checklist L45 hard rule.

### 31. `bad-practice` — "Press feedback (manual, for non-Button glass)": adds a DragGesture(minimumDistance: 0) and scaleEffect(0.96) to a view that already has .glassEffect(.regular.interactive()).  
_skills/liquid-glass/references/04-motion-and-interaction.md:255_

- **Correct / new info:** interactive() already supplies press feedback. Article: it "applies the same responsive and fluid reactions that PrimitiveButtonStyle/glass provides to standard buttons". WWDC25 323: "Glass reacts to user interaction by scaling, bouncing, and shimmering". The recipe scales twice, and a zero-distance drag gesture can interfere with taps and scrolling.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence medium)
- **Action:** Delete the recipe or drop .interactive() from it. Use .interactive() alone, or a Button with .buttonStyle(.glass).

### 32. `platform-requirement` — The Devices section tests iPhone 11, iPad Pro 13", Light/Dark and iPhone landscape. 03-design-tokens L132-141 assumes the nav bar is at the top and the tab bar at the bottom.  
_skills/liquid-glass/checklists/pre-ship-checklist.md:68_

- **Correct / new info:** New device class (Sept 2026), from HIG Designing for iPhone Duo: "On iPhone Duo, toolbars, tab bars, and navigation controls that are typically at the top and bottom of the display move to the side", "Use the ReservedRegion API to keep important elements clear of the center if the system doesn't move them automatically", and "You can use Device Hub in Xcode to preview your app on iPhone Duo and test how your app appears in its various poses." SwiftUI Sept 2026 adds the toolbarVerticalEdge environment value, toolbarVerticalBehavior(_:) and ReservedRegion. Custom floating glass (FABs, accessories) must account for side bars and reserved regions. iPhone 11 is still the oldest supported iPhone on iOS 27 (secondary source: AppleInsider, June 8, 2026), so that item stays valid.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo (apple-other, confidence high)
- **Action:** Add an item: "iPhone Duo (Device Hub): outer and inner displays, folded poses; custom floating glass avoids side bars (toolbarVerticalEdge) and reserved regions". Note side bars in the 03 Z-stack section.

### 33. `behavior-change` — The Build section requires only a 26.0 deployment target and Xcode 26+. It says nothing about the compatibility-mode opt-out or the 27 SDK.  
_skills/liquid-glass/checklists/pre-ship-checklist.md:81_

- **Correct / new info:** UIDesignRequiresCompatibility doc: "Temporarily use this key while reviewing and refining your app's UI for the design in the latest SDKs." and "The system ignores this key when you build for iOS 27 or later, iPadOS 27 or later, Mac Catalyst 27 or later, macOS 27 or later, or tvOS 27 or later." WWDC26 State of the Union: "We'll be removing support for opting to use the old design. So once your app is recompiled with Xcode 27, it will automatically begin to use the new design with Liquid Glass." Separately, App Store uploads must be built "with Xcode 26 or later using an SDK for iOS 26" since April 28, 2026. That is an SDK requirement, not a deployment-target requirement.
- **Availability:** iOS 26.0, iPadOS 26.0, macOS 26.0, tvOS 26.0; ignored when building for iOS/iPadOS/Mac Catalyst/macOS/tvOS 27 or later
- **Evidence:** https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility (apple-doc, confidence high)
- **Action:** Add: "Remove UIDesignRequiresCompatibility (ignored for 27 SDK builds)" and "Build with Xcode 27 for the 27 releases; also check Xcode 26 builds running on iOS 27, where the material updates apply without recompiling".

```swift
UIDesignRequiresCompatibility (Info.plist key, Boolean)
```

### 34. `skill-authoring` — The skill activates when "Editing a .swift file in a project with IPHONEOS_DEPLOYMENT_TARGET >= 26.0". The scope at L12 is "iOS 26+ only". Checklist L85: "No @available(iOS 26.0, *) left over".  
_skills/liquid-glass/SKILL.md:20_

- **Correct / new info:** Liquid Glass follows the SDK, not the deployment target. Adopting Liquid Glass: "Start by building your app in the latest version of Xcode to see the changes", and standard components "pick up the appearance and behavior of this material automatically". App Store uploads have required the iOS 26 SDK since April 28, 2026, and with Xcode 27 the opt-out is gone (WWDC26 State of the Union). Most apps that render Liquid Glass therefore have deployment targets below 26 and gate glass APIs with availability checks. This trigger misses them, and the skill offers them no guidance.
- **Evidence:** https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass (apple-doc, confidence medium)
- **Action:** Trigger on Xcode 26+/27 SDK projects or Liquid Glass API usage, not on deployment target. Add a short section for targets below 26: `if #available(iOS 26, *)` glass, with a Material fallback below 26.

### 35. `wrong-availability` — platforms: [..., visionOS 26+]. The description at L3 also lists "visionOS 26" as a trigger for .glassEffect / GlassEffectContainer work.  
_skills/liquid-glass/SKILL.md:5_

- **Correct / new info:** Glass, Glass.clear, Glass.identity, View.glassEffect(_:in:) and GlassEffectContainer all list iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0 and watchOS 26.0, with no visionOS entry. Adopting Liquid Glass also notes that on tvOS "Apple TV 4K (2nd generation) and newer models support Liquid Glass effects. On older devices, your app maintains its current appearance."
- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 (visionOS not listed)
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass (apple-doc, confidence high)
- **Action:** Remove visionOS from platforms and the description, or say explicitly that these APIs aren't available there. Add the tvOS hardware caveat.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 36. `behavior-change` — The skill is framed around "iOS 26 / Xcode 26 (WWDC25)" only. The title (L8) and triggers (L3, L21) mention only iOS 26 / macOS Tahoe 26.  
_skills/liquid-glass/SKILL.md:10_

- **Correct / new info:** WWDC26 Platforms State of the Union: "In this year's releases, you'll see updates to the foundations of how Liquid Glass is built ...", "we tuned Liquid Glass so it more effectively diffuses complex content behind it", "we also introduced a darkened edge along with brighter specular highlights", and "Apps already using Liquid Glass get these improvements automatically when they run on this year's releases without even needing to recompile." The SwiftUI June and Sept 2026 updates add no new glassEffect, Glass or GlassEffectContainer APIs. The new APIs are toolbar ones (visibilityPriority(_:), ToolbarOverflowMenu, topBarPinnedTrailing, toolbarMinimizationBehavior(_:for:)), TabRole.prominent, NavigationTransition.crossFade and the iPhone Duo vertical-axis toolbar APIs.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/102/ (apple-video, confidence high)
- **Action:** Retitle and re-describe as "iOS 26+ (incl. iOS/iPadOS/macOS 27)" and add 27 triggers. Add a short "What changed in 27" note and recommend checking glass screens on both 26 and 27.

### 37. `behavior-change` — "Don't insert custom glass between layers 1 and 2; let the system own that band." None of the audited files mention scroll edge effects.  
_skills/liquid-glass/references/03-design-tokens.md:141_

- **Correct / new info:** HIG Scroll views (updated June 8, 2026): "Prefer the automatic scroll edge effect style ... If you use the soft scroll edge effect style instead, thoroughly test your interface" and "Scroll edge effects aren't decorative." WWDC26 278: "the .automatic style no longer switches between the existing soft and hard styles but provides its own visuals for additional clarity. If you have overridden the style from .automatic previously, that decision should be re-evaluated, especially when set to .soft". WWDC26 State of the Union: "When content scrolls under floating bars, a uniform toolbar appears across the top ... applied automatically for standard toolbars and can be customized using the existing scroll edge effect APIs."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/278/ (apple-video, confidence medium)
- **Action:** Add a rule: rely on the automatic scroll edge effect for legibility under bars, add no custom scrims or backgrounds there, and re-check any .soft overrides on iOS 27.

### 38. `unverifiable-claim` — "Each item is a 30-second check; collectively they catch ~95% of glass-related ship issues."  
_skills/liquid-glass/checklists/pre-ship-checklist.md:3_

- **Correct / new info:** No data or source supports the 95% figure.
- **Evidence:**  (reasoning, confidence high)
- **Action:** Remove the statistic.

### 39. `other` — Contrast table: "Body text (< 18pt regular, < 14pt bold) 4.5:1; Large text (≥ 18pt regular, ≥ 14pt bold) 3:1". 02 L142 repeats it.  
_skills/liquid-glass/references/05-accessibility.md:61_

- **Correct / new info:** Apple's table, which Accessibility Inspector uses as WCAG AA guidance, is in iOS points and treats all bold text as 3:1: "Up to 17 pts | All | 4.5:1"; "18 pts | All | 3:1"; "All | Bold | 3:1". The HIG adds: "If your app doesn't provide this minimum contrast by default, ensure it at least provides a higher contrast color scheme when the system setting Increase Contrast is turned on."
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/accessibility (apple-other, confidence medium)
- **Action:** Use Apple's table with point sizes. Keep the 3:1 rule for non-text UI.

### 40. `unverifiable-claim` — "Color blind simulators (Xcode → Color Vision Tests)". Checklist L56: "Color Vision tests (Xcode)".  
_skills/liquid-glass/references/05-accessibility.md:189_

- **Correct / new info:** No Apple documentation describes an Xcode "Color Vision Tests" feature. Secondary sources point to Settings > Accessibility > Display & Text Size > Color Filters on a device or Simulator. HIG Color's rule still stands: "Avoid relying solely on color to differentiate between objects ... provide the same information in alternative ways".
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/color (apple-other, confidence low)
- **Action:** Replace with Color Filters plus a grayscale check, or drop the menu path.

### 41. `design-guidance` — "only tint glass for truly destructive primary actions". Destructive actions are styled .glassProminent at 05 L91-95 and 07 L335-341. 05 L98 says role .destructive gives "tint and shape cues across accessibility modes".  
_skills/liquid-glass/references/03-design-tokens.md:66_

- **Correct / new info:** HIG Buttons: "Don't assign the primary role to a button that performs a destructive action, even if that action is the most likely choice. Because of its visual prominence, people sometimes choose a primary button without reading it first." and "a destructive button uses the system red color." Apple documents no "shape cues" from the destructive role.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/buttons (apple-other, confidence low)
- **Action:** Prefer role: .destructive with a non-prominent style, or a confirmation step, over making the destructive action the prominent primary. Remove the "shape cues" claim.

### 42. `unverifiable-claim` — "Full-screen examples that compile in Xcode 26"  
_skills/liquid-glass/SKILL.md:37_

- **Correct / new info:** This can't be checked here (no Swift toolchain). The skill's own reference snippets use glassEffect(..., isEnabled:), which the documented API does not have, so compile claims need CI evidence.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (reasoning, confidence low)
- **Action:** Back the claim with an xcodebuild CI job against the Xcode 26 and 27 SDKs, or soften it to "written for Xcode 26".

## Symbols (8)

### `Glass`

```swift
struct Glass
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 (visionOS not listed)
- **Members:** interactive(_:), tint(_:), clear, identity, regular
- **Doc:** https://developer.apple.com/documentation/swiftui/glass
- **Skill uses it correctly:** NO
- **Notes:** identity is documented as "your content remains unaffected as if no glass effect was applied", so the skill's Reduce Transparency opt-out (SKILL L90, 05 L37) removes the backing. The skill lists visionOS, but Glass is not available there. No opacity member exists, so 07 L93 `.regular.tint(.purple).opacity(0.9)` is suspect.

### `View.glassEffect(_:in:)`

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 (visionOS not listed)
- **Members:** glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Skill uses it correctly:** NO
- **Notes:** Only one overload is documented, with no isEnabled parameter. The skill's isEnabled-based fixes (02 L133/L166, 06 L63/L162, 07 L127) don't match it. Defaults to the regular variant and a Capsule shape.

### `GlassEffectContainer`

```swift
@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 (visionOS not listed)
- **Members:** init(spacing: CGFloat?, content: () -> Content)
- **Doc:** https://developer.apple.com/documentation/swiftui/glasseffectcontainer
- **Skill uses it correctly:** NO
- **Notes:** Doc: "The higher the spacing, the sooner blending begins as the shapes approach each other." The skill has this backwards at 04 L116 and 03 L32. "SwiftUI renders the effects together, improving rendering performance" is qualitative only; the skill's 5× and ≈1-pass claims are unsourced.

### `Glass.clear`

```swift
static var clear: Glass { get }
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Doc:** https://developer.apple.com/documentation/swiftui/glass/clear
- **Skill uses it correctly:** NO
- **Notes:** Doc requires "adding a dimming layer or other treatment beneath the glass"; the skill never mentions one. HIG Materials: 35% dark dimming over bright content. Nothing says clear is cheaper, unlike 06 L61.

### `Glass.identity`

```swift
static var identity: Glass { get }
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0
- **Doc:** https://developer.apple.com/documentation/swiftui/glass/identity
- **Skill uses it correctly:** NO
- **Notes:** "When applied, your content remains unaffected as if no glass effect was applied." The page has no discussion section and does not document whether switching to or from identity animates.

### `ConcentricRectangle`

```swift
struct ConcentricRectangle
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** init(), init(corners:isUniform:), init(topLeadingCorner:topTrailingCorner:bottomLeadingCorner:bottomTrailingCorner:), init(uniformTopCorners:uniformBottomCorners:), init(uniformTopCorners:bottomLeadingCorner:bottomTrailingCorner:), init(uniformBottomCorners:topLeadingCorner:topTrailingCorner:), init(uniformLeadingCorners:uniformTrailingCorners:), init(uniformLeadingCorners:topTrailingCorner:bottomTrailingCorner:), init(uniformTrailingCorners:topLeadingCorner:bottomLeadingCorner:)
- **Doc:** https://developer.apple.com/documentation/swiftui/concentricrectangle
- **Skill uses it correctly:** NO
- **Notes:** Corners resolve against the device corners or any view that sets containerShape(_:). The skill's examples draw the outer card only as a .background, so they are not concentric with it. Use Edge.Corner.Style.concentric(minimum:) to avoid zero radii. WWDC25 323 spells it `.rect(corner: .containerConcentric)`, and Adopting Liquid Glass lists `Shape.rect(corners:isUniform:)`. The skill's `.rect(cornerRadius: .containerConcentric)` matches neither and needs a symbol check.

### `View.accessibilityIgnoresInvertColors(_:)`

```swift
nonisolated func accessibilityIgnoresInvertColors(_ active: Bool = true) -> some View
```

- **Availability:** iOS 14.0, iPadOS 14.0, Mac Catalyst 14.0, macOS 11.0, tvOS 14.0, visionOS 1.0, watchOS 7.0
- **Members:** active: Bool = true
- **Doc:** https://developer.apple.com/documentation/swiftui/view/accessibilityignoresinvertcolors(_:)
- **Skill uses it correctly:** NO
- **Notes:** The skill never uses it and wrongly claims system colors are exempt from Smart Invert (05 L175). This modifier is the documented opt-out.

### `UIDesignRequiresCompatibility`

```swift
UIDesignRequiresCompatibility (Information Property List key, Boolean)
```

- **Availability:** iOS 26.0, iPadOS 26.0, macOS 26.0, tvOS 26.0
- **Doc:** https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility
- **Skill uses it correctly:** NO
- **Notes:** Not mentioned in the skill. iOS 27 change: "The system ignores this key when you build for iOS 27 or later, iPadOS 27 or later, Mac Catalyst 27 or later, macOS 27 or later, or tvOS 27 or later." WWDC26 State of the Union says the opt-out is removed with Xcode 27.

