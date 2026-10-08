# verify:truth-glass-core#6

_Phase: Verify — independent re-check of findings from [truth-glass-core](truth-glass-core.md)_

## Finding 39 — **CONFIRMED**

> 'Primary CTA | tint the glass (`.glassProminent.tint(.blue)`)'.

- **Established truth:** `PrimitiveButtonStyle.glassProminent` is declared `@MainActor @export(implementation) @preconcurrency static var glassProminent: GlassProminentButtonStyle { get }`. It is 26.0 on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS; visionOS is not listed. `GlassProminentButtonStyle` (`nonisolated struct GlassProminentButtonStyle`) has only two documented members: `init()` and `makeBody(configuration:)`. None of GlassProminentButtonStyle, PrimitiveButtonStyle or ButtonStyle has a `tint` member, and there is no `glassProminent(_:)` factory. So `.buttonStyle(.glassProminent.tint(.blue))` will not compile. The correct form applies the View modifier after the style: `.buttonStyle(.glassProminent).tint(.blue)`. `View.tint(_:)` is iOS 15.0+, and line 153 of the same file already uses this form. To tint a non-prominent glass button through the style, Apple documents `static func glass(_ glass: Glass) -> Self` (26.0), e.g. `.buttonStyle(.glass(.regular.tint(.blue)))`. Its doc says the style is one "you can customize by specifying a tint or variant".
- **Evidence:** https://developer.apple.com/documentation/swiftui/glassprominentbuttonstyle
- **Notes:** Sources were the DocC JSON for primitivebuttonstyle/glassprominent, glassprominentbuttonstyle, primitivebuttonstyle, buttonstyle, primitivebuttonstyle/glass(_:), glass and view/tint(_:). The finding's declaration and availability match exactly. The topics list of PrimitiveButtonStyle has `glass`, `glassProminent` and `glass(_:)`, with no `tint`. The `Glass` struct does have `tint(_:)`, but `.glassProminent` is a button style, not a `Glass` value. Line 64 is inside a prose table, so this is a compile risk when copied, not a broken code sample. No Apple sample shows `.glassProminent` followed by `.tint`. The glassProminent page calls it "similar to the borderedProminent style", and the View.tint(_:) doc uses borderedProminent buttons as its tint example. That supports the proposed fix but does not state it outright.

## Finding 40 — **CONFIRMED**

> The skill presents iOS 26 / Xcode 26 / WWDC25 as current and says nothing about the 27 releases.

- **Established truth:** The skill references only iOS 26, Xcode 26 and WWDC25: SKILL.md lines 10 and 37, 01-api-reference.md lines 3 and 533, 06-performance.md line 147, pre-ship-checklist.md line 84, and the 'Requires: Xcode 26+, iOS 26+' headers in the examples. No file under skills/liquid-glass mentions the 27 releases.

Apple's SwiftUI Updates page (sections: September 2026, June 2026, June 2025 and older) has no Glass, glassEffect, GlassEffectContainer, glass button style or ConcentricRectangle entries in either 2026 section. Its only Liquid Glass entries are under June 2025.

WWDC26 session 102 (Platforms State of the Union) contains these lines verbatim:
- "To maintain exceptional readability, we tuned Liquid Glass so it more effectively diffuses complex content behind it."
- "…we also introduced a darkened edge along with brighter specular highlights. We also made it more personalizable with a new slider in settings to adjust Liquid Glass anywhere from ultra clear to fully tinted…"
- "Apps already using Liquid Glass get these improvements automatically when they run on this year's releases without even needing to recompile."
- "We'll be removing support for opting to use the old design. So once your app is recompiled with Xcode 27, it will automatically begin to use the new design with Liquid Glass."

The UIDesignRequiresCompatibility doc agrees: "The system ignores this key when you build for iOS 27 or later, iPadOS 27 or later, Mac Catalyst 27 or later, macOS 27 or later, or tvOS 27 or later."

`ContentBuilder` is documented as a type alias, `typealias ContentBuilder = ViewBuilder`, with availability iOS/iPadOS/Mac Catalyst 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0 and visionOS 1.0. The June 2026 updates say: "Build your project in Xcode 27 or later to construct type-agnostic content from closures that you mark with ContentBuilder, which serves as the unified replacement for type-specific builders like ToolbarContentBuilder and CommandsBuilder."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/102/
- **Notes:** All sub-claims check out. Two caveats:
1. The Updates page does not list every 27.0 symbol. `GeometryProxy.concentricCornerRadii` (`var concentricCornerRadii: RectangleCornerRadii? { get }`) is 27.0 on all platforms, visionOS included, and is not on the Updates page. "No new glass-material or ConcentricRectangle API" holds; "nothing concentric changed in 27" would not.
2. June 2026 also adds chrome APIs that affect the system glass bars: TabRole.prominent, toolbarMinimizationBehavior(_:for:), ToolbarOverflowMenu, ToolbarItemPlacement.topBarPinnedTrailing and ToolbarContent.visibilityPriority(_:). Any iOS 27 note in the skill should mention them.

Sources: updates/swiftui.json (searched every 'lass', 'oncentric' and 'ContentBuilder' hit in the first 100k characters, which hold all of the 2026 sections and June 2025), swiftui/contentbuilder.json, the uidesignrequirescompatibility doc JSON, and the WWDC26/102 page transcript.

## Finding 41 — **PARTIALLY**

> `.glassEffectTransition(.matchedGeometry)  // default with glassEffectID`.

- **Established truth:** Apple's article 'Applying Liquid Glass to custom views' says: "For effects you want to add or remove that are positioned within the container's assigned spacing, the default transition type is matchedGeometry." It also says "If you prefer to have a simpler transition or to create a custom transition, use the materialize transition and withAnimation", and "Use the materialize transition for effects you want to add or remove that are farther from each other than the container's assigned spacing."

The `GlassEffectTransition.matchedGeometry` page (`static var matchedGeometry: GlassEffectTransition { get }`; 26.0 on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS) explains that geometry is "derived from the geometry of a nearby shape within the glass container": "if a newly appearing shape is within the spacing of any existing shape, it will use that shapes geometry to transition out of."

So the skill is right that `.matchedGeometry` is the default. It is wrong to make the default depend on `glassEffectID`; Apple makes it depend on the container's spacing. A correct line 103 comment would be `// default for effects within the container's spacing`. Line 107 also uses a different rule than Apple. It reserves `.materialize` for elements with "no corresponding source", while Apple says to use it for effects farther apart than the container spacing, or for a simpler or custom transition.
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views
- **Notes:** The finding's Apple quote, declaration and availability are correct and verbatim. Calling the skill line "factually-wrong" goes too far: Apple does call matchedGeometry the default, as the skill does. Only the "with glassEffectID" condition is unsupported, which makes the line imprecise rather than false. The `View.glassEffectTransition(_:)` page and the `GlassEffectTransition` type page name no default; only the article does. The word "default" in the matchedGeometry page's discussion refers to `Animation.default` (extra scale and offset effects), not the default transition. The materialize abstract is: "fade in content and animate in or out the glass material but will not attempt to match the geometry of any other glass effects." The WWDC25 session 323 transcript never mentions matchedGeometry, materialize or glassEffectTransition.

## Finding 42 — **CONFIRMED**

> Quantified cost claims: 'GlassEffectContainer of N children ≈ cost of one glass effect' (line 21), '1 container of 5 children is ~5× cheaper' (line 25), Instruments phases named 'GlassEffect: layout' / 'GlassEffect: composite' (line 148), and checklists/pre-ship-checklist.md:62 'Metal System Trace shows one composite phase per GlassEffectContainer'.

- **Established truth:** No Apple source supports any of these:
- the ratios "GlassEffectContainer of N children ≈ cost of one glass effect" (06-performance.md:21) and "~5× cheaper" (:25);
- the Instruments phase names "GlassEffect: layout" (:148) and "GlassEffect: composite" (:149);
- "Metal System Trace shows one composite phase per GlassEffectContainer" (pre-ship-checklist.md:62).
They should be removed.

Apple says more than the finding's "Apple only states", but all of it is qualitative:
- Applying Liquid Glass to custom views: "Use GlassEffectContainer when applying Liquid Glass effects on multiple views to achieve the best rendering performance." and "Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance. Limit the use of Liquid Glass effects onscreen at the same time." Both quotes are verbatim.
- GlassEffectContainer overview: "SwiftUI renders the effects together, improving rendering performance and allowing the effects to interact with and morph into one another."
- NSGlassEffectContainerView tip (AppKit, macOS 26.0): "Using a glass effect container view can improve performance by reducing the number of passes required to render similar glass effect views."
- UIGlassContainerEffect: "renders multiple glass elements into a combined effect."
- Adopting Liquid Glass: "Combine custom Liquid Glass effects to improve rendering performance."

The skill can keep the claim that containers render effects together and need fewer passes, citing these pages. It should drop the numbers and the phase names, and point to general profiling (the Hitches and SwiftUI instruments) instead.
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views
- **Notes:** I tried to refute the finding and could not. None of these sources contains a numeric glass-cost figure or a glass-labeled Instruments phase or track:
- doc JSON for the SwiftUI article, swiftui/glasseffectcontainer, appkit/nsglasseffectcontainerview and uikit/uiglasscontainereffect;
- the HIG Materials page (its change log has no 2026 entry);
- Adopting Liquid Glass, all 151k characters including references;
- transcripts of WWDC25 219, 306 (SwiftUI instrument lanes: Update Groups, Long View Body Updates, Long Representable Updates, Other Long Updates) and 323, and WWDC26 258 and 268;
- web searches for the exact phase strings.
The only WWDC26 glass and performance line is in session 258: "The new hitches metric surfaces issues in more places than scrolling, like understanding how apps use Liquid Glass and SwiftUI views."

I kept the verdict at confirmed because the core claim holds. Two corrections to the finding: its "Apple only states" leaves out the GlassEffectContainer and AppKit statements, which back the skill's qualitative batching wording, and "GlassEffect: composite" is on line 149, not 148.

Other URLs: https://developer.apple.com/documentation/swiftui/glasseffectcontainer and https://developer.apple.com/documentation/appkit/nsglasseffectcontainerview

