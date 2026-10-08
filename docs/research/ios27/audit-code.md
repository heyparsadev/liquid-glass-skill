# audit-code

_Phase: Audit_

## Summary

Read-only audit of the Swift in patterns/*.md, the nine examples/*.swift, and Gallery (project.yml, Sources/GalleryApp.swift). Checked against Apple DocC JSON (about 45 symbol pages, TN3211, TN3208, Xcode 27 and iOS 26.1/26.2/26.4/27 release notes), the WWDC25-323 and WWDC26-269 transcripts, HIG Materials and Sign in with Apple, and Adopting/Applying Liquid Glass. No compiler was available; compile claims rest on the verified declarations.

BUILD UNDER XCODE 27 (Swift 6.4): the nine examples and GalleryApp should still compile. No example hits a TN3211 break:
- no @State is assigned in an init, and none is composed with another wrapper;
- no extension calls a synthesized private memberwise init;
- no TupleView is spelled out, and MapKit and Charts are not used.
Also clean: no ternary mixes ButtonStyle types, no View or ToolbarContent modifier sits in the wrong builder, no legacy Material, no manual glass on toolbar items, and no 26.1+ or 27-only symbol is used at the 26.0 target.
The PATTERN snippets are not all compilable:
- DefaultToolbarItem is nested inside ToolbarItem (glass-search-field.md:59; same in 01-api-reference.md:421).
- `chipStyle()` is undefined and `.containerConcentric` does not exist (glass-card-stack.md).
- 01-api-reference.md:349 puts `sharedBackgroundVisibility` on a Button.

DEPRECATIONS (DocC deprecatedAt 27.2, renamed or replaced; they warn once the deployment target reaches 27.2):
- ScrollView(_:showsIndicators:) at 05:47, 09:240 and 09:271.
- Non-builder overlay(_:alignment:) and background(_:alignment:) at 08:274, 08:314, 09:185 and 09:311.
- In the patterns, toolbarBackground(.hidden, for:) should become toolbarBackgroundVisibility, and toolbar(.hidden, for:) should become toolbarVisibility.
navigationBarTitleDisplayMode, ScrollViewReader and confirmationDialog are not deprecated.

RUNTIME BUGS:
- Random values computed in body make 04's backdrop jump on every tap and 02's Canvas grain re-roll.
- 03's Skip button changes state without withAnimation, so the glass dots hard-cut.
- 09's hand-rolled 'See all' glass pill is mostly outside its Button's hit area.

THE EXAMPLES BREAK THE SKILL'S OWN RULES, mostly in 09 HealthToday:
- Glass on content cards (activity hero, plan card, metric chips), layered over hand-drawn white translucent fills.
- Glass inside glass: stat chips in the hero, a badge in the plan card, glass buttons inside the system bottom accessory.
- Adjacent glass without a GlassEffectContainer: 08 text fields, 09 workout-card chips, 09 hero chips.
- Decorative and white tints, including a yellow label on light glass in 05.
- No Reduce Transparency or Reduce Motion handling anywhere, and unlabeled icon-only buttons.
- Opacity transitions on glass (the skill's anti-pattern #5).
- `.controlSize(.extraLarge)`, which resolves to `.large` on iOS.
- A false comment in 07 saying `.white` and `.primary` can't share a ternary.
Other problems:
- 08 uses an Apple-logo glass button titled 'Apple', which the HIG forbids.
- 01's confirmationDialog isn't attached to its button, so it can't morph out of it.
- 05 stacks a custom glass bar on top of the bottom-toolbar search.
- The Gallery builds in Swift 5 mode, while the API reference claims Swift 6.1+.

iOS 27 OPPORTUNITIES (all symbols verified):
- 09: toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar). The WWDC26 spelling toolbarMinimizeBehavior returns 404.
- 07: `.pickerStyle(.tabs)` for the tab switcher.
- Tab-bar pattern: TabRole.prominent (a .search tab may get prominent treatment by default) and tabViewBottomAccessory(isEnabled:) from 26.1.
- Sheet pattern: NavigationTransition.crossFade and ToolbarContent.matchedTransitionSource.
- 09 and 07 toolbars: visibilityPriority, topBarPinnedTrailing and ToolbarOverflowMenu.
- 05 and the floating-toolbar pattern: safeAreaBar. Not 06: iOS 26.1 known issue 158720838 ('@FocusState doesn't work in safeAreaBar') has no fix noted through 27.0.

## Findings (46)

### 0. `compile-risk` — Variation 'Search field in the bottom toolbar' nests `DefaultToolbarItem(kind: .search, placement: .bottomBar)` inside `ToolbarItem(placement: .bottomBar) { … }`. references/01-api-reference.md:421-423 has the identical nesting, so pattern and reference agree, and both are wrong.  
_skills/liquid-glass/patterns/glass-search-field.md:59_

- **Correct / new info:** DefaultToolbarItem conforms only to ToolbarContent (DocC 'Conforms To: ToolbarContent'). `ToolbarItem<ID, Content> where Content : View` requires a View in its content closure, so this does not type-check in Xcode 26. It still fails in Xcode 27: ContentBuilder drops the builder's View constraint, but ToolbarItem's generic `Content : View` requirement remains. Apple's samples (DocC and WWDC25-323) place DefaultToolbarItem directly in the `.toolbar { }` builder. There it 'will implicitly replace the default-placed instance', which repositions the system search item relative to the other bottom-bar items.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem/init(kind:placement:) (apple-doc, confidence high)
- **Action:** Replace the snippet with `.toolbar { ToolbarItem(placement: .bottomBar) { FilterPicker() }; ToolbarSpacer(.flexible, placement: .bottomBar); DefaultToolbarItem(kind: .search, placement: .bottomBar) }` followed by `.searchable(text: $query)`. Apply the same fix in 01-api-reference.md §10. Reword line 66 to say it repositions the system search item within the bottom toolbar.

```swift
nonisolated init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)
```

### 1. `compile-risk` — 'Multiple chips on one cover' calls `Text("New").chipStyle()` and `Text("Featured").chipStyle().tint(.orange)`.  
_skills/liquid-glass/patterns/glass-card-stack.md:80_

- **Correct / new info:** `chipStyle()` is not defined in the pattern, anywhere else in the skill, or in SwiftUI, so the snippet fails with "value of type 'Text' has no member 'chipStyle'". Glass color is set through `Glass.tint(_:)`, the mechanism 01-api-reference.md §2 teaches. Applying the `.tint(.orange)` view modifier after a helper that has already applied `.glassEffect()` is not a documented way to tint that glass, so the 'Featured' chip is unlikely to turn orange.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass (apple-doc, confidence high)
- **Action:** Define the helper in the snippet and pass the tint through Glass: `extension View { func chipStyle(_ tint: Color? = nil) -> some View { padding(.horizontal, 10).padding(.vertical, 6).glassEffect(.regular.tint(tint)) } }`. Then call `Text("Featured").chipStyle(.orange)`.

```swift
func tint(Color?) -> Glass
```

### 2. `nonexistent-api` — Gotcha: 'If the chip wraps to two lines, switch to `.rect(cornerRadius: .containerConcentric)`'. 01-api-reference.md §12 (lines 466/475) uses the same spelling.  
_skills/liquid-glass/patterns/glass-card-stack.md:92_

- **Correct / new info:** `Shape.rect(cornerRadius:style:)` takes a CGFloat, and DocC has no member named `containerConcentric`. The iOS 26 concentric API is `Shape.rect(corners:isUniform:)` with `Edge.Corner.Style` (e.g. `.concentric`). Its radius resolves against the container shape, and this card sets only `.clipShape(RoundedRectangle(...))`, which does not provide one.
- **Availability:** rect(cornerRadius:style:): iOS 13.0+; rect(corners:isUniform:): iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/shape/rect(corners:isuniform:) (apple-doc, confidence high)
- **Action:** For a wrapped chip, use `.glassEffect(.regular, in: .rect(cornerRadius: 12))`. For concentric corners, use `.rect(corners: .concentric, isUniform: true)` and give the card a container shape (`.containerShape(RoundedRectangle(cornerRadius: 24, style: .continuous))`). Fix 01-api-reference.md §12 at the same time so the reference and pattern stay consistent.

```swift
@export(implementation) static func rect(cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) -> Self ; @export(implementation) static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self
```

### 3. `compile-risk` — `.sharedBackgroundVisibility(.hidden)` is applied to the Button inside `ToolbarItem { … }`. No pattern or example shows the correct form.  
_skills/liquid-glass/references/01-api-reference.md:349_

- **Correct / new info:** This modifier exists only on ToolbarContent and returns `some ToolbarContent`, so it cannot be called on a View and the snippet does not compile. Apple's DocC and WWDC25-323 samples apply it to the ToolbarItem itself, e.g. `ToolbarItem { ProfileButton() }.sharedBackgroundVisibility(.hidden)`. Per the docs, 'Hiding the effect will cause the item to be placed in its own grouping.'
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:) (apple-doc, confidence high)
- **Action:** Move the modifier after the ToolbarItem's closing brace. Consider adding this as a variation in glass-navigation-bar.md (an avatar item without shared glass) so a correct, copyable example exists.

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
```

### 4. `bad-practice` — The stand-in photo's overlay calls `CGFloat.random(in: 80...240)` for frame width and `CGFloat.random(in: -160...160)` for the x offset (lines 110-119). This runs inside the computed `photo` property, which `body` reads.  
_skills/liquid-glass/examples/04-PhotoDetailScreen.swift:113_

- **Correct / new info:** `body` re-runs whenever `expanded` or `favorited` changes, and both change inside `withAnimation(.bouncy)`. Each re-run produces new random frames and offsets, so the background blobs jump and animate to new positions on every tap of the heart or more button. The photo is supposed to be static content behind the glass.
- **Evidence:**  (reasoning, confidence high)
- **Action:** Make the decoration deterministic: derive values from `i` (e.g. `.frame(width: 80 + CGFloat((i * 37) % 160))`, `.offset(x: CGFloat((i * 53) % 320) - 160, …)`) or precompute them once in a `let` array. Better, use a bundled image asset as the photo.

### 5. `inconsistency` — 'See all' is built as `Button("See all") { }.font(…).padding(.horizontal, 10).padding(.vertical, 6).glassEffect(.regular, in: .capsule)`, a hand-rolled glass pill (lines 232-236).  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:235_

- **Correct / new info:** The padding and glass sit outside the Button, so the tappable area is only the footnote label (roughly 50×16 pt) while the visible pill is larger. That is far below the 44×44 pt minimum in the skill's own 05-accessibility.md. It also contradicts 01-api-reference.md §7 ('don't roll your own with .glassEffect() on a Button'). Apple reserves `interactive(_:)` for custom components because it 'applies the same responsive and fluid reactions that PrimitiveButtonStyle.glass provides to standard buttons'. This pill gets no press feedback at all.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence high)
- **Action:** Replace with `Button("See all") { }.buttonStyle(.glass).controlSize(.small)`, as the 'Filter' button at line 263 already does.

```swift
nonisolated struct GlassButtonStyle
```

### 6. `inconsistency` — The Skip pill runs `step = pages.count - 1` without `withAnimation`.  
_skills/liquid-glass/examples/03-OnboardingFlow.swift:31_

- **Correct / new info:** The glass pagination dots (lines 51-61) use GlassEffectContainer and glassEffectID, and the hero relies on an asymmetric transition. Apple: 'The glassEffectID(_:in:) and glassEffectTransition(_:) modifiers only affect their content during view hierarchy transitions or animations.' So tapping Skip hard-cuts the page and the dot widths. This is the skill's own anti-pattern #10 ('Forgetting withAnimation around morphing state'); Continue (line 66) gets it right.
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence high)
- **Action:** Change to `Button("Skip") { withAnimation(.bouncy) { step = pages.count - 1 } }`.

### 7. `design-guidance` — The `activityHero` content card (activity rings and stats) is a hand-drawn translucent panel: `.fill(.white.opacity(0.08))` plus a 0.5 pt white stroke at lines 183-188, commented 'The glass panel'. `.glassEffect(.regular, in: .rect(cornerRadius: 28))` is applied on top of it. Inside sit three `statChip`s, each with its own `.glassEffect(.regular.tint(…), in: .capsule)` (line 220), and there is no GlassEffectContainer.  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:203_

- **Correct / new info:** This one view breaks four of the skill's own rules:
- Rule 1: glass on a content card.
- Rule 2 and the checklist: `.glassEffect()` inside another `.glassEffect()`.
- Rule 3: two or more adjacent glass elements without a container.
- Anti-pattern #12: a custom translucent fill imitating glass.
Apple guidance agrees:
- HIG Materials: 'Don't use Liquid Glass in the content layer… use standard materials for elements in the content layer'.
- Adopting Liquid Glass: 'avoid overcrowding or layering Liquid Glass elements on top of each other'.
- WWDC25-323: 'glass can not sample other glass… This grouping is essential for visual correctness.'
The hand-made white fill also won't follow the iOS 27 Liquid Glass slider, which system glass 'automatically responds to' (WWDC26-269).
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Make the hero a content card with a solid fill or a standard material (`.background(.regularMaterial, in: .rect(cornerRadius: 28))`, which the HIG endorses for the content layer; this also means golden rule 5, 'never Material', needs rewording). Draw the stat chips as plain tinted capsules (`Capsule().fill(tint.opacity(0.18))`). Remove the hand-drawn fill and stroke. Keep glass for chrome only: the toolbar, period switcher and FAB.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 8. `design-guidance` — `planCard` (a list of plan rows) gets a `.white.opacity(0.06)` RoundedRectangle background (311-314) plus `.glassEffect(.regular, in: .rect(cornerRadius: 24))`. Its '3 / 5' badge carries a second `.glassEffect(.regular.tint(.yellow.opacity(0.25)), in: .capsule)` inside it (line 297).  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:315_

- **Correct / new info:** Same violations as the hero: glass on a content card, glass inside glass, and a custom translucent fill under the glass. The skill's own checklist says 'No glass on List rows, card bodies…' and 'No `.glassEffect()` applied inside another `.glassEffect()`'. HIG Materials: 'Don't use Liquid Glass in the content layer.'
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Render the plan card as content (`.background(.regularMaterial, in: .rect(cornerRadius: 24))` or a solid fill) and the badge as a plain tinted capsule. Delete the `.white.opacity(0.06)` layer.

### 9. `design-guidance` — The form VStack(spacing: 14) stacks two or three text fields. Each applies its own `.glassEffect(.regular, in: .rect(cornerRadius: 18))` (lines 273 and 313), and none is wrapped in a GlassEffectContainer.  
_skills/liquid-glass/examples/08-LoginScreen.swift:60_

- **Correct / new info:** Golden rule 3 and the checklist require a GlassEffectContainer around every cluster of two or more nearby glass elements. WWDC25-323: 'glass can not sample other glass, so having nearby glass elements in different containers will result in inconsistent behavior… This grouping is essential for visual correctness.' The confirm field is also inserted with a `.move`+`.opacity` transition and has no container to morph into. Separately, the HIG allows glass on content-layer controls only for transient interactive states (an active slider or toggle), so glass text fields are a stretch stylistically.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence high)
- **Action:** Wrap the field VStack in `GlassEffectContainer(spacing: 14) { … }` and give the fields glassEffectIDs so the confirm field morphs in. Better, given the HIG, give the fields solid or standard-material backgrounds and keep glass for the CTA and chrome.

```swift
@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View ; init(spacing: CGFloat?, content: () -> Content)
```

### 10. `design-guidance` — Each WorkoutCard carries three glass elements: the duration chip (495), the participants chip (512) and a `.glassProminent` play button (522). They are not wrapped in a GlassEffectContainer, and four cards sit side by side in a horizontal ScrollView.  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:495_

- **Correct / new info:** This breaks rule 3 (nearby glass needs a container) and puts about 12 independent glass effects on screen. Apple: 'Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance. Limit the use of Liquid Glass effects onscreen at the same time.' The skill's card-stack pattern allows glass chips over imagery, but only grouped and sparingly.
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence high)
- **Action:** Wrap the bottom HStack (participants chip and play button) in a GlassEffectContainer. Or keep one glass element per card (the play button) and draw the chips as plain dimmed capsules.

### 11. `design-guidance` — The social cluster offers `socialButton("apple.logo", label: "Apple")`, a `.buttonStyle(.glass)` tile showing the SF Symbol Apple logo over the caption 'Apple'.  
_skills/liquid-glass/examples/08-LoginScreen.swift:388_

- **Correct / new info:** The HIG 'Sign in with Apple' page rules this out:
- 'Use only the logo artwork downloaded from Apple Design Resources; never create a custom Apple logo.'
- 'Use the logo file to position the Apple logo in a button; never use the Apple logo as a button.'
- Titles may only be 'Sign in with Apple', 'Sign up with Apple' or 'Continue with Apple'.
- The logo and title within a button must both be black or both be white.
- 'App Review evaluates all custom Sign in with Apple buttons.'
- The button must be no smaller than the other sign-in buttons.
A glass tile showing the symbol and the word 'Apple' meets none of these, and examples get copied verbatim.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple (apple-other, confidence high)
- **Action:** Use `SignInWithAppleButton(.signIn) { … } onCompletion: { … }` from AuthenticationServices with `.signInWithAppleButtonStyle(.white)` on this dark backdrop, full width above the other options. Keep the glass social tiles only for Google and Email.

### 12. `factually-wrong` — Variation 'Tall sheet that doesn't dim background': `.presentationDetents([.large])`, `.presentationBackground(.clear)  // glass shows full background`, `.presentationBackgroundInteraction(.enabled(upThrough: .medium))`.  
_skills/liquid-glass/patterns/glass-modal-sheet.md:85_

- **Correct / new info:** WWDC25-323: 'On iOS 26, partial height sheets are inset by default with a Liquid Glass background. If you've used the presentationBackground modifier to apply a custom background to your sheets, consider removing that and let the new material shine.' So `.clear` replaces the system glass rather than revealing it. `.enabled(upThrough:)` allows interaction behind the sheet only at or below the given detent. Apple's sample includes that detent in the set (`[.height(120), .medium, .large]` with `.enabled(upThrough: .height(120))`). With only `[.large]` the sheet never sits at `.medium`, so the background stays dimmed and blocked, the opposite of the heading.
- **Availability:** iOS 16.4+, iPadOS 16.4+, Mac Catalyst 16.4+, macOS 13.3+, tvOS 16.4+, visionOS 1.0+, watchOS 9.4+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/presentationbackgroundinteraction(_:) (apple-doc, confidence high)
- **Action:** Delete `.presentationBackground(.clear)`. Use `.presentationDetents([.medium, .large]).presentationBackgroundInteraction(.enabled(upThrough: .medium))` and retitle the variation 'Sheet that keeps the background interactive at medium height'. Add a gotcha: don't set presentationBackground on iOS 26+ sheets.

```swift
nonisolated func presentationBackgroundInteraction(_ interaction: PresentationBackgroundInteraction) -> some View
```

### 13. `deprecated` — `ScrollView(.horizontal, showsIndicators: false)` is used here and at examples/09-HealthTodayScreen.swift:240 and :271.  
_skills/liquid-glass/examples/05-DashboardScreen.swift:47_

- **Correct / new info:** DocC metadata for `init(_:showsIndicators:content:)` has `deprecatedAt: 27.2` on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS, with the message 'Use the ScrollView(_:content:) initializer and the scrollIndicators(:_) modifier'. The `deprecated` flag is still false: expect no warning at the Gallery's 26.0 target, but warnings for projects targeting 27.2 or later. Examples 08 and 09 already use `.scrollIndicators(.hidden)` elsewhere.
- **Availability:** Introduced iOS 13.0; deprecatedAt 27.2 on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS (visionOS not marked)
- **Evidence:** https://developer.apple.com/documentation/swiftui/scrollview/init(_:showsindicators:content:) (apple-doc, confidence high)
- **Action:** Change all three call sites to `ScrollView(.horizontal) { … }.scrollIndicators(.hidden)`.

```swift
nonisolated init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ContentBuilder content: () -> Content)
```

### 14. `deprecated` — The non-builder `.overlay(RoundedRectangle(cornerRadius: 18).stroke(…))` is used here, at 08:314 and at examples/09-HealthTodayScreen.swift:185. The non-builder `.background(RoundedRectangle(…).fill(.white.opacity(0.06)))` is used at 09:311.  
_skills/liquid-glass/examples/08-LoginScreen.swift:274_

- **Correct / new info:** `overlay(_:alignment:)` and `background(_:alignment:)` (the forms that take a View argument) have `deprecatedAt: 27.2` on every platform, with the messages 'Use `overlay(alignment:content:)` instead.' and 'Use `background(alignment:content:)` instead.' TN3211 also names these non-builder forms as where Xcode 27's ContentBuilder produces 'ambiguous use of opacity/blendMode' errors when they are given a ShapeStyle expression. These call sites pass shape views, so they still compile, but the closure forms avoid the problem entirely.
- **Availability:** Introduced iOS 13.0; deprecatedAt 27.2 on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/overlay(_:alignment:) (apple-doc, confidence high)
- **Action:** Rewrite as `.overlay { RoundedRectangle(cornerRadius: 18).stroke(…) }` and `.background { RoundedRectangle(…).fill(…) }`. At 09:311, deleting the custom fill (see the plan-card finding) removes the call entirely.

```swift
nonisolated func overlay<Overlay>(_ overlay: Overlay, alignment: Alignment = .center) -> some View where Overlay : View ; nonisolated func background<Background>(_ background: Background, alignment: Alignment = .center) -> some View where Background : View
```

### 15. `deprecated` — 'For a full-bleed image (no nav bar background), use `.toolbarBackground(.hidden, for: .navigationBar)` — items still float as glass shapes individually.'  
_skills/liquid-glass/patterns/glass-navigation-bar.md:59_

- **Correct / new info:** The Visibility overload of `toolbarBackground(_:for:)` (-7lv0f) has DocC metadata `deprecatedAt: 27.2` and `renamed: toolbarBackgroundVisibility(_:for:)` on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS (the `deprecated` flag is still false). The replacement exists since iOS 18.0. Apple docs say nothing about items 'still float[ing] as glass shapes individually'. Adopting Liquid Glass tells you to remove custom bar backgrounds and let the system decide.
- **Availability:** toolbarBackgroundVisibility: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+; old toolbarBackground(Visibility) deprecatedAt 27.2
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarbackground(_:for:)-7lv0f (apple-doc, confidence high)
- **Action:** Use `.toolbarBackgroundVisibility(.hidden, for: .navigationBar)`. Drop the 'float individually' claim, or label it as observed behavior.

```swift
nonisolated func toolbarBackgroundVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

### 16. `deprecated` — `.toolbar(.hidden, for: .tabBar)   // hides only within this stack`  
_skills/liquid-glass/patterns/glass-tab-bar.md:79_

- **Correct / new info:** `toolbar(_:for:)` (Visibility) has DocC metadata `deprecatedAt: 27.2` and `renamed: toolbarVisibility(_:for:)` on every platform except visionOS (the `deprecated` flag is still false). The replacement is available from iOS 18.0.
- **Availability:** toolbarVisibility: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+; old toolbar(Visibility, for:) deprecatedAt 27.2
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbar(_:for:) (apple-doc, confidence high)
- **Action:** Use `.toolbarVisibility(.hidden, for: .tabBar)`.

```swift
nonisolated func toolbarVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

### 17. `bad-practice` — The artwork overlay's `Canvas { ctx, size in for _ in 0..<400 { Double.random… } }` draws random grain (lines 114-121).  
_skills/liquid-glass/examples/02-MusicPlayerScreen.swift:114_

- **Correct / new info:** SwiftUI can't compare the Canvas renderer closure across body evaluations. Toggling play or like (body reads `playing` and `liked`) rebuilds the Canvas and redraws 400 dots at new random positions. The grain flickers on every tap instead of behaving like stable artwork.
- **Evidence:**  (reasoning, confidence medium)
- **Action:** Generate the dot positions once, e.g. `private let grain: [CGPoint] = (0..<400).map { _ in CGPoint(x: .random(in: 0...1), y: .random(in: 0...1)) }` scaled by `size`, or use a deterministic hash of the index. Alternatively ship an artwork image.

### 18. `factually-wrong` — Comment: '`.white` and `.primary` are different ShapeStyle types, so neither can be selected with a ternary — branch on the whole button instead.'  
_skills/liquid-glass/examples/07-ProfileScreen.swift:52_

- **Correct / new info:** Both are members of Color (`static let primary: Color`, iOS 13+), so `cond ? .white : .primary` type-checks as Color. examples/06-ChatScreen.swift:150 already does exactly this (`.foregroundStyle(message.fromMe ? .white : .primary)`), and so would the `.tint(.accentColor)`/`.tint(.clear)` pair here. Only the ButtonStyle half of the comment is true: GlassButtonStyle and GlassProminentButtonStyle are distinct types. As written, the comment teaches a false rule; 08:219 and 09:148 repeat the true ButtonStyle half.
- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/color/primary (apple-doc, confidence high)
- **Action:** Reword the comment to: 'GlassButtonStyle and GlassProminentButtonStyle are different concrete types, so the style can't come from a ternary'. Collapse tint and foregroundStyle into ternaries so only the style branches. Optionally mention `.buttonStyle(.glass(isSelected ? .regular.tint(.accentColor) : .regular))` as a single-type alternative. It looks different from .glassProminent, and its availability is unclear: PrimitiveButtonStyle.glass(_:) is documented 26.0 but GlassButtonStyle.init(_:) is 26.1, so gate it with `if #available(iOS 26.1, *)`.

```swift
static let primary: Color
```

### 19. `behavior-change` — The primary CTA uses `.controlSize(.extraLarge)`, as does examples/08-LoginScreen.swift:367. Both follow 01-api-reference.md:268, which says '.extraLarge // new in iOS 26 — for floating CTAs'.  
_skills/liquid-glass/examples/03-OnboardingFlow.swift:75_

- **Correct / new info:** `ControlSize.extraLarge` was introduced in iOS 17.0, not iOS 26. Its DocC abstract says: 'The largest control size. Resolves to ControlSize.large on platforms other than visionOS.' On iPhone these CTAs render at `.large`, so the examples imply a size iOS doesn't have.
- **Availability:** iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/controlsize/extralarge (apple-doc, confidence high)
- **Action:** Use `.controlSize(.large)` in both examples. Correct 01-api-reference.md §7 and the 03-design-tokens FAB recipe.

```swift
case extraLarge
```

### 20. `design-guidance` — HydrationStrip, the content of `.tabViewBottomAccessory`, contains a `.buttonStyle(.glassProminent)` '+250 ml' button. patterns/glass-tab-bar.md:62 likewise puts a `.buttonStyle(.glass)` play button inside the accessory.  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:594_

- **Correct / new info:** The bottom accessory is part of the system's floating tab-bar chrome, so a glass-styled button inside it is glass on system glass. That contradicts the skill's checklist ('System-provided glass … isn't being double-wrapped') and Adopting Liquid Glass ('avoid overcrowding or layering Liquid Glass elements on top of each other'). Apple's accessory samples (WWDC25-323 MusicPlaybackView, DocC HomeStatusView) show no glass-styled buttons. On iPhone the accessory 'displays inline' when the tab bar collapses (`.inline`).
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass (apple-doc, confidence medium)
- **Action:** Use plain or borderless buttons inside the accessory (e.g. a tinted SF Symbol with `.buttonStyle(.plain)`) in both the example and the pattern. Branch the layout on `.inline`, as Apple does.

```swift
enum TabViewBottomAccessoryPlacement { case expanded; case inline }
```

### 21. `design-guidance` — Each of the six MetricChip content cards (icon, title, value, unit, chevron) gets `.glassEffect(.regular.tint(metric.tint.opacity(0.18)), in: .rect(cornerRadius: 20))`.  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:462_

- **Correct / new info:** These are content-layer data cards, not chrome, so they break golden rule 1 and the checklist ('No glass on … card bodies'). HIG: 'Don't use Liquid Glass in the content layer… use standard materials'. The cards are correctly grouped in a container, but each glass is tinted a different hue, and WWDC25-323 says to tint only 'to convey meaning … not just for visual effect'. The chevron also implies the cards are tappable, but they aren't Buttons.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Render the metric cards with `.background(.regularMaterial, in: .rect(cornerRadius: 20))` or a solid surface, and color only the SF Symbol. If the chevron stays, make each card a NavigationLink or Button.

### 22. `design-guidance` — `.searchable(…).searchToolbarBehavior(.minimize)` (62-63) is combined with a custom glass quick-action bar pinned via `.safeAreaInset(edge: .bottom)` (69-73).  
_skills/liquid-glass/examples/05-DashboardScreen.swift:63_

- **Correct / new info:** Apple: 'On iPhone, the search field in the bottom toolbar can be configured to appear as a button-like control when inactive', and toolbar search 'places the field at the bottom of the screen' (WWDC25-323). The custom bar therefore stacks on top of a system bottom toolbar that holds the search button, giving two bottom glass layers. Adopting Liquid Glass says to 'avoid overcrowding or layering Liquid Glass elements'. Apple's Mail sample shows the idiomatic version: actions as `ToolbarItem(placement: .bottomBar)` plus `ToolbarSpacer` plus `DefaultToolbarItem(kind: .search, placement: .bottomBar)` on a single system glass bar.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/searchtoolbarbehavior(_:) (apple-doc, confidence medium)
- **Action:** Move the three quick actions into `.toolbar { ToolbarItemGroup(placement: .bottomBar) { … }; ToolbarSpacer(.flexible, placement: .bottomBar); DefaultToolbarItem(kind: .search, placement: .bottomBar) }`. If a custom bar is kept, use `.safeAreaBar(edge: .bottom)`. Verify the layout on a device.

```swift
nonisolated func searchToolbarBehavior(_ behavior: SearchToolbarBehavior) -> some View
```

### 23. `design-guidance` — `.confirmationDialog("Sign out of this account?", …)` is attached to the List inside the NavigationStack, not to the Sign Out button (46-55) that sets `showSignOut`.  
_skills/liquid-glass/examples/01-SettingsScreen.swift:66_

- **Correct / new info:** WWDC25-323: 'In the new design, dialogs also automatically morph out of the buttons that present them!' Both that sample and the DocC sample attach `.confirmationDialog` to the presenting Button. Adopting Liquid Glass: 'Specify the source of an action sheet. Position an action sheet's anchor next to the control it originates from.' DocC also notes that in regular size classes on iOS the dialog renders as a popover, which here would anchor to the whole List.
- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, tvOS 16.0+, visionOS 1.0+, watchOS 9.0+
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence high)
- **Action:** Move `.confirmationDialog(…)` onto the Sign Out Button, after `.tint(.red)`, so the dialog morphs out of the glass button and anchors correctly on iPad.

```swift
nonisolated func confirmationDialog<A>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ContentBuilder actions: () -> A) -> some View where A : View
```

### 24. `inconsistency` — None of the nine examples reads `accessibilityReduceTransparency` or `accessibilityReduceMotion` (grep finds zero accessibility environment reads). Yet they drive custom motion: `.move` page transitions (03:43-46), `.move(edge: .top/.bottom)` (08:84, 08:126), and scale+opacity pops (04, 06, 09). They also draw custom translucent fills behind or under glass (09:184, 09:313).  
_skills/liquid-glass/examples/03-OnboardingFlow.swift:43_

- **Correct / new info:** Golden rule 7 and the checklist item 'Animations gated by accessibilityReduceMotion where custom-driven' are never demonstrated, and the examples are what users copy. Apple: 'If you use standard components from system frameworks, this experience adapts automatically. Ensure you test your app's custom elements, colors, and animations with different configurations of these settings.' The skill's prescribed fix, swapping to `.identity` under Reduce Transparency, removes the glass entirely (Glass.identity: 'your content remains unaffected as if no glass effect was applied'), so it is not the right demonstration.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass (apple-doc, confidence high)
- **Action:** In at least one example (03 or 08):
- Add `@Environment(\.accessibilityReduceMotion)` and use `withAnimation(reduceMotion ? nil : .bouncy)`, or swap `.move` transitions for `.opacity`.
- Add `@Environment(\.accessibilityReduceTransparency)` to make the custom backdrop and translucent fills opaque, leaving system glass to adapt on its own.
Rewrite golden rule 7 to match.

```swift
static var identity: Glass
```

### 25. `design-guidance` — Icon-only glass buttons are built as `Button { } label: { Image(systemName:) }` with no accessibility label. This happens in 04 (toolButton, heart, more and close, lines 24-80), 02 (controlButton and the play, like, lyrics and share buttons, 42-96), 06 (plus, camera and mic, 51-71), 08 (back and help, 140-175) and 09 (the FAB, 358-370).  
_skills/liquid-glass/examples/04-PhotoDetailScreen.swift:24_

- **Correct / new info:** Adopting Liquid Glass: 'Provide an accessibility label for every icon. Regardless of what you show in the interface, always specify an accessibility label for each icon.' The skill's 05-accessibility.md requires a 'label & hint' on every glass control. The toolbar examples already use the better form, `Button("Share", systemImage: "square.and.arrow.up")`, which carries a label.
- **Evidence:** https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass (apple-doc, confidence high)
- **Action:** Build the helpers (toolButton, controlButton, quickButton, and the FAB toggle) as `Button(title, systemImage: symbol) { … }.labelStyle(.iconOnly)` or add `.accessibilityLabel`. Give the play/pause and heart toggles labels that reflect their state.

### 26. `other` — Posts/Media/Likes is a hand-built glass segmented control: Button if/else branches plus glassEffectID (lines 18-24, 56-82). 08:209 (Sign In/Sign Up) and 09:137 (Day…Year) repeat the pattern, and none of the three exposes which segment is selected to VoiceOver.  
_skills/liquid-glass/examples/07-ProfileScreen.swift:18_

- **Correct / new info:** iOS 27 adds TabsPickerStyle: 'A picker style that presents options as segmented tabs… On iOS, tvOS, and visionOS, the visual appearance matches that of the standard .segmented style. On all supported platforms, VoiceOver announces options as tabs.' Sample: `Picker("View", selection: $view) { … }.pickerStyle(.tabs)`. This suits 07, which is tab navigation. 08 and 09 select values, so `.segmented` is the system control there. Any custom glass switcher that stays needs `.accessibilityAddTraits(isSelected ? .isSelected : [])`.
- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabspickerstyle (apple-doc, confidence high)
- **Action:** In 07, offer `Picker("Section", selection: $tab) { ForEach(ProfileTab.allCases) { Text($0.title).tag($0) } }.pickerStyle(.tabs)` behind `if #available(iOS 27, *)`, falling back to `.segmented` (the Gallery deploys to 26.0). In all three custom switchers, add the `.isSelected` trait to the selected segment.

```swift
struct TabsPickerStyle ; static var tabs: TabsPickerStyle
```

### 27. `design-guidance` — Tints are decorative rather than semantic:
- 05 quick actions: `.tint(.blue/.orange/.yellow)` (81-83).
- 09 FAB actions: blue, orange, yellow and pink (344-353).
- 09 metric and stat chips: a different hue per metric (220, 462).
- 09 toolbar bell: `.tint(.red)` (110).
- About 14 `.tint(.white)` and 12 translucent-white tints across 02, 03, 04, 07, 08 and 09.  
_skills/liquid-glass/examples/05-DashboardScreen.swift:83_

- **Correct / new info:** This contradicts the skill's own guidance:
- Golden rule 6: 'Tint sparingly. .tint() carries semantic meaning'.
- The token table, where orange and yellow mean warning and caution.
- 05-accessibility.md: '.tint(.white) becomes .tint(.black)' under Smart Invert, so 'use system colors' (checklist: 'Tints are system colors').
WWDC25-323: 'You can still tint icons with a tint modifier, but use this to convey meaning … not just for visual effect.' Apple's badge sample uses no tint, and `.tint` doesn't recolor the badge anyway.
Concretely, DashboardScreen doesn't force dark mode, and these examples use `.tint` on `.glass` buttons to color the label (02:78, 04:38). So 'Log mood' renders yellow on light glass, far below the 4.5:1 contrast the skill requires.
The tints are low opacity (≤0.3), so saturation itself is not the problem.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence medium)
- **Action:** Keep one semantic tint per screen: accent for primary, red for destructive. Use untinted `.glass` for neutral actions, and color only the SF Symbol where meaning is needed (`.symbolRenderingMode(.hierarchical)`). Drop `.tint(.red)` from the toolbar bell. Replace `.tint(.white…)` with `.accentColor` or no tint, following the skill's own Smart Invert rule.

### 28. `bad-practice` — The pagination dots are `Capsule().fill(.white).frame(…).glassEffect(.regular.tint(.white.opacity(0.2)), in: .capsule)` (lines 54-58).  
_skills/liquid-glass/examples/03-OnboardingFlow.swift:57_

- **Correct / new info:** glassEffect 'Renders a shape anchored behind a view with the Liquid Glass material' and 'Applies the foreground effects… over a view'. Here the view is an opaque white capsule exactly the size and shape of the glass, so it covers the glass body and nothing gets lensed. The result is three glass passes for what reads as solid white pills, and the inactive dots don't read as glass either.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence medium)
- **Action:** Either drop the glass (page dots aren't chrome; use plain capsules), or drop the fill: `Color.clear.frame(width: i == step ? 28 : 8, height: 8).glassEffect(.regular.tint(i == step ? .white : nil), in: .capsule)`. `Glass.tint` takes `Color?`, so nil is allowed.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 29. `inconsistency` — `topBar` (137-178) hand-builds a navigation bar from an HStack in a GlassEffectContainer: a glass back chevron, a non-interactive glass capsule holding the title 'Welcome', and a glass help button.  
_skills/liquid-glass/examples/08-LoginScreen.swift:137_

- **Correct / new info:** The skill's own glass-navigation-bar pattern says 'Use NavigationStack — it's glass by default' and warns against custom HStack nav bars. Apple: 'Standard components from system frameworks pick up the appearance and behavior of this material automatically… If you apply Liquid Glass effects to a custom control, do so sparingly.' Putting the static title in a glass capsule gives glass to a non-interactive label, which system bars never do.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence medium)
- **Action:** Wrap the screen in NavigationStack with `.navigationTitle("Welcome").navigationBarTitleDisplayMode(.inline)` and `.toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { } }; ToolbarItem(placement: .topBarTrailing) { Button("Help", systemImage: "questionmark") { … } } }`. Add `.toolbarBackgroundVisibility(.hidden, for: .navigationBar)` if the backdrop must show through.

### 30. `design-guidance` — Glass is used as decoration on content: the onboarding hero symbol (`.glassEffect(.regular.tint(.white.opacity(0.1)), in: .circle)`), the login hero symbol (08:188), the profile avatar ring (07:130), and a full-width `.glassProminent` Sign Out button inside a List row (01:52).  
_skills/liquid-glass/examples/03-OnboardingFlow.swift:91_

- **Correct / new info:** HIG Materials: 'Don't use Liquid Glass in the content layer… An exception to this is for controls in the content layer with a transient interactive element like sliders and toggles'. It also says 'Use Liquid Glass effects sparingly… Limit these effects to the most important functional elements in your app.' Hero illustrations and avatars are content, and the skill's own layer table marks 'hero images' and 'List rows' as no-glass.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence medium)
- **Action:** Give the hero symbols and avatar ring solid or standard-material backgrounds (e.g. `.background(.thinMaterial, in: .circle)`). In Settings, either use a standard destructive row (`Button("Sign Out", role: .destructive)`) or move the CTA out of the List into a `.safeAreaBar(edge: .bottom)`.

### 31. `inconsistency` — Glass buttons that already have glassEffectIDs inside a GlassEffectContainer also get `.transition(.scale.combined(with: .opacity))`, at 04:47/50, 06:67/70 and 09:346-355.  
_skills/liquid-glass/examples/04-PhotoDetailScreen.swift:47_

- **Correct / new info:** The skill's anti-pattern #5 says not to fade glass opacity and to let the system materialize it instead. Apple's guidance:
- 'For effects you want to add or remove that are positioned within the container's assigned spacing, the default transition type is matchedGeometry.'
- 'Use the materialize transition for effects… farther from each other.'
- 'use matchedGeometry and materialize transitions across your apps. The system applies more than opacity changes with the available transition types.'
The added view transition layers a fade over the glass morph, so the examples model what the skill forbids. How the two interact visually is not documented.
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence medium)
- **Action:** Remove `.transition(.scale.combined(with: .opacity))` from glass elements inside containers and rely on the default matchedGeometry morph. Use `.glassEffectTransition(.materialize)` only for effects that appear far from their siblings.

### 32. `platform-requirement` — `SWIFT_VERSION: "5.0"`, with no SWIFT_STRICT_CONCURRENCY, SWIFT_DEFAULT_ACTOR_ISOLATION or SWIFT_APPROACHABLE_CONCURRENCY settings.  
_Gallery/project.yml:28_

- **Correct / new info:** Xcode 27 'includes Swift 6.4' (Xcode 27 release notes). The Gallery compiles the examples in Swift 5 language mode, so Swift 6 data-race errors are never surfaced. Meanwhile 01-api-reference.md §15 lists 'Swift 6.1+' as a requirement, and users paste these examples into Swift 6 targets. The iOS 27 release notes describe 'approachable-concurrency defaults that infer MainActor isolation'. No Xcode 27 note deprecating Swift 5 mode was found, so the current setting still builds. Reading the code, nothing obvious would fail in Swift 6 mode: no global mutable state, no async code, String glassEffectIDs (Sendable), value-type state. That remains unproven without a build.
- **Availability:** Xcode 27 (Swift 6.4)
- **Evidence:** https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes (apple-other, confidence medium)
- **Action:** Set `SWIFT_VERSION: "6.0"`. Add a configuration with `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY: YES` to mirror new-project defaults. Build with Xcode 27 and record the verified toolchain in Gallery/README.md. Keep the deployment target at 26.0 unless 27-only APIs are adopted without availability checks.

### 33. `factually-wrong` — `.scrollContentBackground(.hidden)` is applied to a ScrollView 'so glass shows through scrollables' (also line 60).  
_skills/liquid-glass/patterns/glass-modal-sheet.md:42_

- **Correct / new info:** DocC: 'Specifies the visibility of the background for scrollable views within this view'. Its example 'hides the standard system background of the List'. It also notes: 'List and Form have the seamless appearance by default, configurable by hiding the scroll background. ScrollView can become seamless by making the background visible' (macOS). A plain ScrollView on iOS has no system background, so in this snippet the modifier does nothing.
- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, visionOS 1.0+, watchOS 9.0+ (no tvOS)
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/scrollcontentbackground(_:) (apple-doc, confidence medium)
- **Action:** Remove it from the ScrollView snippet, or switch the sheet body to a List or Form. Reword the bullet to say it applies to List, Form and TextEditor.

```swift
nonisolated func scrollContentBackground(_ visibility: Visibility) -> some View
```

### 34. `factually-wrong` — Prose next to the snippets says DefaultToolbarItem 'pins the search field above the tab bar' (66), that search 'lives in the nav bar' (4), and that the search tab 'takes prominence in the nav layer' (79). glass-tab-bar.md:85 adds that the `.search` tab 'surfaces the system search field at the top of the screen'.  
_skills/liquid-glass/patterns/glass-search-field.md:66_

- **Correct / new info:** WWDC25-323: 'Search in the toolbar places the field at the bottom of the screen, within easy reach. And on iPad and Mac, it appears in the top-trailing position of the toolbar.' On the search tab: 'When someone selects this tab, a search field takes the place of the tab bar.' DefaultToolbarItem repositions the system search item among the bottom-bar items. On iOS 27, a `.search` tab 'may receive the prominent visual treatment by default' (TabRole.prominent docs).
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/ (apple-video, confidence high)
- **Action:** Rewrite these sentences to match Apple:
- Toolbar search sits at the bottom on iPhone and top-trailing on iPad and Mac.
- Selecting the search tab replaces the tab bar with the search field.
- DefaultToolbarItem repositions the search item.

### 35. `inconsistency` — The pattern says 'Inside the accessory, react to whether it's expanded or collapsed', and its code branches on `placement == .expanded`. 01-api-reference.md:396 lists the values as `.expanded | .collapsed`.  
_skills/liquid-glass/patterns/glass-tab-bar.md:44_

- **Correct / new info:** TabViewBottomAccessoryPlacement has exactly two cases, `expanded` and `inline`; there is no `.collapsed`. The environment value is Optional, which is why `== .expanded` compiles; nil means an undefined placement. Apple's samples branch on `.inline` for the compact layout (WWDC25-323: `if placement == .inline { compact } else { full }`). examples/09:574 uses the same `.expanded` check, so its nil case falls into the compact branch.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement (apple-doc, confidence high)
- **Action:** Reword to 'expanded or inline (when the tab bar minimizes)'. Branch on `.inline` in the pattern and in 09's HydrationStrip, and fix the comment in 01-api-reference.md.

```swift
enum TabViewBottomAccessoryPlacement { case expanded; case inline }
```

### 36. `bad-practice` — The message field is a `TextField(…, axis: .vertical).lineLimit(1...5)` (74-75) inside an HStack with `.glassEffect(.regular, in: .capsule)`.  
_skills/liquid-glass/examples/06-ChatScreen.swift:92_

- **Correct / new info:** A Capsule's corner radius is half its height. As the text grows to five lines, the glass becomes a tall pill and the text runs into its rounded ends. The skill's own card-stack gotcha says to switch from the default capsule to a rounded rect when content wraps.
- **Evidence:**  (reasoning, confidence medium)
- **Action:** Use `.glassEffect(.regular, in: .rect(cornerRadius: 20))`, or pick the shape based on the line count, so multi-line input stays legible.

### 37. `behavior-change` — Do the examples rely on behavior that changes with Xcode 27's @State macro or the ContentBuilder unification (TN3211)?

- **Correct / new info:** No. TN3211 lists these breaks.
@State:
- assigning to @State in an init before other stored properties, or when an inline default exists;
- composing another property wrapper with @State;
- extensions calling the synthesized private memberwise init of a view that has @State.
ContentBuilder:
- non-builder background/overlay given a ShapeStyle expression with opacity/blendMode;
- type or member names colliding with an imported module;
- spelled `TupleView` constraints;
- MapKit in scope with an empty nested builder;
- deeply branching Chart closures.
None of these occur in the examples:
- Every @State has an inline default and no view defines an init. The only call sites are the implicit `Screen()` initializers in GalleryApp and #Preview.
- No TupleView, MapKit or Charts.
- File-private `Widget`, `Message`, `Metric` and `Workout` are declared in the app module, so they shadow imported names rather than collide.
- All @State values are value types, so the new initialize-once laziness changes nothing visible.
The only related code is the deprecated non-builder overlay/background (separate finding). Xcode 27 also deprecates PreviewProvider and now runs #Preview on the main actor; the examples already use #Preview.
- **Availability:** Xcode 27 (macro and ContentBuilder apply at any deployment target). 'When you build with Xcode 26 or earlier, the system uses the State property wrapper instead.'
- **Evidence:** https://developer.apple.com/documentation/technotes/tn3211-resolving-swiftui-source-incompatibilities-for-state-and-contentbuilder (apple-doc, confidence high)
- **Action:** No code change needed for TN3211. Optionally add an 'Xcode 27' note to the skill: don't give @State both an inline default and an init assignment, don't compose other wrappers with it, and prefer the closure forms of overlay/background.

```swift
@attached(accessor, names: named(init), named(get), named(set)) @attached(peer, names: prefixed(`_`), prefixed(__), prefixed(`$`)) macro State() ; typealias ContentBuilder = ViewBuilder
```

### 38. `other` — The chat input bar, which contains a TextField driven by `@FocusState inputFocused`, is pinned with `.safeAreaInset(edge: .bottom)`.  
_skills/liquid-glass/examples/06-ChatScreen.swift:40_

- **Correct / new info:** iOS 26 added `safeAreaBar(edge:alignment:spacing:content:)` as the bar-specific API: 'Similar to the safeAreaInset… Additionally, it extends the edge effect of any scroll views affected by the inset safe area.' However, the iOS 26.1 release notes list a known issue: 'On iOS and iPadOS, @FocusState doesn't work in safeAreaBar. (158720838)'. No 'Fixed' entry appears in the 26.2, 26.4 or 27.0 SwiftUI notes. Keeping safeAreaInset is the safe choice for this focus-driven bar, but the example doesn't say why.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26_1-release-notes (apple-other, confidence medium)
- **Action:** Keep `.safeAreaInset` in ChatScreen and add a comment citing 158720838. Use `.safeAreaBar(edge: .bottom)` where no focus is involved (05's quick actions, the floating-toolbar pattern). Retest 06 with safeAreaBar on later releases.

```swift
nonisolated func safeAreaBar(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content: () -> some View) -> some View (plus a VerticalEdge/HorizontalAlignment overload)
```

### 39. `other` — The 'Toolbar that hugs an edge' variation pins the custom glass toolbar with `.safeAreaInset(edge: .bottom)`.  
_skills/liquid-glass/patterns/glass-floating-toolbar.md:61_

- **Correct / new info:** Since iOS 26, `safeAreaBar(edge:…)` insets the safe area the same way and 'extends the edge effect of any scroll views affected by the inset safe area', which is what a floating glass bar over scrolling content needs. For a plain row of actions, a system bottom toolbar (`ToolbarItemGroup(placement: .bottomBar)` plus `ToolbarSpacer`) gets glass grouping for free.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:) (apple-doc, confidence high)
- **Action:** Change the variation to `.safeAreaBar(edge: .bottom) { EditorToolbar() }`. Note the @FocusState known issue for bars that contain text input, and mention the system bottomBar alternative.

```swift
nonisolated func safeAreaBar(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content: () -> some View) -> some View (plus a VerticalEdge/HorizontalAlignment overload)
```

### 40. `other` — HealthAppShell minimizes the tab bar on scroll (`.tabBarMinimizeBehavior(.onScrollDown)`, line 39), but the Today screen's navigation bar never minimizes.  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:101_

- **Correct / new info:** iOS 27 adds `toolbarMinimizationBehavior(_:for:)`: 'Use this modifier to enable toolbar minimization in response to scrolling. The supported placement is navigationBar. When the navigation bar minimizes, an integrated top tab bar will also minimize.' The DocC sample applies `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)` to the scroll content inside a NavigationStack. WWDC26-269's on-screen code spells it `toolbarMinimizeBehavior`, which returns 404 in DocC. The iOS 27 release notes say 'You can use toolbarMinimizationBehavior… This modifier replaces toolbarMinimizeBehavior. (177954148)'.
- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:) (apple-doc, confidence high)
- **Action:** Add `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)` to the Today ScrollView so the nav bar and tab bar recede together. The Gallery deploys to 26.0, so apply it through a small ViewModifier with `if #available(iOS 27, *)`. Never use the WWDC26 spelling.

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

### 41. `other` — The tab-bar pattern, and 09's HealthAppShell (line 34), teach only `role: .search` and an always-on `.tabViewBottomAccessory { … }`.  
_skills/liquid-glass/patterns/glass-tab-bar.md:20_

- **Correct / new info:** iOS 27 adds TabRole.prominent: 'provides prominent visual treatment to one of the tabs… Only one tab can receive the prominent treatment. When there are no tabs with an explicit .prominent role, then a .search role tab may receive the prominent visual treatment by default.' WWDC26 sample: `Tab(role: .prominent) { CartTab() }`. So on iOS 27 the Search/Browse tab in both pattern and example may render prominent with no code change. iOS 26.1 also added `tabViewBottomAccessory(isEnabled:content:)` 'to dynamically show and hide the accessory view', for example a now-playing strip shown only while audio plays.
- **Availability:** TabRole.prominent: iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+; tabViewBottomAccessory(isEnabled:content:): iOS 26.1+, iPadOS 26.1+, Mac Catalyst 26.1+
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabrole/prominent (apple-doc, confidence high)
- **Action:** Add a '.prominent tab (iOS 27)' variation and a note about the .search default. Show `.tabViewBottomAccessory(isEnabled: isPlaying) { NowPlayingStrip() }` (26.1+) in the pattern, and consider it for 09's HydrationStrip (e.g. shown only while below target).

```swift
static var prominent: TabRole { get } ; nonisolated func tabViewBottomAccessory<Content>(isEnabled: Bool, @ContentBuilder content: () -> Content) -> some View where Content : View
```

### 42. `other` — The only transition variation is a zoom from a free-standing Button using `View.matchedTransitionSource`, even though the pattern's own Solution presents the sheet from a toolbar button (lines 14-20).  
_skills/liquid-glass/patterns/glass-modal-sheet.md:64_

- **Correct / new info:** For a toolbar trigger, iOS 26 provides `ToolbarContent.matchedTransitionSource(id:in:)`, applied to the ToolbarItem. DocC sample: `ToolbarItem(placement: .topBarTrailing) { Button(…) }.matchedTransitionSource(id: "world", in: namespace)` paired with `.sheet { SheetView().navigationTransition(.zoom(sourceID: "world", in: namespace)) }`. iOS 27 adds NavigationTransition.crossFade: 'Specify this transition in a sheet to have it appear by fading in over the content, as opposed to moving upwards to cover content.' crossFade is not available on macOS.
- **Availability:** ToolbarContent.matchedTransitionSource: iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+; crossFade: iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/navigationtransition/crossfade (apple-doc, confidence high)
- **Action:** Make the zoom variation use the Solution's Info toolbar item (`ToolbarItem { … }.matchedTransitionSource(id: "info", in: ns)`). Add a 'Cross-fade sheet (iOS 27)' variation: `.sheet(isPresented:) { Content().presentationDetents([.medium]).navigationTransition(.crossFade) }`.

```swift
nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some ToolbarContent ; static var crossFade: CrossFadeNavigationTransition { get }
```

### 43. `other` — The Today toolbar has Profile (leading) and Inbox, a fixed ToolbarSpacer and Share (trailing), with no priority information. ProfileScreen (07:41-48) has Settings and Share trailing.  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:107_

- **Correct / new info:** iOS 27 adds three ways to control toolbar overflow:
- `ToolbarContent.visibilityPriority(_:)`: 'items with a lower priority move into the overflow menu before items with a higher priority'.
- `ToolbarOverflowMenu { … }`: actions 'always placed in the toolbar's overflow menu'.
- `ToolbarItemPlacement.topBarPinnedTrailing`: 'Pinned items only move to the overflow menu when search is active and there isn't enough room.'
WWDC26-269 shows all three together, including `ToolbarItem(placement: .topBarPinnedTrailing) { ShareButton() }`. ToolbarOverflowMenu and topBarPinnedTrailing are available only on iOS, iPadOS, Mac Catalyst and visionOS.
- **Availability:** visibilityPriority: iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 26.1+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+; ToolbarOverflowMenu and topBarPinnedTrailing: iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, visionOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:) (apple-doc, confidence high)
- **Action:** In an iOS 27 variant of 09, give Inbox `.visibilityPriority(.high)` and pin Share with `.topBarPinnedTrailing`. In 07, move the secondary Settings action into `ToolbarOverflowMenu { … }`. Gate with `if #available(iOS 27, *)` inside the toolbar builder, and confirm that compiles at the 26.0 deployment target.

```swift
@MainActor @preconcurrency func visibilityPriority(_ priority: ToolbarItemVisibilityPriority) -> some ToolbarContent ; nonisolated struct ToolbarOverflowMenu<Content> where Content : View ; static let topBarPinnedTrailing: ToolbarItemPlacement
```

### 44. `behavior-change` — The README says 'Requires Xcode 26 or later' and 'Pick an iPhone simulator running iOS 26' (line 22). The committed docs/screenshots were captured from this app on iOS 26.  
_Gallery/README.md:9_

- **Correct / new info:** WWDC26-269: 'When I build and run our app, the Liquid Glass design automatically takes on its updated appearance… Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint.' Built with Xcode 27 for iOS 27, every screen will differ from the committed screenshots, and the custom `.white.opacity` fills in 09 won't follow the slider. The Gallery's `UILaunchScreen: {}` passes TN3208's iOS 27 App Store launch-screen check, which only requires the key to be present.
- **Availability:** Xcode 27 / iOS 27
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/269/ (apple-video, confidence medium)
- **Action:** Re-capture docs/screenshots on an iOS 27 simulator after the fixes. Note which OS the screenshots show, and test at both ends of the Liquid Glass slider (clear and tinted).

### 45. `other` — `LabeledContent("Apple ID", value: …)` hardcodes a real personal email address in a published example.  
_skills/liquid-glass/examples/01-SettingsScreen.swift:24_

- **Correct / new info:** The skill ships in a public plugin directory, and examples get copied verbatim. Placeholder data would avoid publishing a personal address, and the other examples already use fictional names (e.g. 'Lyra Calder').
- **Evidence:**  (reasoning, confidence high)
- **Action:** Replace it with a placeholder such as `name@example.com`. Also check docs/screenshots/01-settings.png, which was captured from this screen and likely shows the address.

## Symbols (40)

### `DefaultToolbarItem / init(kind:placement:)`

```swift
nonisolated struct DefaultToolbarItem ; nonisolated init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** init(kind:placement:); Conforms To: ToolbarContent
- **Doc:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem/init(kind:placement:)
- **Skill uses it correctly:** NO
- **Notes:** Nested inside ToolbarItem at glass-search-field.md:59-61 and 01-api-reference.md:421-423, which is a compile error. It must be a direct child of .toolbar {}. It repositions or replaces the default-placed system item ('Return Value: A ToolbarItem with content provided by the kind').

### `ToolbarItem`

```swift
nonisolated struct ToolbarItem<ID, Content> where Content : View
```

- **Availability:** iOS 14.0+, iPadOS 14.0+, Mac Catalyst 14.0+, macOS 11.0+, tvOS 14.0+, visionOS 1.0+, watchOS 7.0+
- **Members:** init(placement: ToolbarItemPlacement, content: () -> Content), init(id: String, placement: ToolbarItemPlacement, content: () -> Content), init(id:placement:showsByDefault:content:) [deprecated]
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritem
- **Skill uses it correctly:** yes
- **Notes:** Every example usage wraps a Button View and is correct. The Content : View requirement is why nesting DefaultToolbarItem fails.

### `ToolbarContent.sharedBackgroundVisibility(_:)`

```swift
nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+
- **Members:** visibility: Visibility
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:)
- **Skill uses it correctly:** NO
- **Notes:** 01-api-reference.md:349 applies it to a Button (a View), which does not compile. No pattern or example uses it.

### `View.toolbarBackground(_:for:) [Visibility overload, -7lv0f]`

```swift
nonisolated func toolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** Introduced iOS 16.0 / iPadOS 16.0 / Mac Catalyst 16.0 / macOS 13.0 / tvOS 16.0 / watchOS 9.0 / visionOS 1.0; deprecatedAt 27.2 (deprecated flag false) on all but visionOS; renamed toolbarBackgroundVisibility(_:for:)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarbackground(_:for:)-7lv0f
- **Skill uses it correctly:** NO
- **Notes:** Used at glass-navigation-bar.md:59. The ShapeStyle overload (-5ybst) is not deprecated.

### `View.toolbarBackgroundVisibility(_:for:)`

```swift
nonisolated func toolbarBackgroundVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarbackgroundvisibility(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** The replacement API. The skill does not use it yet.

### `View.toolbar(_:for:) [Visibility] / View.toolbarVisibility(_:for:)`

```swift
nonisolated func toolbar(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View ; nonisolated func toolbarVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** toolbar(_:for:): introduced iOS 16.0, deprecatedAt 27.2 (all but visionOS), renamed toolbarVisibility(_:for:); toolbarVisibility: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarvisibility(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** glass-tab-bar.md:79 uses the old spelling.

### `View.navigationBarTitleDisplayMode(_:)`

```swift
nonisolated func navigationBarTitleDisplayMode(_ displayMode: NavigationBarItem.TitleDisplayMode) -> some View
```

- **Availability:** iOS 14.0+, iPadOS 14.0+, Mac Catalyst 14.0+, visionOS 1.0+, watchOS 8.0+ (no deprecation fields)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/navigationbartitledisplaymode(_:)
- **Skill uses it correctly:** yes
- **Notes:** Not deprecated in the 27 SDK docs. Uses at 06:31, 09:102 and glass-navigation-bar.md:20 are fine.

### `View.overlay(_:alignment:) [non-builder]`

```swift
nonisolated func overlay<Overlay>(_ overlay: Overlay, alignment: Alignment = .center) -> some View where Overlay : View
```

- **Availability:** Introduced iOS 13.0; deprecatedAt 27.2 on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS, watchOS; message 'Use `overlay(alignment:content:)` instead.'
- **Doc:** https://developer.apple.com/documentation/swiftui/view/overlay(_:alignment:)
- **Skill uses it correctly:** NO
- **Notes:** Used at 08:274, 08:314 and 09:185. TN3211 recommends closure forms; these call sites avoid the ShapeStyle ambiguity case because they pass shape views.

### `View.background(_:alignment:) [non-builder]`

```swift
nonisolated func background<Background>(_ background: Background, alignment: Alignment = .center) -> some View where Background : View
```

- **Availability:** Introduced iOS 13.0; deprecatedAt 27.2 on all platforms; message 'Use `background(alignment:content:)` instead.'
- **Doc:** https://developer.apple.com/documentation/swiftui/view/background(_:alignment:)
- **Skill uses it correctly:** NO
- **Notes:** Used at 09:311. The ShapeStyle forms (`.background(.background)`, `.background(.blue, in: .circle)`, AnyShapeStyle) used elsewhere are not affected.

### `ScrollView.init(_:showsIndicators:content:)`

```swift
nonisolated init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ContentBuilder content: () -> Content)
```

- **Availability:** Introduced iOS 13.0; deprecatedAt 27.2 on iOS, iPadOS, Mac Catalyst, macOS, tvOS, watchOS; message 'Use the ScrollView(_:content:) initializer and the scrollIndicators(:_) modifier'
- **Doc:** https://developer.apple.com/documentation/swiftui/scrollview/init(_:showsindicators:content:)
- **Skill uses it correctly:** NO
- **Notes:** Used at 05:47, 09:240 and 09:271.

### `ScrollViewReader`

```swift
@frozen nonisolated struct ScrollViewReader<Content> where Content : View
```

- **Availability:** iOS 14.0+, iPadOS 14.0+, Mac Catalyst 14.0+, macOS 11.0+, tvOS 14.0+, visionOS 1.0+, watchOS 7.0+ (no deprecation fields)
- **Doc:** https://developer.apple.com/documentation/swiftui/scrollviewreader
- **Skill uses it correctly:** yes
- **Notes:** 06-ChatScreen usage is fine and not deprecated.

### `View.confirmationDialog(_:isPresented:titleVisibility:actions:)`

```swift
nonisolated func confirmationDialog<A>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ContentBuilder actions: () -> A) -> some View where A : View
```

- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, tvOS 16.0+, visionOS 1.0+, watchOS 9.0+
- **Members:** Overloads for LocalizedStringResource, Text, StringProtocol titles
- **Doc:** https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:)
- **Skill uses it correctly:** yes
- **Notes:** Compiles and is not deprecated. 01 attaches it to the List rather than the presenting Button; Apple's DocC and WWDC25-323 samples attach it to the Button so the dialog morphs from it.

### `Color.primary`

```swift
static let primary: Color
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/color/primary
- **Skill uses it correctly:** NO
- **Notes:** Makes `cond ? .white : .primary` valid as Color. 06:150 uses it correctly, but the 07:52-54 comment claims it can't be done.

### `ControlSize.extraLarge`

```swift
case extraLarge
```

- **Availability:** iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS 1.0+, watchOS 10.0+
- **Members:** ControlSize: mini, small, regular, large, extraLarge
- **Doc:** https://developer.apple.com/documentation/swiftui/controlsize/extralarge
- **Skill uses it correctly:** NO
- **Notes:** 'Resolves to ControlSize.large on platforms other than visionOS.' Used at 03:75 and 08:367. 01-api-reference.md calls it new in iOS 26, which is wrong.

### `TabsPickerStyle / PickerStyle.tabs`

```swift
struct TabsPickerStyle ; static var tabs: TabsPickerStyle
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+
- **Members:** init()
- **Doc:** https://developer.apple.com/documentation/swiftui/tabspickerstyle
- **Skill uses it correctly:** NO
- **Notes:** Not used yet (opportunity). On iOS it looks like .segmented, and VoiceOver announces the options as tabs. It fits 07's Posts/Media/Likes switcher.

### `View.glassEffect(_:in:)`

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (visionOS not listed)
- **Members:** glass: Glass = .regular; in shape: some Shape = DefaultGlassEffectShape()
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Skill uses it correctly:** yes
- **Notes:** All 17 example call sites compile. Placement on content cards and nesting are design issues, not API misuse. DocC: it 'Renders a shape anchored behind a view' and 'Applies the foreground effects… over a view'. There is no isEnabled overload.

### `Glass`

```swift
struct Glass
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** static var regular: Glass, static var clear: Glass, static var identity: Glass, func tint(Color?) -> Glass, func interactive(Bool) -> Glass; conforms to Equatable, Sendable, SendableMetatype
- **Doc:** https://developer.apple.com/documentation/swiftui/glass
- **Skill uses it correctly:** yes
- **Notes:** Examples use .regular and .regular.tint(...) correctly. identity: 'your content remains unaffected as if no glass effect was applied', so it is a poor Reduce Transparency fallback.

### `GlassEffectContainer`

```swift
@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View ; init(spacing: CGFloat?, content: () -> Content)
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Members:** init(spacing:content:)
- **Doc:** https://developer.apple.com/documentation/swiftui/glasseffectcontainer
- **Skill uses it correctly:** yes
- **Notes:** All 16 example containers set spacing equal to the inner stack spacing, as Apple's sample does. Missing containers: 08's form fields, 09's hero stat chips and 09's workout-card chips. Apple: 'Creating too many Liquid Glass effect containers… can degrade performance.'

### `View.glassEffectID(_:in:)`

```swift
func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffectid(_:in:)
- **Skill uses it correctly:** yes
- **Notes:** All IDs are String, which is Sendable. Applying it to `.buttonStyle(.glass)` buttons matches Apple's WWDC25-323 BadgeToggle sample. It only has an effect during transitions or animations.

### `PrimitiveButtonStyle.glass(_:)`

```swift
nonisolated static func glass(_ glass: Glass) -> Self
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (per its page; the backing GlassButtonStyle.init(_:) is 26.1)
- **Members:** Available when Self is GlassButtonStyle
- **Doc:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glass(_:)
- **Skill uses it correctly:** NO
- **Notes:** Not used. It could replace some if/else style branching as `.glass(isSelected ? .regular.tint(.accentColor) : .regular)`, but the docs disagree on 26.0 vs 26.1, so gate it with #available(iOS 26.1, *).

### `GlassButtonStyle / init(_:)`

```swift
nonisolated struct GlassButtonStyle ; nonisolated init(_ glass: Glass)
```

- **Availability:** Type: iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+; init(_:): iOS 26.1+, iPadOS 26.1+, Mac Catalyst 26.1+, macOS 26.1+, tvOS 26.1+, watchOS 26.1+
- **Members:** init(), init(_:), makeBody(configuration:)
- **Doc:** https://developer.apple.com/documentation/swiftui/glassbuttonstyle/init(_:)
- **Skill uses it correctly:** yes
- **Notes:** Examples use .buttonStyle(.glass) correctly. In these examples, .tint on .glass colors the label (02:78, 04:38).

### `Shape.rect(cornerRadius:style:)`

```swift
@export(implementation) static func rect(cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) -> Self
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/shape/rect(cornerradius:style:)
- **Skill uses it correctly:** NO
- **Notes:** Numeric uses (08:273, 09:203, 09:315, 09:462) are correct. `.rect(cornerRadius: .containerConcentric)` at glass-card-stack.md:92 does not exist; the page has no containerConcentric member.

### `Shape.rect(corners:isUniform:)`

```swift
@export(implementation) static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** corners: Edge.Corner.Style; isUniform: Bool = false
- **Doc:** https://developer.apple.com/documentation/swiftui/shape/rect(corners:isuniform:)
- **Skill uses it correctly:** NO
- **Notes:** The correct concentric API. The skill does not use it. Radii are calculated relative to the container shape.

### `TabRole.prominent`

```swift
static var prominent: TabRole { get }
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/tabrole/prominent
- **Skill uses it correctly:** NO
- **Notes:** Not used (opportunity). Only one tab can be prominent, and a .search tab may get the prominent treatment by default, which affects 09's Browse tab and the pattern's Search tab.

### `View.toolbarMinimizationBehavior(_:for:)`

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Members:** Sample uses .onScrollDown; related toolbarMinimizationSafeAreaAdjustment(_:for:), ToolbarMinimizationRestoration
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** Not used (opportunity for 09). The supported placement is navigationBar. The WWDC26-269 spelling `toolbarMinimizeBehavior(_:for:)` returns HTTP 404 in DocC, and the release notes say it was replaced.

### `ToolbarOverflowMenu`

```swift
nonisolated struct ToolbarOverflowMenu<Content> where Content : View ; init(content: () -> Content)
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, visionOS 27.0+
- **Members:** init(content:); conforms to CustomizableToolbarContent, ToolbarContent
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu
- **Skill uses it correctly:** NO
- **Notes:** Not used (opportunity). Its actions are always placed in the overflow menu.

### `ToolbarItemPlacement.topBarPinnedTrailing`

```swift
static let topBarPinnedTrailing: ToolbarItemPlacement
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, visionOS 27.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbaritemplacement/topbarpinnedtrailing
- **Skill uses it correctly:** NO
- **Notes:** Not used (opportunity). 'Pinned items only move to the overflow menu when search is active and there isn't enough room.'

### `NavigationTransition.crossFade`

```swift
static var crossFade: CrossFadeNavigationTransition { get }
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+ (not macOS)
- **Doc:** https://developer.apple.com/documentation/swiftui/navigationtransition/crossfade
- **Skill uses it correctly:** NO
- **Notes:** Not used (opportunity for glass-modal-sheet.md). Used inside a sheet, it fades the sheet in instead of sliding it up.

### `ToolbarContent.visibilityPriority(_:)`

```swift
@MainActor @preconcurrency func visibilityPriority(_ priority: ToolbarItemVisibilityPriority) -> some ToolbarContent
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 26.1+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Members:** ToolbarItemVisibilityPriority.automatic (documented); .high is used in Apple's sample
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:)
- **Skill uses it correctly:** NO
- **Notes:** Not used (opportunity).

### `View.safeAreaBar(edge:alignment:spacing:content:)`

```swift
nonisolated func safeAreaBar(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content: () -> some View) -> some View (plus a VerticalEdge/HorizontalAlignment overload)
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:)
- **Skill uses it correctly:** NO
- **Notes:** Not used. The examples use safeAreaInset (05, 06, floating-toolbar pattern). iOS 26.1 known issue 158720838: @FocusState doesn't work in safeAreaBar; no fix appears in the 26.2, 26.4 or 27.0 notes.

### `TabViewBottomAccessoryPlacement`

```swift
enum TabViewBottomAccessoryPlacement
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** case expanded, case inline
- **Doc:** https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement
- **Skill uses it correctly:** NO
- **Notes:** The `== .expanded` code at 09:574 and glass-tab-bar.md:54 compiles. The pattern prose ('collapsed') and 01-api-reference.md:396 (`.collapsed`) are wrong. Apple branches on .inline.

### `View.tabViewBottomAccessory(isEnabled:content:)`

```swift
nonisolated func tabViewBottomAccessory<Content>(isEnabled: Bool, @ContentBuilder content: () -> Content) -> some View where Content : View
```

- **Availability:** iOS 26.1+, iPadOS 26.1+, Mac Catalyst 26.1+
- **Members:** isEnabled: Bool; content
- **Doc:** https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:)
- **Skill uses it correctly:** NO
- **Notes:** Not used (opportunity). Use it to show or hide the accessory dynamically.

### `SearchToolbarBehavior / View.searchToolbarBehavior(_:)`

```swift
struct SearchToolbarBehavior ; nonisolated func searchToolbarBehavior(_ behavior: SearchToolbarBehavior) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** static var automatic, static var minimize
- **Doc:** https://developer.apple.com/documentation/swiftui/searchtoolbarbehavior
- **Skill uses it correctly:** yes
- **Notes:** `.minimize` placed after `.searchable` is correct (01:60, 05:63, patterns). Apple's own discussion sample misspells it `.minimized`. On iPhone the minimized search control sits in the bottom toolbar.

### `TabBarMinimizeBehavior`

```swift
struct TabBarMinimizeBehavior
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** static let automatic, static let never, static let onScrollDown, static let onScrollUp
- **Doc:** https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior
- **Skill uses it correctly:** yes
- **Notes:** Used correctly at 09:39 and in the pattern. onScrollDown/onScrollUp: 'Minimizing is supported for tab bars on only iPhone.'

### `ToolbarSpacer.init(_:placement:)`

```swift
nonisolated init(_ sizing: SpacerSizing = .flexible, placement: ToolbarItemPlacement = .automatic)
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarspacer/init(_:placement:)
- **Skill uses it correctly:** yes
- **Notes:** `ToolbarSpacer(.fixed, placement: .topBarTrailing)` at 09:112 is correct and sits at the toolbar-builder level.

### `ToolbarContent.matchedTransitionSource(id:in:)`

```swift
nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some ToolbarContent
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/toolbarcontent/matchedtransitionsource(id:in:)
- **Skill uses it correctly:** NO
- **Notes:** Not used. glass-modal-sheet.md presents its sheet from a toolbar button but only demonstrates the View-level source.

### `View.presentationBackgroundInteraction(_:)`

```swift
nonisolated func presentationBackgroundInteraction(_ interaction: PresentationBackgroundInteraction) -> some View
```

- **Availability:** iOS 16.4+, iPadOS 16.4+, Mac Catalyst 16.4+, macOS 13.3+, tvOS 16.4+, visionOS 1.0+, watchOS 9.4+
- **Members:** PresentationBackgroundInteraction .enabled(upThrough:) used in sample
- **Doc:** https://developer.apple.com/documentation/swiftui/view/presentationbackgroundinteraction(_:)
- **Skill uses it correctly:** NO
- **Notes:** glass-modal-sheet.md:86 pairs `.enabled(upThrough: .medium)` with detents [.large] only, so interaction is never enabled. Apple's sample includes the threshold detent in the set.

### `View.scrollContentBackground(_:)`

```swift
nonisolated func scrollContentBackground(_ visibility: Visibility) -> some View
```

- **Availability:** iOS 16.0+, iPadOS 16.0+, Mac Catalyst 16.0+, macOS 13.0+, visionOS 1.0+, watchOS 9.0+ (no tvOS)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/scrollcontentbackground(_:)
- **Skill uses it correctly:** NO
- **Notes:** Hides the system background of List and Form. It has no effect on the plain ScrollView in glass-modal-sheet.md:42.

### `State() macro`

```swift
@attached(accessor, names: named(init), named(get), named(set)) @attached(peer, names: prefixed(`_`), prefixed(__), prefixed(`$`)) macro State()
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+ (macro when building with Xcode 27; 'When you build with Xcode 26 or earlier, the system uses the State property wrapper instead.')
- **Doc:** https://developer.apple.com/documentation/swiftui/state()
- **Skill uses it correctly:** yes
- **Notes:** No example matches a TN3211 break: no init assignment, no composed wrappers, no extension calls to a private memberwise init. All state values are value types.

### `ContentBuilder`

```swift
typealias ContentBuilder = ViewBuilder
```

- **Availability:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+ (Xcode 27)
- **Doc:** https://developer.apple.com/documentation/swiftui/contentbuilder
- **Skill uses it correctly:** yes
- **Notes:** The unified replacement for ToolbarContentBuilder and CommandsBuilder, with no conformance enforced inside the builder. The examples' @ViewBuilder helpers and toolbar closures are unaffected. The only TN3211-adjacent code is the deprecated non-builder overlay/background.

