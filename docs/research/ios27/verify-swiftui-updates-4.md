# verify:swiftui-updates#4

_Phase: Verify — independent re-check of findings from [swiftui-updates](swiftui-updates.md)_

## Finding 19 — **CONFIRMED**

> The 'Vertical floating palette' variation positions custom vertical glass bars with no awareness of system vertical bars.

- **Established truth:** Correct. The skill's 'Vertical floating palette' variation (patterns/glass-floating-toolbar.md:54-55) only says 'Swap HStack for VStack. Same GlassEffectContainer rules apply.' It says nothing about system vertical bars.

SwiftUI now has EnvironmentValues.toolbarVerticalEdge, declared `var toolbarVerticalEdge: HorizontalEdge? { get }`. It was introduced in 27.1 on iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS, and is flagged beta only on iOS and iPadOS.
- It reflects the system's preferred edge for the vertical bar 'regardless of whether a vertical bar is currently visible'.
- It is read-only, and the system picks the edge 'based on locale and device'.
- It returns nil where the system never places a vertical bar, such as hardware without one or a size class or orientation that doesn't use one.

The HIG page 'Designing for iPhone Duo' (new on 2026-09-09) says toolbars, tab bars and navigation controls that are usually at the top and bottom move to the side. The exception is the inner display in portrait, which keeps standard horizontal bars.
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/environmentvalues/toolbarverticaledge.json
- **Notes:** Sources: apple-doc (the symbol's DocC JSON) and apple-other (HIG JSON at design/human-interface-guidelines/designing-for-iphone-duo.json).
- I checked the declaration and availability against the raw metadata JSON: externalID s:7SwiftUI17EnvironmentValuesV19toolbarVerticalEdge..., beta:true only for iOS and iPadOS.
- The finding's quotes match the abstract and discussion word for word.
- The doc's own example aligns a FloatingToolPalette to the trailing or leading edge depending on this value.
- Useful HIG lines for the rewrite: 'In general, don't override the default bar placement'; 'Account for asymmetry in your layouts... Use safe areas'; 'Locate controls near the content they affect'.
- The APIs are 27.1, not 27.0. The skill should gate them with #available(iOS 27.1, *) and label them beta.

## Finding 20 — **CONFIRMED**

> Skill assumes system bars are always horizontal (top nav bar / bottom tab bar).

- **Established truth:** Correct. The skill's toolbar section (01-api-reference.md §8, line 298) and TabView section (§9, line 355) only use top and bottom placements: .topBarLeading/.topBarTrailing, the bottom tab accessory and the bottom-toolbar search. They never mention a vertical bar.

View.toolbarVerticalBehavior(_:) is declared `nonisolated func toolbarVerticalBehavior(_ behavior: ToolbarVerticalBehavior) -> some View`. ToolbarVerticalBehavior is a struct with:
- static let automatic: 'The system determines whether the vertical bar is rendered.'
- static let disabled: 'The vertical bar is disabled.'

Both were introduced in 27.1 and are beta on iOS and iPadOS. The finding's quoted discussion is verbatim. So are the resolution rules: NavigationStack uses the top-most view, TabView the selected view, and NavigationSplitView the view in the trailing-most column. Apple also says to use toolbarVisibility(_:for:) to hide bars instead.
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/view/toolbarverticalbehavior(_:).json
- **Notes:** Sources: apple-doc (view/toolbarverticalbehavior(_:).json and toolbarverticalbehavior.json).
- The discussion adds two details not in the finding. The behavior 'is resolved by the window or presentation if placed within a sheet or form'. And a change is animated: content reflows, the status bar changes axis, and 'the leading or trailing safe area inset for the vertical bar is added or removed'. That matters for the skill's .safeAreaInset guidance.
- Apple's example applies .toolbarVerticalBehavior(.disabled) to a TabView.
- The September 2026 SwiftUI updates page lists this API under 'Controls on the vertical axis'.
- Availability is 27.1, beta on iOS and iPadOS.

## Finding 21 — **CONFIRMED**

> No per-item control over horizontal vs vertical bar placement.

- **Established truth:** Correct. Both overloads exist:
- ToolbarContent.axisBehavior(_:): `nonisolated func axisBehavior(_ behavior: ToolbarItemAxisBehavior) -> some ToolbarContent`
- CustomizableToolbarContent.axisBehavior(_:): the same, but returning `some CustomizableToolbarContent`

ToolbarItemAxisBehavior is a struct with three members:
- .automatic: 'The automatic axis behavior.'
- .horizontalOnly: 'The item only supports horizontal bars. If an item only supports horizontal bars and no horizontal bars are present, the item is not shown.'
- .verticalPreferred: 'The item supports both horizontal and vertical bars, and prefers a vertical placement when both horizontal and vertical bars are present.'

All were introduced in 27.1 and are beta on iOS and iPadOS. The HIG sentence 'Labels that include text stay in a horizontal bar, so prefer a symbol wherever one works.' is verbatim, under 'Keep text-based buttons to a minimum.' The skill has no per-item axis control.
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/toolbaritemaxisbehavior.json
- **Notes:** Sources: apple-doc (toolbarcontent/axisbehavior(_:).json, customizabletoolbarcontent/axisbehavior(_:).json, toolbaritemaxisbehavior.json) and apple-other (the iPhone Duo HIG page, checked against the raw JSON text).
- The finding's declaration covers only the ToolbarContent overload. The CustomizableToolbarContent overload returns `some CustomizableToolbarContent`.
- Apple's example: `ToolbarItem(placement: .primaryAction) { Toggle(...) }.axisBehavior(.horizontalOnly)`.
- Related HIG advice for the rewrite: 'Provide both a title and a symbol for each toolbar item that isn't text-only'; 'Group related toolbar items instead of spacing them manually' (ToolbarItemGroup adapts, so avoid fixed spacing); 'Items overflow from bottom to top by default.'

## Finding 22 — **CONFIRMED**

> No guidance on toolbar vs tab bar priority when bars share constrained space.

- **Established truth:** Correct. View.toolbarVerticalCompressionBehavior(_:) is declared `nonisolated func toolbarVerticalCompressionBehavior(_ behavior: ToolbarVerticalCompressionBehavior) -> some View`. Its abstract is verbatim: 'Sets how bars should compress when different types of toolbars are hosted together and space is constrained.'

ToolbarVerticalCompressionBehavior has three members:
- .automatic
- .prefersTabBar: 'prefers keeping the tab bar visible'
- .prefersToolbarItems: 'prefers keeping toolbar items visible'

Introduced in 27.1, beta on iOS and iPadOS. The HIG agrees with the finding:
- In navigation-focused experiences, toolbar items move into overflow so the tab bar stays. 'This is the default bar compression behavior.'
- In task-oriented experiences, the tab bar is minimized to keep toolbar actions.

The skill has no such guidance.
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/view/toolbarverticalcompressionbehavior(_:).json
- **Notes:** Sources: apple-doc (the modifier and type JSON) and apple-other (iPhone Duo HIG, checked against the raw JSON).
- Apple's example applies .toolbarVerticalCompressionBehavior(.prefersToolbarItems) inside a TabView > Tab > NavigationStack, for a Files-like app.
- Scope: the September 2026 updates page lists this under 'Controls on the vertical axis', and the HIG guidance sits under 'Vertical controls' for iPhone Duo. The HIG also links UIVerticalBarCompressionBehavior for UIKit. It says the task-oriented case 'mirrors the minimized tab bar behavior present on other iPhone devices', so on other iPhones the skill's existing tabBarMinimizeBehavior guidance still applies.
- The rewrite should not present this as a general replacement for tabBarMinimizeBehavior.

## Finding 23 — **CONFIRMED**

> New adaptive two-pane layout container (September 2026 'Arrangement views').

- **Established truth:** Correct. ArrangementView is declared `nonisolated struct ArrangementView<Primary, Secondary> where Primary : View, Secondary : View`. It appears under the 'Arrangement views' heading of the September 2026 SwiftUI updates. Every symbol in the finding exists with the stated shape:
- `nonisolated init(@ContentBuilder primary: () -> Primary, @ContentBuilder secondary: () -> Secondary)` and `init(_: ArrangementViewStyleConfiguration)`
- `nonisolated func arrangementViewStyle(_ style: some ArrangementViewStyle) -> some View`
- The ArrangementViewStyle protocol has static vars .automatic (AutomaticArrangementViewStyle, which 'resolves to a SplitArrangementViewStyle'), .split and .overlay. SplitArrangementViewStyle and OverlayArrangementViewStyle each have axes(Axis.Set).
- Custom styles implement `makeBody(configuration:)`. ArrangementViewStyleConfiguration has .primary and .secondary, which are type-erased views.
- `splitArrangementLayoutRatio(_ ratio: CGFloat?)`
- `splitArrangementLayoutRatio(minHorizontal:idealHorizontal:maxHorizontal:minVertical:idealVertical:maxVertical:)`, all CGFloat? = nil
- `splitArrangementLayoutSize(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:)`, all CGFloat? = nil
- `splitArrangementFixedLayoutSize(horizontal: Bool = true, vertical: Bool = true)`
- `overlayArrangementEdge(_ edge: HorizontalEdge?)`
- Environment values `splitArrangementAxis: Axis? { get set }` (nil outside a split arrangement) and `overlayArrangementZIndex: Int { get set }`

All are 27.1, beta on iOS and iPadOS. The HIG quote 'Keep navigation outside of arrangement views... place navigation containers like navigation split views and tab views around it rather than within it.' is verbatim.
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/arrangementview.json
- **Notes:** Sources: apple-doc. I fetched arrangementview.json and its init, arrangementviewstyle.json, automatic/split/overlay arrangementviewstyle.json, arrangementviewstyleconfiguration.json, the five view modifier pages and the two environment value pages. Apple-other: the iPhone Duo HIG 'Arrangement views' section.
- Detail not in the finding: init(primary:secondary:) uses @ContentBuilder, which I confirmed in the raw tokens. ContentBuilder is documented as `typealias ContentBuilder = ViewBuilder`, so trailing-closure usage is unchanged.
- Apple's docs disagree with themselves on one point. The updates page says overlayArrangementEdge anchors to 'a specific vertical or horizontal edge', but the declaration takes HorizontalEdge?. Trust the declaration.
- Apple's examples: `.arrangementViewStyle(.overlay)` for a player with controls over video, and `.arrangementViewStyle(.split.axes(.horizontal))`.
- HIG: consider an arrangement view when the layout already resembles one. An HStack or VStack maps to split, and a ZStack maps to overlay.

## Finding 24 — **CONFIRMED**

> No hardware-avoidance API for floating glass controls.

- **Established truth:** Correct. ReservedRegion is a struct ('A region within a view's coordinate space that another entity reserves') with these properties:
- id (ReservedRegion.ID)
- frame (CGRect, 'including the margins')
- isActive (Bool)
- kind (ReservedRegion.Kind)
- margins (EdgeInsets)

ReservedRegion.Kind has `static var occlusion` and `static var division`. The descriptions the finding quotes are verbatim from the ReservedRegion overview's term list, which pairs each Kind member with that text. ReservedRegion.QueryOptions is @frozen and has `static var includeInactive` ('Include inactive reserved regions.').

Regions are read with `func reservedRegions(kind: ReservedRegion.Kind, options: ReservedRegion.QueryOptions = [], layoutDirectionBehavior: LayoutDirectionBehavior = .mirrors) -> [ReservedRegion]` on GeometryProxy. By default the system mirrors region geometry for right-to-left layouts; pass LayoutDirectionBehavior.fixed to opt out. All are 27.1, beta on iOS and iPadOS. The skill has no hardware-avoidance API.
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/reservedregion.json
- **Notes:** Sources: apple-doc (reservedregion.json, reservedregion/kind-swift.struct.json (the plain /kind.json path returns 404), reservedregion/queryoptions.json, geometryproxy/reservedregions(kind:options:layoutdirectionbehavior:).json) and apple-other (iPhone Duo HIG 'Reserved regions').
- The Kind members' own abstracts are shorter than the overview text: 'A region that is occluded by an element.' and 'A region where content should split into two separate regions.'
- Apple's docs are inconsistent here. The overview says the method returns regions that intersect the view 'regardless of whether they are currently active', while QueryOptions.includeInactive exists to include inactive ones. The skill should pass .includeInactive explicitly when needed and check isActive.
- The HIG says the system already accounts for the outer camera when controls are on the side, and that alerts, menus, sheets and split views adapt to the fold. Use the ReservedRegion API 'to keep important elements clear of the center if the system doesn't move them automatically.'
- The September 2026 updates page also lists related APIs I did not verify in detail: onHingeChange(isEnabled:_:), DeviceHingeContext, DeviceHinge and CameraCaptureAccessory.

