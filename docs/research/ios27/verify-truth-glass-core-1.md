# verify:truth-glass-core#1

_Phase: Verify — independent re-check of findings from [truth-glass-core](truth-glass-core.md)_

## Finding 0 — **CONFIRMED**

> Section 1 is titled `.glassEffect(_:in:isEnabled:)` and declares `func glassEffect() -> some View` plus `func glassEffect<S: Shape>(_ glass: Glass = .regular, in shape: S = DefaultGlassEffectShape, isEnabled: Bool = true)`; param table row (line 29) documents isEnabled; example line 51 `.glassEffect(.regular, in: .circle, isEnabled: highlighted)`.

- **Established truth:** SwiftUI has exactly one glassEffect modifier: `nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View`. Its symbol ID is `s:7SwiftUI4ViewPAAE11glassEffect_2inQrAA5GlassV_qd__tAA5ShapeRd__lF`, which encodes only the labels `_` and `in`. It has no `isEnabled` parameter, and there is no separate zero-argument overload: `.glassEffect()` is this same method using both defaults. The default shape is the struct `DefaultGlassEffectShape`, passed as an instance `DefaultGlassEffectShape()`. Its abstract says: 'The default shape applied by glass effects, a capsule.' The method's Discussion says: 'SwiftUI uses the regular variant by default along with a Capsule shape.' It is available on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS 26.0, and not on visionOS. The skill gets these wrong: the section 1 title, both declarations (including the generic `S = DefaultGlassEffectShape` default), the `isEnabled` table row on line 29, and the example on line 51, which will not compile against the release SDK.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Notes:** apple-doc: fetched the symbol's DocC JSON. Its declarations array has no 'isEnabled' token, and the page has no otherDeclarations or deprecationSummary. The pages glasseffect(_:in:isenabled:).json and glasseffect().json both return 404. The see-also group 'Styling views with Liquid Glass' lists only glassEffect(_:in:). The June 2025 entry on the SwiftUI updates page links View/glassEffect(_:in:). The June 2026 and September 2026 (iOS 27) sections have no glass changes. The 'Applying Liquid Glass to custom views' article never mentions isEnabled.

apple-other (Apple Developer Forums): thread 787661 (June 2025) shows the compiler error "'glassEffect(_:in:isEnabled:)' is unavailable in visionOS" in visionOS 26 beta 1. So isEnabled was a real early-beta signature that the skill copied. Thread 792899 (July 2025) reports 'Symbol not found' for the two-label symbol on a mismatched beta, which fits the signature changing during the betas.

secondary: a third-party grep of SwiftUICore.swiftinterface (July 2026) shows a single `func glassEffect` line with no isEnabled.

Not compiled here, since there is no Swift toolchain on Linux.

## Finding 1 — **CONFIRMED**

> Anti-pattern #5 'Right' block: `.glassEffect(.regular, isEnabled: visible)` (line 124 says 'use `isEnabled` or `.identity`').

- **Established truth:** `.glassEffect(.regular, isEnabled: visible)` does not compile because glassEffect(_:in:) has no isEnabled parameter. To switch glass off without changing the view tree, swap the variant: `.glassEffect(visible ? .regular : .identity)`. The abstract of `Glass.identity` (`static var identity: Glass`) says: 'When applied, your content remains unaffected as if no glass effect was applied.' To animate glass appearing or disappearing, insert or remove the view inside a GlassEffectContainer, change state with withAnimation, and attach `.glassEffectTransition(.materialize)`. For morphing between shapes, use glassEffectID(_:in:) with the default matchedGeometry transition. Apple's article says: 'If you prefer to have a simpler transition or to create a custom transition, use the materialize transition and withAnimation.'
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Notes:** apple-doc: verified the glassEffect(_:in:) declaration, Glass/identity, the glassEffectTransition(_:) Discussion and the 'Applying Liquid Glass to custom views' article.

The transition only acts 'when you add or remove views with these effects from the view hierarchy'. So a materialize transition on a view that is always present does nothing for an in-place toggle, and the view must actually be inserted or removed.

The docs require glassEffectID for coordinated matchedGeometry morphing, not for materialize. The finding's 'glassEffectID + materialize' combination is valid but slightly over-specified.

Apple does not document whether swapping .regular for .identity animates. Glass conforms to Equatable.

## Finding 2 — **CONFIRMED**

> Energy section: `.glassEffect(.regular, isEnabled: !isIdle)`; line 63 also says 'Hide the overlay during heavy moments (`isEnabled: false`)'.

- **Established truth:** Line 162 (`.glassEffect(.regular, isEnabled: !isIdle)`) and line 63 ('Hide the overlay during heavy moments (`isEnabled: false`)') both rely on a parameter that does not exist in glassEffect(_:in:), so the code does not compile. The valid equivalent is `.glassEffect(isIdle ? .identity : .regular)`, or removing the overlay from the hierarchy. Glass offers only `regular`, `clear`, `identity`, `tint(_:)` and `interactive(_:)`, and no member about enabling. Apple's docs only say `.identity` leaves content 'unaffected as if no glass effect was applied'. They say nothing about GPU or battery savings, so the skill's claim on line 165 about 'reclaiming GPU and battery' is not sourced from Apple.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Notes:** apple-doc: the glassEffect(_:in:) declaration and the full Glass topics list. No member name contains 'enable' except the argument of interactive(_:). Both quoted lines were confirmed in references/06-performance.md.

## Finding 3 — **CONFIRMED**

> 'Don't animate opacity on glass elements — use `.glassEffect(... isEnabled: false)` or swap to `.identity`'; line 166 'Animate glass opacity (animate `isEnabled` or swap variants)'.

- **Established truth:** Neither `nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View` nor `@MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View` has an isEnabled parameter. So `.glassEffect(... isEnabled: false)` on line 133 and 'animate `isEnabled`' on line 166 are invalid. The only isEnabled argument in the Liquid Glass API is `Glass.interactive(_ isEnabled: Bool = true) -> Glass`. It controls interactivity, not whether the glass renders, and it takes no `isEnabled:` label. There are two valid options. One is swapping to `Glass.identity`. The other is inserting or removing the view inside a GlassEffectContainer under withAnimation, with glassEffectTransition(.materialize) or the default matchedGeometry.
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Notes:** apple-doc: both modifier declarations, Glass/interactive(_:), and the article. The article says 'The system applies more than opacity changes with the available transition types.'

The 'never animate opacity on glass' rule is the skill's own guidance. It is not a rule stated in the Apple pages checked.

The finding's word 'Only' is slightly strong: you can also use the transition without IDs. The substance is correct.

## Finding 4 — **CONFIRMED**

> Section 6 '`.glassEffectTransition(_:isEnabled:)`' declares `func glassEffectTransition(_ transition: GlassEffectTransition, isEnabled: Bool = true)` and `enum GlassEffectTransition { case identity; case matchedGeometry; case materialize }`.

- **Established truth:** The declaration is `@MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View`, with no isEnabled parameter. GlassEffectTransition is `struct GlassEffectTransition`, not an enum. It conforms to Sendable and SendableMetatype but not Equatable, so it cannot be switched over. It exposes three type properties:
- `static var identity: GlassEffectTransition`: 'The identity transition specifying no changes.'
- `static var matchedGeometry: GlassEffectTransition`: 'Returns the matched geometry glass effect transition.'
- `static var materialize: GlassEffectTransition`: 'The materialize glass effect transition which will fade in content and animate in or out the glass material but will not attempt to match the geometry of any other glass effects.'

Available on iOS, iPadOS, Mac Catalyst, macOS, tvOS and watchOS 26.0, and not on visionOS.
- **Evidence:** https://developer.apple.com/documentation/swiftui/glasseffecttransition
- **Notes:** apple-doc: the GlassEffectTransition JSON (symbolKind struct, 'Type Properties' topic group) and the glassEffectTransition(_:) JSON. glasseffecttransition(_:isenabled:).json returns 404.

The article adds two points. Within the container's spacing, the default transition is matchedGeometry. Use materialize for effects that are farther apart than the spacing.

secondary: third-party SkipUI stubs still mirror `glassEffectTransition(_:isEnabled:)` and `glassEffect(_:in:isEnabled:)`. This fits the skill having copied the iOS 26 beta 1 API surface.

## Finding 5 — **CONFIRMED**

> Section 12 lists `.rect(cornerRadius: .containerConcentric)` as a shape primitive (line 466) and recommends `.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))` (lines 473-475).

- **Established truth:** The real declaration is `@export(implementation) static func rect(cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) -> Self`, available since iOS 13. Its cornerRadius is a CGFloat, so `.rect(cornerRadius: .containerConcentric)` cannot compile. No `containerConcentric` symbol exists in Shape (whose full rect(...) list was checked, and which has no `rect(corner:)`), RoundedRectangle, Edge.Corner.Style, ConcentricRectangle, or the Liquid Glass article.

The shipping API is `ConcentricRectangle` together with `@export(implementation) static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self` and its sibling `rect(...)` corner-style overloads. These are available on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS 26.0. `Edge.Corner.Style` is a struct with members `concentric`, `concentric(minimum:)` and `fixed(_:)`.

The fix is `.glassEffect(.regular, in: .rect(corners: .concentric))`, or `in: ConcentricRectangle()`. Concentricity resolves against a container shape. System views such as sheets and popovers provide one by default. Custom parents must set one with `nonisolated func containerShape(_ shape: some RoundedRectangularShape) -> some View` (iOS 26.0+).
- **Evidence:** https://developer.apple.com/documentation/swiftui/concentricrectangle
- **Notes:** apple-doc: the ConcentricRectangle overview says 'To allow ConcentricRectangle to resolve corner radii based on concentricity in your custom view, use containerShape(_:)...'. The Shape JSON was complete, not truncated, with zero 'containerConcentric' matches.

apple-video: the WWDC25 session 323 code sample at 17:27 shows `.background(.tint, in: .rect(corner: .containerConcentric))`.

apple-other: in forum thread 787615, an Apple Frameworks Engineer answered 'These APIs aren't available in the first beta release', and a user added that beta 2 didn't have them either. That pre-release spelling never shipped. The skill's `cornerRadius:` variant never existed in any form.

The same wrong API also appears in: SKILL.md:87; 02-hig-principles.md:20, 27, 82, 154; 03-design-tokens.md:13, 18, 152; 07-anti-patterns.md:154; patterns/glass-card-stack.md:92; checklists/pre-ship-checklist.md:26.

The example at 07-anti-patterns.md:150-158 also needs `.containerShape(.rect(cornerRadius: 28))` on the parent. A plain `.background(RoundedRectangle(...))` does not set a container shape.

