# verify:audit-code#4

_Phase: Verify — independent re-check of findings from [audit-code](audit-code.md)_

## Finding 27 — **PARTIALLY**

> Tints are decorative rather than semantic:
- 05 quick actions: `.tint(.blue/.orange/.yellow)` (81-83).
- 09 FAB actions: blue, orange, yellow and pink (344-353).
- 09 metric and stat chips: a different hue per metric (220, 462).
- 09 toolbar bell: `.tint(.red)` (110).
- About 14 `.tint(.white)` and 12 translucent-white tints across 02, 03, 04, 07, 08 and 09.

- **Established truth:** Core claim confirmed. The examples use hue tints that carry no semantic meaning, which contradicts both the skill and Apple.
- 05:81-83 colors three peer, non-primary quick actions blue, orange and yellow. `.tint` on `.buttonStyle(.glass)` colors the label text and symbol, as the repo's own iOS 26 screenshot docs/screenshots/05-dashboard.png shows.
- 09:344-353 colors the FAB actions blue, orange, yellow and pink.
- 09:462 gives each metric chip its own hue.
- 09:110 tints the bell `.tint(.red)`.

These break the skill's own rules: SKILL.md golden rule 6; 03-design-tokens.md:53-54 and 02-hig-principles.md:98, which map orange and yellow to warning and caution; and 05-accessibility.md:174-175 with checklist:32.

They also break Apple's guidance:
- WWDC25-323: 'You can still tint icons with a tint modifier, but use this to convey meaning, like a call to action or next step, but not just for visual effect.'
- HIG Color, Liquid Glass color: 'Apply color sparingly to the Liquid Glass material, and to symbols or text on the material. If you apply color, reserve it for elements that truly benefit from emphasis, such as status indicators or primary actions… Refrain from adding color to the background of multiple controls.'
- HIG Buttons: 'Avoid applying a similar color to button labels and content layer backgrounds… prefer using the default monochromatic appearance of button labels.'

Contrast: 05 does not force dark mode. In the light-mode screenshot, 'Log mood' measures about 1.3:1 yellow-on-light-glass (Log water about 3.1:1, Add meal about 1.8:1), far below the skill's 4.5:1.

Corrections to the finding:
1. 'The tints are low opacity (≤0.3)' is false for most cited cases. Only the `.glassEffect` chip tints (0.18 and 0.25) and the translucent whites are ≤0.3. The 05 and 09 button tints, the bell and the 14 `.tint(.white)` are full opacity.
2. No Apple doc says `.tint` cannot recolor a badge. The badge(_:) docs say nothing about color, so drop that claim. 'Apple's badge sample uses no tint' is true.
3. The 09:220 stat chips (Move red, Exercise green, Stand cyan) match the activity-ring colors, so they work as a ring legend and are arguably semantic.
4. The 09 FAB labels set `.foregroundStyle(.white)`, so the visible effect of their `.tint` is unproven.
5. Of the 12 translucent-white tints, 11 are in 02, 03, 07, 08 and 09, and the 12th is 05:116. 04 has none. The 14 count for unconditional `.tint(.white)` is right; there are 16 including the two ternaries.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/color
- **Notes:** Primary sources:
- WWDC25-323 transcript (apple-video): tint quote checked word for word. The badge sample is `Button("Notifications", systemImage: "bell") { }.badge(modelData.notifications.count)` with no tint.
- HIG Color JSON (apple-other), last updated Dec 16, 2025: Liquid Glass color section. Also: 'Avoid using the same color to mean different things.'
- HIG Buttons JSON (apple-other), last updated Dec 16, 2025.
- The GlassButtonStyle and PrimitiveButtonStyle.glass docs say nothing about how tint applies (glass: `@export(implementation) nonisolated static var glass: GlassButtonStyle`, iOS 26.0+). So the claim that tint colors the label rests on the committed iOS 26 screenshot, not on docs.
- I measured contrast from the 414x900 downscaled PNG with WCAG relative luminance. The figures are approximate; anti-aliasing may understate the text color.
- Repo line numbers and quotes all match: SKILL.md:89; tokens:53-54; accessibility:61, 174-175; checklist:32, 58.
- The bell `.tint(.red)` is the weakest example, since a red bell could be read as a status cue, although the badge already signals status.

## Finding 30 — **CONFIRMED**

> Glass is used as decoration on content: the onboarding hero symbol (`.glassEffect(.regular.tint(.white.opacity(0.1)), in: .circle)`), the login hero symbol (08:188), the profile avatar ring (07:130), and a full-width `.glassProminent` Sign Out button inside a List row (01:52).

- **Established truth:** Confirmed. Three examples put non-interactive Liquid Glass on content:
- 03:91, the onboarding hero symbol: `.glassEffect(.regular.tint(.white.opacity(0.1)), in: .circle)`.
- 08:188, the login hero sparkles symbol: `.glassEffect(.regular.tint(.white.opacity(0.15)), in: .circle)`.
- 07:130, the profile avatar ring: `.glassEffect(.regular, in: .circle)`.

A fourth puts a functional glass control in the content layer: 01:52, a full-width (`.frame(maxWidth: .infinity)`) `.glassProminent` destructive Sign Out button in a List section row.

HIG Materials, word for word: 'Don't use Liquid Glass in the content layer. … An exception to this is for controls in the content layer with a transient interactive element like sliders and toggles; in these cases, the element takes on a Liquid Glass appearance to emphasize its interactivity when a person activates it.' Also: 'Use Liquid Glass effects sparingly. … Limit these effects to the most important functional elements in your app.'

The skill's own table (02-hig-principles.md:56) lists 'List rows, cards, hero images, body text' as no-glass, and checklist:20 says 'No glass on List rows… hero backgrounds'.

Nuance:
- The Sign Out button is a functional control, not decoration. It still breaks the content-layer rule because it is not a transient slider or toggle.
- The skill's table also marks 'Controls | Buttons' as '✅ usually', so the skill contradicts itself for this item.
- HIG Buttons separately warns against giving a destructive action primary prominence ('Don't assign the primary role to a button that performs a destructive action').
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials
- **Notes:** - HIG Materials JSON (apple-other) change log: added June 9, 2025; updated Sept 9, 2025. There is no 2026 change, so the guidance still stands for iOS 27.
- The 'Adopting Liquid Glass' technology overview (apple-doc) repeats: 'Avoid overusing Liquid Glass effects… Limit these effects to the most important functional elements in your app.'
- Repo lines checked: 03:87-91, 08:184-188, 07:123-130, 01:45-55.

## Finding 32 — **CONFIRMED**

> `SWIFT_VERSION: "5.0"`, with no SWIFT_STRICT_CONCURRENCY, SWIFT_DEFAULT_ACTOR_ISOLATION or SWIFT_APPROACHABLE_CONCURRENCY settings.

- **Established truth:** Confirmed. Gallery/project.yml:28 sets `SWIFT_VERSION: "5.0"` and sets none of SWIFT_STRICT_CONCURRENCY, SWIFT_DEFAULT_ACTOR_ISOLATION or SWIFT_APPROACHABLE_CONCURRENCY. So the examples build in Swift 5 language mode and Swift 6 data-race checking never runs.

Xcode 27 release notes, word for word: 'Xcode 27 includes Swift 6.4 and SDKs for iOS 27, iPadOS 27, tvOS 27, watchOS 27, macOS 27, and visionOS 27.' I read the full notes, including the Swift Compiler section. Nothing deprecates Swift 5 mode or changes concurrency defaults, so the setting still builds.

The quoted phrase does appear in the iOS & iPadOS 27 release notes, but only inside one SwiftUI Resolved Issue about DocumentGroup and URLDocumentConfiguration (180302015): 'With approachable-concurrency defaults that infer MainActor isolation, an unannotated nonisolated async method runs on the main actor, defeating the intent of off-main reading and writing.' It is not a general announcement of new iOS 27 defaults.

01-api-reference.md §15 lists 'Swift 6.1+', and that is stale in any case. The Xcode 26 notes say 'Xcode 26 includes Swift 6.2', so the iOS 26 SDK already needs 6.2, and Xcode 27 ships 6.4.

A code scan finds nothing obvious that would fail in Swift 6 mode: no global mutable state (06's `static var sample` is a computed property), no async, Task or Dispatch, String glassEffectIDs, and value-type @State. This is not build-verified.
- **Evidence:** https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes
- **Notes:** - Sources (apple-other): the Xcode 27 release notes JSON, read in full across two offsets; the iOS & iPadOS 27 release notes JSON, read in full; and the Xcode 26 release notes JSON overview.
- The finding's claim that users paste examples into Swift 6 targets is a plausible assumption, not verifiable.
- The remark that Swift 5 mode does not surface Swift 6 data-race errors is standard Swift language-mode behavior, not something specific to Xcode 27.

## Finding 33 — **CONFIRMED**

> `.scrollContentBackground(.hidden)` is applied to a ScrollView 'so glass shows through scrollables' (also line 60).

- **Established truth:** Confirmed. Apple DocC for `scrollContentBackground(_:)`:
- Declaration: `nonisolated func scrollContentBackground(_ visibility: Visibility) -> some View`.
- Availability: iOS 16.0, iPadOS 16.0, Mac Catalyst 16.0, macOS 13.0, visionOS 1.0, watchOS 9.0. tvOS is not listed. Nothing is beta or deprecated.
- Abstract: 'Specifies the visibility of the background for scrollable views within this view.'
- Example: 'The following example hides the standard system background of the List.'
- macOS note: 'On macOS 15.0 and later, … `List` and `Form` have the seamless appearance by default, configurable by hiding the scroll background. `ScrollView` can become seamless by making the background visible.'

In glass-modal-sheet.md:42 the modifier sits on a ScrollView that contains only a VStack of Text, with no List, Form or TextEditor. An iOS ScrollView draws no standard background, so the modifier does nothing here. The line-60 rationale, 'so glass shows through scrollables', is wrong for this snippet. The modifier only matters when the sheet's content holds a List or Form (or TextEditor).
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/scrollcontentbackground(_:)
- **Notes:** - Source: DocC JSON (apple-doc). The declaration, availability and quotes all match the finding exactly.
- The point that an iOS ScrollView has no background is inferred from the doc's List-only example and its macOS note, plus standard behavior. The doc does not state it outright for iOS.
- Related, outside this finding: 01-api-reference.md §11 applies the same modifier to sheet content, where it only helps if that content holds a List or Form.

## Finding 34 — **CONFIRMED**

> Prose next to the snippets says DefaultToolbarItem 'pins the search field above the tab bar' (66), that search 'lives in the nav bar' (4), and that the search tab 'takes prominence in the nav layer' (79). glass-tab-bar.md:85 adds that the `.search` tab 'surfaces the system search field at the top of the screen'.

- **Established truth:** Confirmed for iPhone, the skill's primary target.

WWDC25-323, word for word:
- 'Search in the toolbar places the field at the bottom of the screen, within easy reach. And on iPad and Mac, it appears in the top-trailing position of the toolbar.'
- On the search tab: 'When someone selects this tab, a search field takes the place of the tab bar, and the content of the tab is shown.'
- 'On iPad and Mac, when someone selects the search tab, the search field appears centered above your apps browsing suggestions.'

The searchToolbarBehavior(_:) docs (iOS 26.0+) also say: 'On iPhone, the search field in the bottom toolbar can be configured to appear as a button-like control when inactive.'

DefaultToolbarItem (iOS 26.0+; `nonisolated struct DefaultToolbarItem`, conforms to ToolbarContent) is documented as: 'Place this item in your toolbar to control where the system-provided item, like search, will be positioned.' Apple's sample places `DefaultToolbarItem(kind: .search, placement: .bottomBar)` among .bottomBar items with ToolbarSpacers. Nothing documents 'pins the search field above the tab bar'.

TabRole.prominent (`static var prominent: TabRole`, iOS 27.0+): 'When there are no tabs with an explicit .prominent role, then a .search role tab may receive the prominent visual treatment by default.' The June 2026 SwiftUI updates add: 'Set the TabRole.prominent role on a tab to place the tab in a separate, trailing position of the tab bar.'

So on iPhone the skill's 'lives in the nav bar' (search-field:4), 'pins the search field above the tab bar' (:66), 'takes prominence in the nav layer' (:79) and 'at the top of the screen' (tab-bar:85) are wrong. 'Nav bar' and 'top' are roughly right only on iPad and Mac.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/323/
- **Notes:** - Sources: the WWDC25-323 transcript (apple-video), fetched twice and consistent both times; DocC JSON (apple-doc) for DefaultToolbarItem, searchToolbarBehavior(_:), TabRole, TabRole.search and TabRole.prominent; and the SwiftUI updates page (apple-doc).
- The repo's own iOS 26 screenshots 01 and 05 show NavigationStack `.searchable` fields at the bottom on iPhone.
- Caveat: screenshot 09 shows TabView-level `.searchable` also putting a field at the top of the non-search Today tab, so real placement depends on configuration.
- Adjacent issue outside this finding: glass-search-field.md:58-62 and 01-api-reference.md §10 nest `DefaultToolbarItem` inside `ToolbarItem(placement: .bottomBar) { }`. DefaultToolbarItem is ToolbarContent, not a View, so it belongs directly in `.toolbar {}` as Apple's sample does. Nested this way it most likely won't compile.

## Finding 44 — **CONFIRMED**

> The README says 'Requires Xcode 26 or later' and 'Pick an iPhone simulator running iOS 26' (line 22). The committed docs/screenshots were captured from this app on iOS 26.

- **Established truth:** Confirmed. Gallery/README.md:9 says 'Requires Xcode 26 or later' and :22 says 'Pick an iPhone simulator running iOS 26'. README:4-5 says every screenshot was captured from this app, and docs/screenshots were committed on 2026-08-12, before iOS 27 shipped, consistent with the iOS 26 look.

WWDC26 session 269, 'What's new in SwiftUI', word for word:
- 'When I build and run our app, the Liquid Glass design automatically takes on its updated appearance. Apps gain this look without having to change a single line of code!'
- 'Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint.'

All nine examples use system or custom Liquid Glass, so an Xcode 27 / iOS 27 build should differ from the committed screenshots. That is an inference; I have not built it. 09's plain `.fill(.white.opacity(0.08))` (line 184) and `.fill(.white.opacity(0.06))` (line 313) are ordinary colors, not Liquid Glass, so they won't follow the slider.

TN3208 (first published 2026-06-08, updated 2026-09-14): 'When you upload an app built with the iOS 27 SDK or later, App Store Connect validates that your app's Info.plist contains at least one of the following keys: UILaunchStoryboardName, UILaunchStoryboards, UILaunchScreen, UILaunchScreens' (otherwise error ITMS-90870). The iOS & iPadOS 27 release notes say the same. The Gallery's `UILaunchScreen: {}` writes that key into Info.plist, so it passes. TN3208 does not explicitly say that an empty dictionary is enough beyond the key being present.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/269/
- **Notes:** - Sources: the WWDC26-269 page and transcript (apple-video); the TN3208 DocC JSON (apple-doc), found via the technotes index; and the iOS & iPadOS 27 release notes UIKit section (apple-other), which says 'iOS and iPadOS apps built with the 27.0 SDK or later are required to include a launch screen' (168247372).
- The transcript does not say whether the 'Liquid Glass slider' is a Settings control, though the wording implies a user setting.
- The June 2026 SwiftUI updates list no API for reading the slider value.
- That the screenshots show iOS 26 is inferred from the README and commit date; it is not stated outright.

