# verify:audit-references#2

_Phase: Verify — independent re-check of findings from [audit-references](audit-references.md)_

## Finding 7 — **CONFIRMED**

> "Tinted Mode (iOS 26.1+)": "Users can globally reduce app glassiness via Settings → Accessibility → Display. The system applies the chosen opacity to all .glassEffect automatically ... verify your design still reads at maximum opacity (essentially solid)." L17 calls it a "User-controlled opacity multiplier".

- **Established truth:** The skill frames the Liquid Glass look preference as an accessibility setting, and it isn't one. Apple separates the two in HIG Materials and in Adopting Liquid Glass: "like if people choose a preferred look for Liquid Glass in their device's settings, or turn on accessibility settings that reduce transparency or increase contrast". iOS 26.1 shipped a two-way Clear/Tinted choice under Settings > Display & Brightness > Liquid Glass (secondary sources only). iOS 27 adds a slider. WWDC26 Platforms State of the Union says: "We also made it more personalizable with a new slider in settings to adjust Liquid Glass anywhere from ultra clear to fully tinted, allowing users to choose the look that works best for them." WWDC26 What's new in SwiftUI (session 269) says: "Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint." Apps need no code for this. Secondary sources put the slider at Settings > Appearance > Liquid Glass, with the midpoint as the default, replacing the Clear/Tinted buttons. Designs should be checked at both ends of the slider, not only the solid end.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/102/
- **Notes:** Apple sources (verbatim):
- WWDC26 session 102 transcript has the slider quote.
- WWDC26 session 269 transcript has the SwiftUI quote.
- The HIG Materials JSON sentence is verbatim. Its change log stops at Sept 9, 2025, so the HIG has no slider-specific update.
- Adopting Liquid Glass repeats the distinction: "people can choose a preferred look for Liquid Glass in their device's settings, or turn on accessibility settings that reduce transparency or motion".

Secondary sources only (Tom's Guide, Macworld, MacRumors, BGR, iGeeksBlog, MacObserver and others): the Display & Brightness path in 26.1, the Appearance path in 27, the default midpoint, and "replaced". support.apple.com and apple.com/newsroom could not be fetched here (DNS failure), so Apple's 26.1 release-note wording was not read directly.

The finding's last sentence, that legibility risk is greatest at the ultra-clear end, is an inference, not an Apple statement. The HIG's advice to add a dimming layer behind clear glass for legibility supports it.

The skill's L17 and L163-165 are wrong in three ways: the Settings path, the framing as an accessibility setting, and calling it an "opacity multiplier" (Apple's terms are tint and ultra clear to fully tinted). They are also out of date for iOS 27.

## Finding 8 — **CONFIRMED**

> "Solution: use system colors (.tint(.blue), .tint(.accentColor)), which Smart Invert leaves alone". L18: "Smart Invert | Glass tint inverts; background image stays".

- **Established truth:** No Apple source exempts system colors such as .tint(.blue) or .tint(.accentColor) from Smart Invert. Apple's description is that Smart Invert reverses the colors on the display except for images, media, and some apps that use dark color styles. That wording is from Apple Support HT207025 (now support.apple.com/en-us/111773), seen only through search snippets. So a system-color tint inverts like any other color. The documented per-view opt-out in SwiftUI is `nonisolated func accessibilityIgnoresInvertColors(_ active: Bool = true) -> some View`: "Sets whether this view should ignore the system Smart Invert setting." Its discussion says "Use this modifier to suppress Smart Invert in a view that shouldn't be inverted." Availability: iOS 14.0, iPadOS 14.0, Mac Catalyst 14.0, macOS 11.0, tvOS 14.0, visionOS 1.0, watchOS 7.0. The UIKit equivalent is UIView.accessibilityIgnoresInvertColors (iOS 11.0). Its docs say inversion "can have a destructive impact on images and videos" and that setting it to true affects "the view and all of its subviews".
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/accessibilityignoresinvertcolors(_:)
- **Notes:** The declaration, parameter text, discussion and the full availability table were fetched from the DocC JSON and match the finding exactly.

I checked HIG Accessibility, Color and Dark Mode, plus the UIKit doc. None of them says system colors are exempt from Smart Invert, and the HIG pages don't mention Smart Invert at all.

The Apple Support wording could not be fetched (support.apple.com fails DNS here). The search tool listed Apple Support 111773 and repeated the images/media/dark-style-apps exception, so treat that quote as secondary-confirmed.

One nuance: an app that uses a dark color style may be left uninverted, but that comes from the app's style, not from using system colors.

The skill's L175 "solution" and the matching checklist L53 ("system colors used") should be replaced with accessibilityIgnoresInvertColors guidance. The skill's L18 claim about how glass looks under Smart Invert has no Apple source either way.

## Finding 9 — **CONFIRMED**

> `GlassEffectContainer(spacing: 8) // morph aggressively — overlaps merge`. Also 03 L32 ("Distinct, non-morphing siblings | 40+ (or omit container)"), 03 L25 (spacing is the threshold within which elements "blend during transitions"), and 03 L151 ("Default morph threshold 16–24", next to L150 "nil (system optimal)").

- **Established truth:** Higher container spacing means earlier blending, so the skill has the direction backwards. The GlassEffectContainer docs say: "As shapes near one another, their paths start to blend into one another. The higher the spacing, the sooner blending begins as the shapes approach each other." Applying Liquid Glass to custom views says: "The larger the spacing value on the container, the sooner the Liquid Glass effects behind views blend together and merge the shapes during a transition. A spacing value on the container that's larger than the spacing of an interior HStack, VStack, or other layout container causes Liquid Glass effects to blend together at rest because the views are too close to each other." Spacing also controls transitions: an effect within the container's spacing gets matchedGeometry by default, and the morph happens "when the eraser's nearest edge is less than or equal to the container's spacing". So spacing: 8 is the least aggressive of the skill's values. A container spacing of 40 or more with a smaller layout gap merges siblings even at rest. To keep siblings distinct, set the container spacing no larger than the layout gap, or use separate containers. The full declaration is `@MainActor @preconcurrency init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)`. The default is nil and Apple does not say what nil does. No Apple source gives a 16–24 default. Availability: iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS 26.0, with no visionOS entry.
- **Evidence:** https://developer.apple.com/documentation/swiftui/glasseffectcontainer
- **Notes:** All quotes are verbatim from the DocC JSON for glasseffectcontainer, glasseffectcontainer/init(spacing:content:) and applying-liquid-glass-to-custom-views.

The init page has no parameter descriptions, so the skill's "nil (system optimal)" at 03 L150 is also unsourced.

The declaration the finding gives is the shortened topic-signature form. Current docs also show `= nil` and an `@ContentBuilder` attribute; the token's USR is a typealias, apparently new in the 27 SDK docs.

One wording nuance: Apple says blending at rest happens when the container spacing is LARGER than the layout spacing. The finding's "unless their layout gap is larger" blurs the case where the two are equal. Apple's own 40/40 example needs an offset before the shapes blend.

The skill's L118 (80 = distant siblings still attract) points in the correct direction.

## Finding 11 — **CONFIRMED**

> "Glass cannot sample other glass. A glass element on top of another glass element produces flat blur — the lensing effect is lost. Use GlassEffectContainer to merge them into one layer." Also 06 L57 ("you get flat blur and an extra pass") and 07 L24 ("Each layer flattens into blur ... you pay for three render passes").

- **Established truth:** WWDC25 session 323 says: "This effect is achieved by sampling content from an area larger than itself. However, glass can not sample other glass, so having nearby glass elements in different containers will result in inconsistent behavior. Using a glass container allows these elements to share their sampling region, providing a consistent visual result." It also says: "This grouping is essential for visual correctness." For glass placed on glass, the fix is not a container. WWDC25 session 219 says "always avoid glass on glass" and "When placing elements on top of Liquid Glass, avoid applying the material to both layers. Instead, use fills, transparency, and vibrancy for the top elements to make them feel like a thin overlay that is part of the material." Adopting Liquid Glass says to "avoid overcrowding or layering Liquid Glass elements on top of each other." No Apple source says nested glass produces "flat blur", loses lensing, or costs a counted number of render passes. Apple ties containers to "rendering performance" only in general terms.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/
- **Notes:** All quotes are verbatim from the transcripts of WWDC25 sessions 323 and 219.

I searched these sources and found no "flat blur", lost lensing or pass counts: WWDC25 sessions 219, 323, 356 and 284; Adopting Liquid Glass; Applying Liquid Glass to custom views; the glassEffect(_:in:) and GlassEffectContainer docs; and HIG Materials.

WWDC25 session 284 (UIKit) goes further against the skill. It says "When adding glass to an existing glass container, it adapts its appearance automatically," with sample code that puts a glass view inside a glass UIVisualEffectView's contentView.

Related problems for the fix phase:
- The skill's 02 L65 and SKILL L85 ("Maximum two glass layers... = OK") conflict with "always avoid glass on glass".
- 01-api-reference L57 repeats the "cannot sample" framing.

## Finding 13 — **CONFIRMED**

> "Instruments → Metal System Trace (Xcode 26) shows glass passes as labeled phases. Look for: 'GlassEffect: layout' ... 'GlassEffect: composite'". Checklist L62: "Metal System Trace shows one composite phase per GlassEffectContainer per frame". L153: "The Animation Hitch template".

- **Established truth:** No Apple documentation, release note or WWDC session describes "GlassEffect: layout" or "GlassEffect: composite" phases in Metal System Trace, or any phase labelled for Liquid Glass. The Instruments template and instrument is named "Animation Hitches", not "Animation Hitch". Sources: Tech Talk 10856 ("the new Animation Hitches template in Instruments"), Xcode 26.4 release notes ("recording Animation Hitches Instrument"), and Xcode 27 release notes ("Animation Hitches instrument now supports visionOS"). For SwiftUI, use the SwiftUI template with the SwiftUI instrument (Instruments 26, WWDC25 session 306), which also includes the Hangs and Hitches instruments. In Xcode 27, the Organizer's new Hitches metric "replaces the Scrolling metric in the Organizer, now displaying animation hitches for all animations in your app". WWDC26 session 258 adds: "The new hitches metric surfaces issues in more places than scrolling, like understanding how apps use Liquid Glass and SwiftUI views."
- **Evidence:** https://developer.apple.com/videos/play/tech-talks/10856/
- **Notes:** I checked these and none mentions Metal System Trace glass labels:
- Xcode 27 release notes (both parts) and Xcode 26.4 release notes
- WWDC25 session 306 and WWDC26 sessions 268 and 258 transcripts
- Tech Talks 10856 and 10857
- The "Understanding hitches in your app" article
- A web search for the exact label strings, which returned no hits

The absence is established by search, not by an Apple statement, but every relevant primary source I could reach is consistent with it.

WWDC26 session 268 is about hangs (Time Profiler, the Swift Concurrency and System Trace templates) and doesn't mention glass. The session titles 306 ("Optimize SwiftUI performance with Instruments") and 268 ("Profile, fix, and verify: Improve app responsiveness with Instruments") are correct.

The same invented guidance also appears at 06-performance L187 and checklist L62 and L65.

## Finding 15 — **CONFIRMED**

> The concentricity example: an inner `.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))` inside a card drawn with `.background(RoundedRectangle(cornerRadius: 28))` (L78) is said to compute curves "concentric with the outer container". The same pattern appears at 07 L150-158, SKILL L87 and 03 L18.

- **Established truth:** Concentric corners resolve against a container shape. That can be a view that reaches the device's rounded corners, a system-provided container such as a sheet or popover, or any view that sets containerShape(_:). The ConcentricRectangle docs say: "To allow ConcentricRectangle to resolve corner radii based on concentricity in your custom view, use containerShape(_:) to specify a container shape that implements RoundedRectangularShape." A `.background(RoundedRectangle(cornerRadius: 28))` does not declare a container shape, so the inner corners do not follow the 28 pt card. Far from the container's corners, "the corner radius the system calculates may be zero", and concentric(minimum:) guards against that. The containerShape(_:) docs show the correct pattern: `.containerShape(shape).background(shape.fill(.background))`. The relevant declaration is `nonisolated func containerShape(_ shape: some RoundedRectangularShape) -> some View`, iOS 26.0+. The skill's spelling `.rect(cornerRadius: .containerConcentric)` does not exist: rect(cornerRadius:style:) takes a CGFloat, Shape has no rect(corner:), and nothing is named containerConcentric. Edge.Corner.Style has only concentric, concentric(minimum:) and fixed(_:). The correct form is `.glassEffect(.regular, in: .rect(corners: .concentric(minimum: 12), isUniform: true))` or ConcentricRectangle(), with the card setting `.containerShape(RoundedRectangle(cornerRadius: 28))`. The declaration is `static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self`. ConcentricRectangle is available on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS 26.0.
- **Evidence:** https://developer.apple.com/documentation/swiftui/concentricrectangle
- **Notes:** Fetched from the DocC JSON: concentricrectangle, view/containershape(_:), shape (all 12 rect( entries, none of them rect(corner:)), shape/rect(corners:isuniform:) and edge/corner/style.

The WWDC25 session 323 page sample `.rect(corner: .containerConcentric)` is a pre-release spelling that is not in the shipping docs.

WWDC25 session 356 supports the fallback approach: "use a concentric shape with a fallback radius."

Nuance: 03 L13 ("Card inside a sheet") would resolve correctly against the sheet, which is a system container, once the spelling is fixed. The missing containerShape problem applies specifically to the `.background(RoundedRectangle)` card pattern at 02 L76-83 and 07 L150-158, and to the general rules at SKILL L87 and 03 L18.

Other `.containerConcentric` occurrences to fix: 01 L466 and L473-475; 02 L20, L27 and L154; 03 L152; patterns/glass-card-stack.md L92; checklist L26.

