# verify:audit-code#1

_Phase: Verify — independent re-check of findings from [audit-code](audit-code.md)_

## Finding 0 — **CONFIRMED**

> Variation 'Search field in the bottom toolbar' nests `DefaultToolbarItem(kind: .search, placement: .bottomBar)` inside `ToolbarItem(placement: .bottomBar) { … }`. references/01-api-reference.md:421-423 has the identical nesting, so pattern and reference agree, and both are wrong.

- **Established truth:** patterns/glass-search-field.md:59-61 and references/01-api-reference.md:421-423 both nest `DefaultToolbarItem(kind: .search, placement: .bottomBar)` inside `ToolbarItem(placement: .bottomBar) { }`. That does not type-check.
- DefaultToolbarItem: DocC gives `nonisolated struct DefaultToolbarItem`, and its only 'Conforms To' entry is ToolbarContent.
- ToolbarItem: declared `nonisolated struct ToolbarItem<ID, Content> where Content : View`. In the current (iOS 27) SDK its initializer is `nonisolated init(placement: ToolbarItemPlacement = .automatic, @ContentBuilder content: () -> Content)`, 'Available when ID is () and Content conforms to View.'
- ContentBuilder: declared `typealias ContentBuilder = ViewBuilder`. DocC says 'In its build functions, ContentBuilder doesn't enforce protocol conformance' (Xcode 27), but ToolbarItem's own `Content : View` requirement still rejects DefaultToolbarItem.
- Correct form: DocC (`init(kind:placement:)`) and the WWDC25-323 'Toolbar items with flexible spacing' sample put `DefaultToolbarItem(kind: .search, placement: .bottomBar)` directly in `.toolbar { }`, between ToolbarItems and ToolbarSpacers. There, 'If the system has already placed a matching item kind in the toolbar, using a valid DefaultToolbarItem created by this initializer will implicitly replace the default-placed instance. You can use this to move default item kinds to other ToolbarItemPlacements, or to reposition default item kinds relative to other toolbar content.'
- Declaration: `nonisolated init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement = .automatic)`. Available iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS 26.0, none beta or deprecated.
- **Evidence:** https://developer.apple.com/documentation/swiftui/defaulttoolbaritem/init(kind:placement:)
- **Notes:** Primary sources (all apple-doc unless marked):
- swiftui/defaulttoolbaritem.json
- swiftui/defaulttoolbaritem/init(kind:placement:).json
- swiftui/toolbaritem.json
- swiftui/toolbaritem/init(placement:content:).json
- swiftui/contentbuilder.json
- updates/swiftui.json, June 2026 'General': 'Build your project in Xcode 27 or later to construct type-agnostic content from closures that you mark with ContentBuilder…'
- WWDC25-323 code sample at 8:47 (apple-video).

There is no compiler here, so the compile failure is inferred from these documented type constraints. The pattern's prose 'This pins the search field above the tab bar' is not supported by any doc. DocC only says the item is repositioned among the bottom-bar items. That sentence is not part of this finding, but it should be rechecked when the snippet is fixed.

## Finding 1 — **CONFIRMED**

> 'Multiple chips on one cover' calls `Text("New").chipStyle()` and `Text("Featured").chipStyle().tint(.orange)`.

- **Established truth:** patterns/glass-card-stack.md:80-81 call `Text("New").chipStyle()` and `Text("Featured").chipStyle().tint(.orange)`, so the snippet fails with "value of type 'Text' has no member 'chipStyle'".
- Not in the skill: grep finds `chipStyle` only at those two lines, never defined.
- Not in SwiftUI: /documentation/swiftui/view/chipstyle() returns 404, and the June/September 2026 updates sections mention no chip API.
- The documented way to color glass is `Glass.tint(_:)`, declared `func tint(_ color: Color?) -> Glass`, used as `.glassEffect(.regular.tint(.orange))`. Availability: iOS, iPadOS, Mac Catalyst, macOS, tvOS, watchOS 26.0; visionOS is not listed. Apple's 'Applying Liquid Glass to custom views' article uses only this form, and so does skill §2.
- None of these pages say the view tint modifier tints a glassEffect surface: glassEffect(_:in:), Glass, the Applying Liquid Glass article, and View.tint(_:) (Color? overload iOS 15.0; ShapeStyle overload iOS 16.0). The words 'glass' and 'Glass' never appear on the View.tint pages. So `.chipStyle().tint(.orange)` is not a documented way to tint the chip's glass.
- **Evidence:** https://developer.apple.com/documentation/swiftui/glass/tint(_:)
- **Notes:** Apple docs don't describe runtime behavior here either way, so 'unlikely to turn orange' is the finding's inference, not something the docs state.

Suggested fix: define the helper in the pattern, e.g. `func chip(tint: Color? = nil) -> some View { padding(.horizontal, 10).padding(.vertical, 6).glassEffect(.regular.tint(tint)) }`, and call `.chip(tint: .orange)`.

Side note: skill §2 (01-api-reference.md:72) declares `func tint(_ color: Color) -> Glass` with a non-optional parameter, but DocC has `Color?`.

Sources (apple-doc): swiftui/glass.json, swiftui/glass/tint(_:).json, swiftui/view/tint(_:).json, swiftui/view/tint(_:)-93mfq.json, swiftui/applying-liquid-glass-to-custom-views.json.

## Finding 2 — **CONFIRMED**

> Gotcha: 'If the chip wraps to two lines, switch to `.rect(cornerRadius: .containerConcentric)`'. 01-api-reference.md §12 (lines 466/475) uses the same spelling.

- **Established truth:** `.rect(cornerRadius: .containerConcentric)` is not valid. It appears at glass-card-stack.md:92 and 01-api-reference.md:466/475.
- `Shape.rect(cornerRadius:style:)` is `@export(implementation) static func rect(cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) -> Self` (iOS 13.0+, Self == RoundedRectangle). It takes a CGFloat.
- No `containerConcentric` member exists. Shape's 13 'Getting rectangles' members contain no 'concentric' text at all. Edge.Corner.Style's only members are `concentric`, `concentric(minimum:)` and `fixed(_:)`.
- The iOS 26 concentric API is Edge.Corner.Style, used through `ConcentricRectangle` or `Shape.rect(corners:isUniform:)`. The latter is declared `@export(implementation) static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self`. All of these are available on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS 26.0.
- Concentric radii resolve against a container shape. In custom views that shape is set with `containerShape(_:)`: 'Sets the container shape to use for any container relative shape or concentric rectangle within this view' (`nonisolated func containerShape(_ shape: some RoundedRectangularShape) -> some View`, 26.0).
- The card only applies `.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))`, and clipShape's docs never mention container shapes. So a correct fix also needs `.containerShape(RoundedRectangle(cornerRadius: 24))` on the card. It probably also needs `.concentric(minimum:)`, because DocC warns that a corner far from the container's corners can get a calculated radius that 'may be zero'.
- **Evidence:** https://developer.apple.com/documentation/swiftui/edge/corner/style
- **Notes:** Sources (apple-doc):
- swiftui/shape/rect(cornerradius:style:).json
- swiftui/shape/rect(corners:isuniform:).json
- swiftui/edge/corner/style.json
- swiftui/shape.json (topics)
- swiftui/concentricrectangle.json
- swiftui/view/containershape(_:).json
- swiftui/view/clipshape(_:style:).json
- updates/swiftui.json: no concentric or corner changes in June or September 2026.

The wrong spelling is used throughout the skill, not just in §12. It also appears in:
- SKILL.md:87 (Golden rule 4)
- references/02-hig-principles.md:20, 27, 82, 154
- references/03-design-tokens.md:13, 18, 152
- references/07-anti-patterns.md:154 (the 'Right' example of anti-pattern #6)
- checklists/pre-ship-checklist.md:26

All of these need the same correction.

## Finding 3 — **CONFIRMED**

> `.sharedBackgroundVisibility(.hidden)` is applied to the Button inside `ToolbarItem { … }`. No pattern or example shows the correct form.

- **Established truth:** 01-api-reference.md:347-350 apply `.sharedBackgroundVisibility(.hidden)` to the Button inside `ToolbarItem { }`, which does not compile.
- The modifier exists only on ToolbarContent: `nonisolated func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent`. Availability: iOS, iPadOS, Mac Catalyst, macOS 26.0; tvOS, visionOS and watchOS are not listed.
- /documentation/swiftui/view/sharedbackgroundvisibility(_:) returns 404, so there is no View overload.
- Button is not in ToolbarContent's 'Conforming Types' list: DefaultToolbarItem, EmptyView, ForEach, Group, ToolbarItem, ToolbarItemGroup, ToolbarOverflowMenu, ToolbarSpacer, ToolbarTitleMenu, TupleContent.
- Correct form, as in the DocC sample (`ToolbarItem(placement: principal) { BuildStatus() }.sharedBackgroundVisibility(.hidden)`) and the WWDC25-323 'Hide shared glass background' sample (`ToolbarItem { ProfileButton() }.sharedBackgroundVisibility(.hidden)`): apply it to the ToolbarItem.
- DocC: 'Hiding the effect will cause the item to be placed in its own grouping.'
- grep confirms no pattern or example in the skill uses the modifier, so nothing in the skill shows the correct form.
- **Evidence:** https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:)
- **Notes:** Sources: swiftui/toolbarcontent/sharedbackgroundvisibility(_:).json, swiftui/toolbarcontent.json (topics and conforming types), the 404 on the View path (all apple-doc), and the WWDC25-323 code sample at 9:07 (apple-video).

Xcode 27's ContentBuilder doesn't change this. Member lookup on Button fails regardless of the builder. Even if it succeeded, the result would be `some ToolbarContent`, which ToolbarItem's `Content : View` closure rejects. Note that DocC's sample prints `placement: principal` without the leading dot; real code needs `.principal`.

## Finding 7 — **PARTIALLY**

> The `activityHero` content card (activity rings and stats) is a hand-drawn translucent panel: `.fill(.white.opacity(0.08))` plus a 0.5 pt white stroke at lines 183-188, commented 'The glass panel'. `.glassEffect(.regular, in: .rect(cornerRadius: 28))` is applied on top of it. Inside sit three `statChip`s, each with its own `.glassEffect(.regular.tint(…), in: .capsule)` (line 220), and there is no GlassEffectContainer.

- **Established truth:** The code description is accurate:
- Lines 182-188 draw a RoundedRectangle (radius 28) with `.fill(.white.opacity(0.08))` and a 0.5 pt `.white.opacity(0.15)` stroke, commented '// The glass panel'.
- Line 203 wraps the whole ZStack in `.glassEffect(.regular, in: .rect(cornerRadius: 28))`.
- The three statChips (lines 195-197) each apply `.glassEffect(.regular.tint(tint.opacity(0.18)), in: .capsule)` (line 220), with no GlassEffectContainer.

Skill rules clearly broken:
- Golden Rule 1 (glass is for chrome, 'Not for content backgrounds').
- Checklist line 20: 'No glass on `List` rows, card bodies, hero backgrounds…'
- Checklist line 11: 'No `.glassEffect()` applied **inside** another `.glassEffect()`'
- Golden Rule 3 and checklist line 12: two or more adjacent glass elements need a container.

Overstated:
- Golden Rule 2 literally says 'Never glass-on-glass-on-glass. Maximum two layers.' The panel-plus-chip stack is two layers, so the nesting breaks the checklist, not Rule 2 as written.
- Anti-pattern #12 is titled 'Custom blurs to imitate glass' and its example uses `.blur(radius: 20)`. This view has a translucent fill and stroke but no blur, so #12 applies only in spirit.

Apple quotes, all verbatim:
- HIG Materials: 'Don't use Liquid Glass in the content layer.' … 'Instead, use standard materials for elements in the content layer, such as app backgrounds.'
- Adopting Liquid Glass: '…avoid overcrowding or layering Liquid Glass elements on top of each other.'
- WWDC25-323: 'This grouping is essential for visual correctness. … However, glass can not sample other glass, so having nearby glass elements in different containers will result in inconsistent behavior.' The transcript has the sentences in this order; the finding reverses them. The point is about grouping nearby glass into one container.
- WWDC26-269 ('What's new in SwiftUI', in the passage on 'the 2027 releases'): 'Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint.' Apple doesn't say outright that a hard-coded white fill won't follow the slider; that is a reasonable inference.

Declaration `nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View` is confirmed. Availability: iOS, iPadOS, Mac Catalyst, macOS, tvOS, watchOS 26.0; visionOS is not listed.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials
- **Notes:** The design problem is real, and the fix direction is right: no glass on this content card, use a standard material or solid surface, and drop the nested chip glass and the faux-glass fill. Only the Rule 2 and anti-pattern #12 citations should be reworded.

Wording nit: 'glassEffect … applied on top of it' is true of modifier order only. glassEffect 'Renders a shape anchored behind a view', so the white fill actually draws over the glass material.

Sources:
- apple-other: HIG materials.json; its change log has no 2026 entries and no slider mention.
- apple-doc: technologyoverviews/adopting-liquid-glass.json.
- apple-video: WWDC25-323 transcript and WWDC26-269 transcript (refreshed look and feel chapter, 2:12).
- secondary: 9to5mac, MacRumors and Tom's Guide (all June 2026) place the slider in iOS 27 Settings > Appearance > Liquid Glass. These are leads only.

Side issue, out of scope: DocC has no glassEffect overload with an isEnabled parameter (view/glasseffect(_:in:isenabled:) returns 404, and GlassEffectContainer's See Also lists only glassEffect(_:in:)). Yet 01-api-reference.md §1 (lines 7, 16-20, 29, 51) and anti-pattern #5 (07-anti-patterns.md:127) use `isEnabled:`. Worth a separate check.

## Finding 8 — **CONFIRMED**

> `planCard` (a list of plan rows) gets a `.white.opacity(0.06)` RoundedRectangle background (311-314) plus `.glassEffect(.regular, in: .rect(cornerRadius: 24))`. Its '3 / 5' badge carries a second `.glassEffect(.regular.tint(.yellow.opacity(0.25)), in: .capsule)` inside it (line 297).

- **Established truth:** planCard (examples/09-HealthTodayScreen.swift:284-317) has a header row and a VStack of five planRow HStacks.
- Lines 311-314: `.background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.06)))`.
- Line 315: `.glassEffect(.regular, in: .rect(cornerRadius: 24))`.
- Line 297: the '3 / 5' badge carries its own `.glassEffect(.regular.tint(.yellow.opacity(0.25)), in: .capsule)`, nested inside the card's glass.

That is glass on a content card, glass inside glass, and a hand-made translucent fill. It contradicts:
- The skill's checklist line 20: 'No glass on `List` rows, card bodies, hero backgrounds, or full-screen backdrops'
- The skill's checklist line 11: 'No `.glassEffect()` applied **inside** another `.glassEffect()` (glass-on-glass)'
- HIG Materials: 'Don't use Liquid Glass in the content layer.' … 'Instead, use standard materials for elements in the content layer, such as app backgrounds.'
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials
- **Notes:** All line numbers and code match the file. Both checklist quotes are verbatim; the finding drops the bold and the parenthetical. The HIG quote is verbatim.

Minor wording issues:
- 'Custom translucent fill under the glass': because `.background` comes before `.glassEffect`, the fill is part of the content that glassEffect renders in front of its material. Visually it sits on top of the glass. This doesn't change the conclusion.
- The badge nesting is only two layers, which Golden Rule 2 literally allows ('Maximum two layers'). The checklist item, which the finding correctly cites, is what forbids it.
- 'A list of plan rows' means a VStack, not a SwiftUI List. That's fine for the checklist's 'card bodies' clause.

Adopting Liquid Glass also supports this finding: 'avoid overcrowding or layering Liquid Glass elements on top of each other.'

