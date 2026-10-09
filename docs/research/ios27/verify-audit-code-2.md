# verify:audit-code#2

_Phase: Verify — independent re-check of findings from [audit-code](audit-code.md)_

## Finding 9 — **CONFIRMED**

> The form VStack(spacing: 14) stacks two or three text fields. Each applies its own `.glassEffect(.regular, in: .rect(cornerRadius: 18))` (lines 273 and 313), and none is wrapped in a GlassEffectContainer.

- **Established truth:** Correct. In examples/08-LoginScreen.swift the form VStack(spacing: 14) at line 60 holds two fields, or three in sign-up mode. Each field applies its own `.glassEffect(.regular, in: .rect(cornerRadius: 18))` (lines 273 and 313), and no GlassEffectContainer wraps them. The 'Confirm password' field is inserted with `.transition(.move(edge: .top).combined(with: .opacity))` (line 84), so it gets no glass morph. This breaks the skill's own golden rule 3 (SKILL.md:86) and its checklist item (pre-ship-checklist.md:12).

Apple sources:
- WWDC25-323, verbatim: 'To combine multiple glass elements, use the GlassEffectContainer. This grouping is essential for visual correctness.' Later in the transcript: 'However, glass can not sample other glass, so having nearby glass elements in different containers will result in inconsistent behavior. Using a glass container allows these elements to share their sampling region, providing a consistent visual result.'
- 'Applying Liquid Glass to custom views': 'Use GlassEffectContainer when applying Liquid Glass effects on multiple views to achieve the best rendering performance.'
- HIG Materials: 'Don't use Liquid Glass in the content layer… An exception to this is for controls in the content layer with a transient interactive element like sliders and toggles; in these cases, the element takes on a Liquid Glass appearance to emphasize its interactivity when a person activates it.' The page also says to use Liquid Glass effects sparingly.

Declaration: `@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View`. The full initializer in the current docs is `@MainActor @preconcurrency init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)`. It is available on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS 26.0, but not visionOS.

Caution for the fix: if you wrap the form, keep the container spacing below the 14 pt VStack spacing. Apple says a container spacing 'larger than the spacing of an interior HStack, VStack, or other layout container causes Liquid Glass effects to blend together at rest.' The HIG-preferred fix is to take the glass off these content-layer fields.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/
- **Notes:** Sources (all Apple):
- WWDC25-323 transcript (apple-video). The quoted words are verbatim, but the finding joins two passages in reverse order with an ellipsis: 'This grouping is essential…' comes before 'glass can not sample other glass…' in the transcript. The meaning is unchanged.
- GlassEffectContainer doc JSON and init(spacing:content:) doc JSON (apple-doc). The finding's init signature is the shortened form from the topics list; the full declaration has `= nil` and `@ContentBuilder`. Availability matches exactly, with no visionOS entry.
- 'Applying Liquid Glass to custom views' (apple-doc). It confirms the performance, blending and morph reasons. On transitions it says the default for inserting or removing effects inside a container is matchedGeometry, which supports the point about the confirm field.
- HIG Materials JSON (apple-other). The 'transient interactive element like sliders and toggles' exception is quoted accurately.

The code facts (line numbers, no container, the transition) and the skill's own rules were checked against the repo files.

## Finding 11 — **PARTIALLY**

> The social cluster offers `socialButton("apple.logo", label: "Apple")`, a `.buttonStyle(.glass)` tile showing the SF Symbol Apple logo over the caption 'Apple'.

- **Established truth:** The core point is right, but 'meets none of these' overstates it.

In examples/08-LoginScreen.swift:388, `socialButton("apple.logo", label: "Apple")` renders a `.buttonStyle(.glass)` tile (line 407). The tile shows the `apple.logo` SF Symbol over the caption 'Apple', with both set to `.foregroundStyle(.white)` (line 405). It works as a custom Sign in with Apple button, and it breaks the HIG in these ways:
1. 'Use only the logo artwork downloaded from Apple Design Resources; never create a custom Apple logo.' The tile uses an SF Symbol, not the downloaded artwork.
2. 'Titles. Use only Sign in with Apple, Sign up with Apple, or Continue with Apple.' The caption is just 'Apple'.
3. 'Background appearance. The overall color needs to remain black or white.' The background is glass. The finding did not cite this rule.
4. 'Use the logo file to position the Apple logo in a button; never use the Apple logo as a button.' The tile arguably breaks this too.
The HIG also states: 'App Review evaluates all custom Sign in with Apple buttons.'

Where the finding overstates:
- 'Logo and title colors. Within a button, both items must be either black or white' is met, because both are white.
- The tile is the same size as the Google and Email tiles. It is smaller than the full-width primary 'Sign In' button, so 'Make a Sign in with Apple button no smaller than other sign-in buttons, and avoid making people scroll to see the button' is at most arguably broken. The cluster also sits near the bottom of a ScrollView.

The conclusion stands: the example teaches a non-compliant button and should be replaced. Options are the system `SignInWithAppleButton` (AuthenticationServices; `@MainActor @preconcurrency struct SignInWithAppleButton`, iOS 14.0+, `init(_:onRequest:onCompletion:)`), a custom button that follows every HIG rule, or dropping the Apple tile.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
- **Notes:** Source: the HIG sign-in-with-apple JSON (apple-other). All six rules the finding quotes or paraphrases appear on the page, either verbatim ('never create a custom Apple logo', 'never use the Apple logo as a button', 'App Review evaluates all custom Sign in with Apple buttons') or as accurate paraphrases (titles, black/white colors, 'no smaller than other sign-in buttons').

The verdict is 'partially' only because of the closing sentence 'meets none of these'. The color rule is satisfied, and the size rule is met relative to the other social tiles. The skill is still wrong, and the actionable fix is unchanged.

The SignInWithAppleButton declaration and availability come from the AuthenticationServices doc JSON (apple-doc).

## Finding 12 — **CONFIRMED**

> Variation 'Tall sheet that doesn't dim background': `.presentationDetents([.large])`, `.presentationBackground(.clear)  // glass shows full background`, `.presentationBackgroundInteraction(.enabled(upThrough: .medium))`.

- **Established truth:** Correct. The variation 'Tall sheet that doesn't dim background' (patterns/glass-modal-sheet.md:80-88) does the opposite of its heading.

Background interaction: the docs for `PresentationBackgroundInteraction.enabled(upThrough:)` define the parameter as 'The largest detent at which people can interact with the view behind the presentation.' They add: 'At detents larger than the one you specify, SwiftUI disables interaction.' With `.presentationDetents([.large])`, the sheet always sits at `.large`, which is above `.medium`, so interaction behind it stays disabled. The SwiftUI pages do not mention dimming. UIKit's equivalent, `largestUndimmedDetentIdentifier`, documents the system adding 'a noninteractive dimming view underneath the sheet' at detents larger than the identifier: 'set this property to medium to add the dimming view at the large detent.' So the background stays dimmed and blocked. Apple's own sample includes the threshold detent: `.presentationDetents([.height(120), .medium, .large])` with `.presentationBackgroundInteraction(.enabled(upThrough: .height(120)))`.

Background: `presentationBackground(_:)` 'Sets the presentation background of the enclosing sheet using a shape style', so `.clear` replaces the system background instead of revealing glass. WWDC25-323: 'On iOS 26, partial height sheets are inset by default with a Liquid Glass background… When transitioning to a full height sheet, the glass background gradually transitions, becoming opaque and anchoring to the edge of the screen. If you've used the presentationBackground modifier to apply a custom background to your sheets, consider removing that and let the new material shine.' A sheet with only the `.large` detent therefore has no glass by default, and `.clear` only makes it transparent.

A correct version would use detents such as `[.medium, .large]` with `.enabled(upThrough: .medium)` and no presentationBackground. Declaration: `nonisolated func presentationBackgroundInteraction(_ interaction: PresentationBackgroundInteraction) -> some View`. Available on iOS, iPadOS, Mac Catalyst and tvOS 16.4, macOS 13.3, visionOS 1.0 and watchOS 9.4.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/presentationbackgroundinteraction(_:)
- **Notes:** Sources:
- presentationBackgroundInteraction(_:) doc JSON (apple-doc): declaration, availability and the sample code with height(120)/medium/large match the finding exactly.
- PresentationBackgroundInteraction and enabled(upThrough:) doc JSON (apple-doc): confirm the 'at or below' meaning.
- presentationBackground(_:) doc JSON (apple-doc).
- WWDC25-323 transcript (apple-video): the quote is verbatim.
- 'Adopting Liquid Glass' (apple-doc) agrees: 'When a half sheet expands to full height, it transitions to a more opaque appearance' and 'Audit the backgrounds of sheets and popovers'.

Two small nuances. First, 'dimmed' rests on UIKit's largestUndimmedDetentIdentifier docs plus the SwiftUI interaction docs; no SwiftUI page states dimming outright. Second, 'replaces the system glass' is slightly loose for a sheet with only the large detent, because the system's full-height background is opaque rather than glass. The conclusion is unaffected.

## Finding 13 — **CONFIRMED**

> `ScrollView(.horizontal, showsIndicators: false)` is used here and at examples/09-HealthTodayScreen.swift:240 and :271.

- **Established truth:** Correct. `ScrollView(.horizontal, showsIndicators: false)` appears only at examples/05-DashboardScreen.swift:47 and examples/09-HealthTodayScreen.swift:240 and :271.

Declaration: `nonisolated init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ContentBuilder content: () -> Content)`.

metadata.platforms:
- iOS, iPadOS, Mac Catalyst and tvOS: introducedAt 13.0.
- macOS: introducedAt 10.15. watchOS: introducedAt 6.0.
- All six of those: deprecatedAt '27.2', with the message 'Use the ScrollView(_:content:) initializer and the scrollIndicators(:_) modifier'. The typo is Apple's.
- visionOS: introducedAt 1.0, with no deprecatedAt.
The per-platform `deprecated` flags are false. However, the ScrollView type page's topic entry for this initializer sets `"deprecated": true`.

Replacement: `ScrollView(.horizontal) { … }.scrollIndicators(.hidden)`. `scrollIndicators(_:axes:)` is available from iOS 16.0, and `init(_:content:)` is not deprecated.

The Gallery targets iOS 26.0 (Gallery/project.yml). Swift reports a versioned deprecation only when the deployment target is at or above that version, so no warning is expected there. Projects targeting 27.2 or later will get warnings. Examples 08:116 and 09:100 already use `.scrollIndicators(.hidden)`.
- **Evidence:** https://developer.apple.com/documentation/swiftui/scrollview/init(_:showsindicators:content:)
- **Notes:** Sources (apple-doc): the init(_:showsIndicators:content:) doc JSON (platforms array quoted verbatim), the ScrollView type JSON (its topics list init(_:content:) without deprecation and the deprecated initializer with deprecated:true), and the scrollIndicators(_:axes:) doc JSON.

The finding links 'no warning at 26.0' to the deprecated flag being false. The real reason is that the deployment target (26.0) is below 27.2. That behavior comes from Swift's availability rules, which I did not re-check in Apple docs; the conclusion is the same either way.

Apple's SwiftUI updates page ('September 2026' section) does not list these deprecations. That is normal for that page and does not contradict the symbol metadata.

## Finding 14 — **CONFIRMED**

> The non-builder `.overlay(RoundedRectangle(cornerRadius: 18).stroke(…))` is used here, at 08:314 and at examples/09-HealthTodayScreen.swift:185. The non-builder `.background(RoundedRectangle(…).fill(.white.opacity(0.06)))` is used at 09:311.

- **Established truth:** Correct.

Call sites:
- The non-builder `.overlay(<View>)` form is used at examples/08-LoginScreen.swift:274 and :314 and examples/09-HealthTodayScreen.swift:185.
- The non-builder `.background(<View>)` form is used at 09:311.

Deprecation metadata:
- `nonisolated func overlay<Overlay>(_ overlay: Overlay, alignment: Alignment = .center) -> some View where Overlay : View` has deprecatedAt '27.2' on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS. The message is 'Use `overlay(alignment:content:)` instead.'
- `nonisolated func background<Background>(_ background: Background, alignment: Alignment = .center) -> some View where Background : View` has the same metadata, with the message 'Use `background(alignment:content:)` instead.'
- Both were introduced in iOS 13.0 (macOS 10.15, watchOS 6.0, visionOS 1.0). The per-platform deprecated flags are false.

TN3211 is titled 'Resolving SwiftUI source incompatibilities for State and ContentBuilder' and covers Xcode 27. Its section 'Use the closure-based forms of background and overlay for ShapeStyle expressions' says that passing a ShapeStyle expression built with opacity(_:) or blendMode(_:) to 'the deprecated, non-builder forms' produces 'error: ambiguous use of 'opacity'' or 'error: ambiguous use of 'blendMode''. The fix is the closure form.

The four call sites above pass stroked or filled shape views, not ShapeStyle expressions, so they fall outside that failure case. Their still compiling is plausible but was not checked with a compiler.

The finding misses other uses of the deprecated `.background(<View>)` form at references/07-anti-patterns.md:145, :157 and :292, and at references/02-hig-principles.md:77. By contrast, examples/06-ChatScreen.swift:147 (`.background(AnyShapeStyle…)`) and 09:572 (`.background(_:in:)`) use ShapeStyle overloads and are not affected.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/overlay(_:alignment:)
- **Notes:** Sources:
- overlay(_:alignment:) and background(_:alignment:) doc JSON (apple-doc): platform arrays and deprecation summaries quoted verbatim.
- TN3211 doc JSON (apple-doc), path documentation/technotes/tn3211-resolving-swiftui-source-incompatibilities-for-state-and-contentbuilder. The finding's paraphrase is accurate. The technote's own link text names background(alignment:content:) and overlay(alignment:content:) while calling them the 'deprecated, non-builder forms'; the meaning is clear.

Related, outside this finding: references/05-accessibility.md:73 suggests `Color.black.opacity(0.15).blendMode(.plusDarker)` as a scrim. If someone passes that directly to `.background(...)`, they would hit exactly the TN3211 ambiguity error.

## Finding 15 — **CONFIRMED**

> 'For a full-bleed image (no nav bar background), use `.toolbarBackground(.hidden, for: .navigationBar)` — items still float as glass shapes individually.'

- **Established truth:** Correct. patterns/glass-navigation-bar.md:59 uses `.toolbarBackground(.hidden, for: .navigationBar)`.

That is the Visibility overload `toolbarBackground(_:for:)-7lv0f`, declared `nonisolated func toolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View`. On iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS its metadata has deprecatedAt '27.2' and renamed 'toolbarBackgroundVisibility(_:for:)'. The per-platform deprecated flags are false, and visionOS is not marked.

The replacement is `.toolbarBackgroundVisibility(.hidden, for: .navigationBar)`, declared `nonisolated func toolbarBackgroundVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View`. It is available on iOS, iPadOS, Mac Catalyst and tvOS 18.0, macOS 15.0, visionOS 2.0 and watchOS 11.0, and is not deprecated.

Neither page mentions toolbar items floating as glass. 'Adopting Liquid Glass' says toolbars 'provide a grouping mechanism for toolbar items', with items that 'share a background' and are separated by fixed spacers. So 'individually' also conflicts with the documented behavior. The same article says: 'Reduce your use of custom backgrounds in controls and navigation elements… Prefer to remove custom effects and let the system determine the background appearance', naming NavigationStack, NavigationSplitView and toolbar(content:).

The ShapeStyle overload `toolbarBackground(_:for:)-5ybst`, used as a ❌ example at references/07-anti-patterns.md:90, is NOT deprecated.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarbackground(_:for:)-7lv0f
- **Notes:** Sources (apple-doc):
- toolbarbackground(_:for:)-7lv0f doc JSON: platforms quoted verbatim with renamed. It has no message or deprecationSummary.
- toolbarbackgroundvisibility(_:for:) doc JSON: the availability matches the finding exactly, and its discussion has no glass or Liquid Glass text.
- toolbarbackground(_:for:)-5ybst doc JSON: no deprecatedAt.
- 'Adopting Liquid Glass' (technologyoverviews) JSON: I read both halves. It never mentions toolbarBackground or toolbarBackgroundVisibility.

The finding stretches one point slightly. Hiding a bar background is not strictly 'adding a custom background', but the article's 'let the system determine the background appearance' guidance fairly covers it.

