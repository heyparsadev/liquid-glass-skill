# design-platform

_Phase: Research_

## Summary

I checked the skill against Apple's own sources, read through the developer.apple.com DocC JSON endpoints: the HIG pages and their change logs, the What's New page, Technology Overviews, the UIKit/AppKit/SwiftUI updates pages, the iOS 27 and Xcode 27 release notes, the Xcode support matrix, Apple Developer News, and the WWDC26 Keynote (101), Platforms State of the Union (102) and sessions 269, 278, 289, 292, 251, 220, 258, 260, plus the iPhone Duo tech talk 111462. apple.com, support.apple.com and news sites failed DNS resolution in this environment, so details of the consumer setting come only from search-result summaries and are labelled secondary.

Main changes in 26.x to 27:
1. **The old design can no longer be kept.** `UIDesignRequiresCompatibility` is ignored when you build for iOS/iPadOS/macOS/tvOS/Mac Catalyst 27 or later. The State of the Union said: "once your app is recompiled with Xcode 27, it will automatically begin to use the new design". From April 2027, iOS apps uploaded to App Store Connect must be built with the iOS 27 SDK.
2. **Liquid Glass looks different.** It diffuses complex content more, and has a darkened edge and brighter specular highlights. Apps get this automatically, even without recompiling.
3. **New user setting.** A Settings slider runs "from ultra clear to fully tinted" and replaces the iOS 26.1 Clear/Tinted choice. Standard glass responds to it automatically. I found no public API in SwiftUI `EnvironmentValues` or UIKit `UITraitCollection` to read it.
4. **Scroll edge effect changed.** In iOS 27, `.automatic` no longer switches between soft and hard; it has its own look, and a uniform top bar appears when content scrolls under floating bars. Apps that forced `.soft` no longer match the system. The HIG (June 8, 2026) now says to prefer automatic. The skill doesn't cover scroll edge effects at all.
5. **HIG updates relevant to glass:**
   - Design principles reintroduced as eight new principles (June 2026).
   - Branding (Sep 2026): put brand color in the content layer.
   - Sheets (Mar 2026): new button-placement rules.
   - Search fields and Tab bars (June 2026): search tab can be a standard tab or a button appearance; new `TabRole.prominent` in iOS 27.
   - Sidebars and App icons updated (June 2026).
   - New "Designing for iPhone Duo" page (Sep 2026): toolbars and tab bars move to a vertical bar on the side. iPhone Duo ships Oct 23, 2026 with iOS 27.1.
6. **Accessibility API changes:**
   - `accessibilityShowButtonShapes` is renamed `accessibilityShowBorders`; macOS 27 adds a separate Show Borders setting.
   - `accessibilityReduceHighlightingEffects` (Reduce Bright Effects) is new in iOS 26.4.
   - Xcode 27 previews add Control Borders and Color Scheme Contrast overrides.
7. **Toolchain:** Xcode 27 includes Swift 6.4 and needs macOS Tahoe 26.6 or later; deployment targets go back to iOS 15. Xcode 26 shipped with Swift 6.2, not the 6.1 the skill states.
8. **Devices:** iOS 27 supports iPhone 11 and every model iOS 26 supports (Keynote).
9. **visionOS:** the Liquid Glass SwiftUI APIs (`Glass`, `glassEffect`, `GlassEffectContainer`, `.glass` button style) list no visionOS availability, yet the skill claims visionOS 26+.

Separate from 27, the skill has several long-standing conflicts with Apple guidance:
- It allows two stacked glass layers; Apple says "always avoid glass on glass".
- It bans standard materials outright; the HIG says to use them in the content layer.
- It describes Reduce Transparency, Increase Contrast and Reduce Motion behavior inaccurately.
- Its contrast table doesn't match the HIG's.
- It omits the dimming-layer rule for clear glass.
- Its brand-color advice ("tint the label") conflicts with the HIG.
- It puts glass chips in the content layer in list cards.
- It recommends fixed toolbar spacers.
- It cites the wrong WWDC25 session number (356 is "Get to know the new design system", not 284).
- Its performance numbers and Instruments phase names can't be verified.

Rumors and beta-era reports (slider location Settings > Appearance > Liquid Glass, how fine-grained it is, the iPhone SE list) are marked low/medium and secondary.

## Findings (35)

### 0. `platform-requirement` — Skill has no guidance on UIDesignRequiresCompatibility / compatibility mode; Build section assumes Xcode 26 and treats Liquid Glass adoption as optional.  
_checklists/pre-ship-checklist.md:81_

- **Correct / new info:** Apple doc for the Info.plist key (Boolean, iOS/iPadOS/macOS/tvOS 26.0, not deprecated): Warning "Temporarily use this key while reviewing and refining your app's UI for the design in the latest SDKs." ... "The system ignores this key when you build for iOS 27 or later, iPadOS 27 or later, Mac Catalyst 27 or later, macOS 27 or later, or tvOS 27 or later." WWDC26 Platforms State of the Union (102): "We'll be removing support for opting to use the old design. So once your app is recompiled with Xcode 27, it will automatically begin to use the new design with Liquid Glass." Note: the Technology Overviews article 'Adopting Liquid Glass' still advises adding the key and has not been updated for 27.
- **Availability:** iOS 26.0+, iPadOS 26.0+, macOS 26.0+, tvOS 26.0+ (ignored when building for 27 or later)
- **Evidence:** https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility (apple-doc, confidence high)
- **Action:** Add a 'Migration / compatibility mode' section: UIDesignRequiresCompatibility is ignored when you build with the 27 SDKs, so every app rebuilt with Xcode 27 gets Liquid Glass. Tell Claude not to suggest the key as a long-term opt-out.

```swift
UIDesignRequiresCompatibility (Boolean Info.plist key)
```

### 1. `platform-requirement` — "Built with Xcode 26+" / IPHONEOS_DEPLOYMENT_TARGET = 26.0  
_checklists/pre-ship-checklist.md:84_

- **Correct / new info:** Apple Developer News (Sept 9, 2026): "Starting April 2027, apps and games uploaded to App Store Connect need to meet the following minimum requirements: iOS and iPadOS apps must be built with the iOS 27 & iPadOS 27 SDK or later" (same for tvOS 27, visionOS 27, watchOS 27 SDKs). Because UIDesignRequiresCompatibility is ignored for 27-SDK builds, this makes Liquid Glass effectively mandatory for all App Store submissions from April 2027.
- **Evidence:** https://developer.apple.com/news/ (apple-other, confidence high)
- **Action:** Update the Build section: build with Xcode 27 / iOS 27 SDK. Note the April 2027 deadline. Note that the deployment target can stay at 26.0 (Xcode 27 supports iOS 15–27 deployment targets).

### 2. `factually-wrong` — Minimum requirements: Xcode 26.0+, Swift 6.1+  
_references/01-api-reference.md:534_

- **Correct / new info:** Apple's Xcode support matrix: Xcode 26 / 26.0.1 ship Swift 6.2 (26.1–26.3: 6.2.x; 26.4–26.6: Swift 6.3). Xcode 27: requires macOS Tahoe 26.6 or later; SDKs iOS/tvOS/watchOS/visionOS/macOS 27; deployment targets iOS 15–27, iPadOS 15–27, macOS 12–27, watchOS 9–27, visionOS 1–27; on-device debugging iOS 17+; compiler Swift 6.4 (language modes 6, 5, 4.2, 4). Xcode 27 release notes: "Xcode 27 includes Swift 6.4 and SDKs for iOS 27, iPadOS 27, tvOS 27, watchOS 27, macOS 27, and visionOS 27."
- **Evidence:** https://developer.apple.com/support/xcode/ (apple-other, confidence high)
- **Action:** Change Swift to 6.2+ (Xcode 26) and add an Xcode 27 / Swift 6.4 row (macOS Tahoe 26.6+ host). Keep the iOS 26.0 minimum for the Glass APIs.

### 3. `wrong-availability` — platforms: [..., visionOS 26+]; 01-api-reference.md §15 lists visionOS 26.0+ as a supported target for the Liquid Glass APIs  
_SKILL.md:5_

- **Correct / new info:** Apple DocC availability for glassEffect(_:in:), Glass, Glass.clear, GlassEffectContainer and PrimitiveButtonStyle.glass lists ONLY iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 — visionOS is not listed. HIG Materials: "In visionOS, windows generally use an unmodifiable system-defined material called glass".
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (no visionOS)
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) (apple-doc, confidence high)
- **Action:** Remove visionOS from the frontmatter platforms, the description and the requirements table (01-api-reference.md line 532). Note that visionOS uses its own system glass material and that glassEffect/GlassEffectContainer/.glass are not available there.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 4. `factually-wrong` — Hardware floor on iPhone: iPhone 11 or later (older devices fall back to a flat translucent material managed by the system)  
_references/01-api-reference.md:536_

- **Correct / new info:** WWDC26 Keynote: "that does mean that iOS 27 is supported on iPhone 11 and all of the same iPhone models as iOS 26." iOS 26/27 cannot be installed on pre-iPhone 11 hardware, so there is no 'older device fallback' for an iOS 26+ app. Secondary sources say the supported list includes the iPhone SE 2nd/3rd gen (both A13/A15).
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/101/ (apple-video, confidence high)
- **Action:** Replace with: 'iOS 26 and iOS 27 both support iPhone 11 and later (iOS 27 drops no devices). iPhone 11 / SE (2nd gen) on A13 is the low-end perf target.' Remove the invented fallback claim. The checklist item 'Tested on iPhone 11 (oldest supported)' stays correct for 27.

### 5. `behavior-change` — Material properties table describes iOS 26 glass rendering only  
_references/02-hig-principles.md:32_

- **Correct / new info:** WWDC26 Platforms State of the Union: "To maintain exceptional readability, we tuned Liquid Glass so it more effectively diffuses complex content behind it." "And to establish more depth and separation, we also introduced a darkened edge along with brighter specular highlights." "Apps already using Liquid Glass get these improvements automatically when they run on this year's releases without even needing to recompile." Keynote: "we tuned Liquid Glass so it diffuses complex content behind it much more effectively, while also creating more depth and separation." HIG Color: small elements (toolbars, tab bars) adapt between light and dark; "Liquid Glass appears more opaque in larger elements like sidebars to preserve legibility".
- **Availability:** iOS 27 / iPadOS 27 / macOS 27 (runtime change, no recompile needed)
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/102/ (apple-video, confidence high)
- **Action:** Add a 'What changed in 27' note: more diffusion, darkened edge, brighter speculars, applied automatically. Tell Claude not to add custom borders, edge strokes or blurs to imitate depth, and to re-check custom glass visuals on iOS 27.

### 6. `behavior-change` — "Tinted Mode (iOS 26.1+): Users can globally reduce app glassiness via Settings → Accessibility → Display. The system applies the chosen opacity ... verify your design still reads at maximum opacity"; table row "User-controlled opacity multiplier"  
_references/05-accessibility.md:163_

- **Correct / new info:** iOS 26.1 added a binary Liquid Glass look choice (Clear / Tinted). Apple's HIG Materials and 'Adopting Liquid Glass' only say "people can choose a preferred look for Liquid Glass in their device's settings". Secondary sources place it at Settings > Display & Brightness > Liquid Glass, not Accessibility. iOS 27 replaces it with a slider. Keynote: "we're adding a new slider and settings to adjust Liquid Glass, so you can set it anywhere from ultra clear to fully tinted ... for developers who have already adopted Liquid Glass, these customizations apply in your apps right away." WWDC26 'What's new in SwiftUI' (269): "Liquid Glass has a refined look and automatically responds to the new Liquid Glass slider to adjust its tint." HIG Materials: the appearance of the regular and clear variants "can differ in response to certain system settings". Location in 27 (Settings > Appearance > Liquid Glass) and its granularity come only from secondary beta-era reports, which conflict.
- **Availability:** Clear/Tinted: iOS 26.1+; slider: iOS 27+
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/101/ (apple-video, confidence high)
- **Action:** Rename to 'Liquid Glass appearance setting'. Describe 26.1 Clear/Tinted and the 27 ultra-clear-to-fully-tinted slider. Drop the 'Accessibility → Display' path and the 'opacity multiplier' wording. Tell Claude to test custom glass, tints and dimming layers at both ends of the slider.

### 7. `other` — Implicitly: nothing to code; no mention of whether apps can read the setting  
_references/05-accessibility.md:165_

- **Correct / new info:** No public API for reading the user's Liquid Glass look/slider was found. SwiftUI EnvironmentValues topics contain no glass-related property, UITraitCollection lists no glass trait, and the Glass struct docs don't mention system settings. Standard glass adapts automatically (WWDC26 269, State of the Union).
- **Evidence:** https://developer.apple.com/documentation/swiftui/environmentvalues (apple-doc, confidence medium)
- **Action:** State explicitly that there is no API to detect the slider position. Tell Claude never to invent one, and to use Glass variants and system dimming so custom UI adapts automatically.

```swift
NOT FOUND
```

### 8. `factually-wrong` — Reduce Transparency: opaque material with subtle border, lensing disabled; Increase Contrast: stark border, tints saturate; Reduce Motion: specular tracking off, morphing replaced with cross-fade or hard cut, materialize suppressed (also 01-api-reference.md lines 494-496)  
_references/05-accessibility.md:13_

- **Correct / new info:** WWDC25 'Meet Liquid Glass' (219): "Reduced Transparency, makes Liquid Glass frostier and obscures more of the content behind it. Increased contrast, makes elements predominantly black or white and highlights them with a contrasting border and Reduced Motion decreases the intensity of some effects and disables any elastic properties for the material. These are available automatically whenever you use the new material." WWDC26 State of the Union: "Liquid Glass seamlessly adapts to a variety of accessibility settings users may choose, such as reducing transparency or increasing contrast." iPhone Duo tech talk: a vertical bar "does have a background when the reduced transparency accessibility setting is enabled. Make sure your custom view content stays legible regardless."
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence high)
- **Action:** Rewrite the table rows with Apple's wording: frostier rather than opaque, predominantly black/white plus a contrasting border, reduced intensity with no elastic properties. Remove the unverified 'tints saturate', 'cross-fade or hard cut' and 'lensing disabled' claims.

### 9. `new-api-ios26x` — Environment values listed: accessibilityReduceTransparency, accessibilityReduceMotion, accessibilityDifferentiateWithoutColor, colorSchemeContrast; no Show Borders / Button Shapes handling  
_references/05-accessibility.md:28_

- **Correct / new info:** accessibilityShowButtonShapes is deprecated/renamed to accessibilityShowBorders ("Whether the system preference for Show Borders is enabled."). Discussion: "On macOS 27 and later, the system provides a dedicated Show Borders setting in System Settings. On earlier versions of macOS, this value is true when Increased Contrast is enabled. When this value is true, draw interactive custom controls such as buttons with clearly visible edges". State of the Union: "now macOS 27 also supports the 'show borders' environment value, just like iOS." Xcode 27 release notes: the preview canvas overrides picker "now includes a Control Borders group" and "a Color Scheme Contrast group".
- **Availability:** iOS 14.0+, iPadOS 14.0+, Mac Catalyst 14.0+, macOS 11.0+, tvOS 14.0+, visionOS 1.0+, watchOS 7.0+ (back-deployed name; dedicated macOS setting in 27)
- **Evidence:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityshowborders (apple-doc, confidence high)
- **Action:** Add accessibilityShowBorders to the env-value list, the custom-control guidance (stroke custom glass controls when true) and the audit checklist. Mention the Xcode 27 Control Borders preview override.

```swift
@backDeployed(before: iOS 26.1, macOS 26.1, tvOS 26.1, watchOS 26.1, visionOS 26.1)
var accessibilityShowBorders: Bool { get }
```

### 10. `new-api-ios26x` — System-managed adaptations table omits Reduce Bright Effects  
_references/05-accessibility.md:7_

- **Correct / new info:** New SwiftUI environment value accessibilityReduceHighlightingEffects: "Whether the system preference for Reduce Bright Effects is enabled." Discussion: "If this property's value is true, controls, such as buttons, should be drawn in such a way that minimizes highlighting and flashing of onscreen elements." Whether system Liquid Glass speculars respond to it is not documented (reasoning).
- **Availability:** iOS 26.4+, iPadOS 26.4+, Mac Catalyst 26.4+, macOS 26.4+, tvOS 26.4+, visionOS 26.4+, watchOS 26.4+
- **Evidence:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducehighlightingeffects (apple-doc, confidence high)
- **Action:** Add Reduce Bright Effects: custom highlight, shimmer or glow effects layered on glass controls should be suppressed when this is true. Add it to the audit checklist.

```swift
var accessibilityReduceHighlightingEffects: Bool { get }
```

### 11. `factually-wrong` — Body text (< 18pt regular, < 14pt bold) 4.5:1; Large text (≥ 18pt regular, ≥ 14pt bold) 3:1 (also 02-hig-principles.md line 142)  
_references/05-accessibility.md:61_

- **Correct / new info:** HIG Accessibility (values Accessibility Inspector uses, from WCAG AA): "Up to 17 pts | All | 4.5:1"; "18 pts | All | 3:1"; "All | Bold | 3:1". "If your app doesn't provide this minimum contrast by default, ensure it at least provides a higher contrast color scheme when the system setting Increase Contrast is turned on." HIG also mentions APCA as an alternative measure.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/accessibility (apple-other, confidence high)
- **Action:** Replace the table with the HIG table: ≤17pt 4.5:1; 18pt+ 3:1; bold at any size 3:1. Add the Increase Contrast fallback requirement.

### 12. `factually-wrong` — Apple's minimum tappable area is 44 × 44 points  
_references/05-accessibility.md:148_

- **Correct / new info:** HIG Accessibility control-size table: iOS/iPadOS default control size 44x44 pt, minimum control size 28x28 pt (macOS 28/20, tvOS 66/56, visionOS 60/28, watchOS 44/28). Spacing: ~12 pt padding around bezeled elements, ~24 pt around non-bezeled.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/accessibility (apple-other, confidence high)
- **Action:** Reword as '44×44 pt default/recommended, 28×28 pt absolute minimum' and add the padding guidance.

### 13. `design-guidance` — "Never glass-on-glass-on-glass. Maximum two layers." (02-hig-principles.md line 65: "A glass card sitting on a glass nav bar = OK"; checklist line 21 'Maximum two glass layers stacked')  
_SKILL.md:85_

- **Correct / new info:** WWDC25 'Meet Liquid Glass' (219): "always avoid glass on glass. Stacking Liquid Glass elements on top of each other can quickly make the interface feel cluttered and confusing. When placing elements on top of Liquid Glass, avoid applying the material to both layers. Instead, use fills, transparency, and vibrancy for the top elements to make them feel like a thin overlay that is part of the material." HIG Materials: "Don't use Liquid Glass in the content layer." A 'glass card' is content layer.
- **Evidence:** https://developer.apple.com/videos/play/wwdc2025/219/ (apple-video, confidence high)
- **Action:** Change the rule to 'Never stack glass on glass (one glass layer)'. Elements on top of glass use fills, transparency or vibrancy. Remove 'glass card on glass nav bar = OK' and fix the checklist item.

### 14. `design-guidance` — "Never use .ultraThinMaterial or other legacy Material values in iOS 26+" (checklist line 9: no .ultraThinMaterial/.regularMaterial/.thinMaterial left in iOS 26 code paths)  
_SKILL.md:88_

- **Correct / new info:** HIG Materials: "Don't use Liquid Glass in the content layer ... Instead, use standard materials for elements in the content layer, such as app backgrounds." "In addition to Liquid Glass, iOS and iPadOS continue to provide four standard materials — ultra-thin, thin, regular (default), and thick — which you can use in the content layer to help create visual distinction." Also: "Help ensure legibility by using vibrant colors on top of materials" and avoid quaternaryLabel on thin/ultraThin.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Narrow the rule to: don't use standard materials for controls or navigation chrome, where you'd use glass; standard Materials are correct in the content layer. Update the checklist and anti-pattern #2 to match.

### 15. `design-guidance` — Contrast fix: subtle scrim Color.black.opacity(0.15).blendMode(.plusDarker); 06-performance.md line 61 suggests '.clear variant (lighter)' as a perf fix; no rules for when clear is allowed  
_references/05-accessibility.md:73_

- **Correct / new info:** HIG Materials: "Only use clear Liquid Glass for components that appear over visually rich backgrounds." Regular: "Use the regular variant when background content might create legibility issues, or when components have a significant amount of text, such as alerts, sidebars, or popovers." Clear: for components that float above media backgrounds. "If the underlying content is bright, consider adding a dark dimming layer of 35% opacity"; no dimming needed if content is dark or if AVKit playback controls provide their own. Glass.clear doc: "When using clear glass, ensure content remains legible by adding a dimming layer or other treatment beneath the glass." (example uses .background(.black.opacity(0.3))). WWDC25 219: Regular and Clear "should never be mixed"; use Clear only if (1) over media-rich content, (2) the content layer isn't hurt by a dimming layer, (3) the content on top is bold and bright.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Add the HIG rules for regular vs clear, including the 35% dark dimming layer for bright content and 'never mix variants'. Remove '.clear is lighter' as a performance tip, since Apple gives no performance rationale for it.

```swift
static var clear: Glass { get }
```

### 16. `design-guidance` — "For brand color, tint the content (icon, label), not the glass." (also 03-design-tokens.md line 67, checklist line 34; tint table maps red/green/orange semantics onto glass)  
_references/02-hig-principles.md:103_

- **Correct / new info:** HIG Branding (Sept 9, 2026): "Apply your app's accent color judiciously ... Minimize its use on controls and instead use it intentionally for primary actions or status indicators, like badges for unread content or an icon for the selected tab in a tab bar. To express your brand through color, consider moving it into the content layer, where it scrolls beneath Liquid Glass controls and gets picked up dynamically." HIG Color (Dec 16, 2025): "To emphasize primary actions, apply color to the background rather than to symbols or text" and "Refrain from adding color to the background of multiple controls." "If your app features colorful backgrounds or visually rich content, prefer a monochromatic appearance for toolbars and tab bars". In monochromatic apps, using the brand color as the accent color "can be an effective way". WWDC26 'Communicate your brand identity on iOS' (251): "move color into the content area of your app, into the scroll view. That way, Liquid Glass controls sit above the content layer and pick up your brand color dynamically."
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/branding (apple-other, confidence high)
- **Action:** Rewrite the Tinting and brand rules: put brand color in the scrolling content layer; keep bar labels monochrome by default; color the background of only the one primary action (prominent style); use the accent color for status and selection. Remove 'tint the icon/label for brand'.

### 17. `design-guidance` — Toolbar item tinted (.badge(3).tint(.red)) and a fixed ToolbarSpacer between toolbar items  
_examples/09-HealthTodayScreen.swift:110_

- **Correct / new info:** HIG Toolbars (Dec 16, 2025): "Reduce the use of toolbar backgrounds and tinted controls." "Use the .prominent style for key actions such as Done or Submit ... Only specify one primary action, and put it on the trailing side of the toolbar." "Prefer system-provided symbols without borders." Badges are endorsed as status indicators, but the tint is unnecessary.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/toolbars (apple-other, confidence medium)
- **Action:** Remove .tint(.red) from the toolbar Inbox button and let the badge carry the status. Also see the ToolbarSpacer finding.

### 18. `design-guidance` — ToolbarSpacer: "Insert visible breathing room between glass toolbar items" (used with .fixed in example 09)  
_references/01-api-reference.md:317_

- **Correct / new info:** Adopting Liquid Glass: "Audit toolbar customizations. Review anything custom you do to display items in your toolbars, like your use of fixed spacers or custom items, as these can appear inconsistent with system behavior." HIG Designing for iPhone Duo: "Group related toolbar items instead of spacing them manually. Groups you create with ToolbarItemGroup ... provide space between items and other groups automatically, and adapt as the available space changes, so avoid adding fixed spacing yourself." iPhone Duo tech talk: "By default, flexible spacers are zero size in the vertical axis. But fixed spacers continue to respect their minimum size ... Your app shouldn't be creating additional spacing". HIG Toolbars still recommends fixed space only between adjacent text-labeled buttons.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo (apple-other, confidence high)
- **Action:** Recommend ToolbarItemGroup for grouping. Limit ToolbarSpacer(.fixed) to separating adjacent text-labeled buttons, and warn that fixed spacers persist in vertical bars.

### 19. `behavior-change` — Skill never mentions scroll edge effects (ScrollEdgeEffectStyle, scrollEdgeEffectStyle(_:for:), safeAreaBar)  
_references/02-hig-principles.md_

- **Correct / new info:** HIG Scroll views (updated June 8, 2026): "Prefer the automatic scroll edge effect style ... If you use the soft scroll edge effect style instead, thoroughly test"; "Only use a scroll edge effect when a scroll view is behind floating interface elements"; "Apply one scroll edge effect per view". WWDC26 'Modernize your UIKit app' (278): "the .automatic style no longer switches between the existing soft and hard styles but provides its own visuals for additional clarity. If you have overridden the style from .automatic previously, that decision should be re-evaluated, especially when set to .soft, as that no longer matches the default system appearance." State of the Union: "When content scrolls under floating bars, a uniform toolbar appears across the top and keeps the text legible ... applied automatically for standard toolbars and can be customized using the existing scroll edge effect APIs." macOS 27 (289): automatic "resolves to a hard-edge effect, when there is free-floating text". HIG Layout: "Instead of applying a solid or semi-opaque background color beneath controls, use a scroll edge effect". iOS 27 UIKit: a UIScrollEdgeElementContainerInteraction container view may contribute to the effect's shape.
- **Availability:** ScrollEdgeEffectStyle: iOS 26.0+ (all platforms 26.0); new automatic visuals: iOS 27
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/scroll-views (apple-other, confidence high)
- **Action:** Add a 'Scroll edge effects' section to the HIG and API references: prefer .automatic; don't force .soft; use only behind floating UI, one per view; never put a solid or tinted background behind bars. Add an anti-pattern for .toolbarBackground colors.

```swift
static var automatic: ScrollEdgeEffectStyle / static var hard: ScrollEdgeEffectStyle / static var soft: ScrollEdgeEffectStyle
```

### 20. `design-guidance` — "Toolbar that hugs an edge: Wrap in a .safeAreaInset to pin it"  
_patterns/glass-floating-toolbar.md:58_

- **Correct / new info:** HIG Scroll views: "If you use custom bars, you might want to add this effect manually if the top layer of your interface needs extra clarity". SwiftUI lists safeAreaBar(edge:alignment:spacing:content:) — "Shows the specified content as a custom bar beside the modified view" — under 'Configuring scroll edge effects', unlike safeAreaInset. On iPhone Duo, custom bars should position themselves using the toolbarVerticalEdge environment value.
- **Availability:** safeAreaBar: iOS 26.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle (apple-doc, confidence medium)
- **Action:** Use .safeAreaBar(edge:) for custom floating bars so they take part in scroll edge effects, and add the iPhone Duo vertical-edge note.

### 21. `platform-requirement` — Tab bar / toolbar patterns assume horizontal bars at top/bottom; no iPhone Duo guidance  
_patterns/glass-tab-bar.md_

- **Correct / new info:** HIG 'Designing for iPhone Duo' (new Sept 9, 2026): "On iPhone Duo, toolbars, tab bars, and navigation controls that are typically at the top and bottom of the display move to the side ... The exception is the inner display in portrait". Guidance: "In general, don't override the default bar placement"; "Provide both a title and a symbol for each toolbar item that isn't text-only"; "Keep text-based buttons to a minimum. Labels that include text stay in a horizontal bar"; use visibility priority and the system overflow menu; ReservedRegion for hinge/camera. Developer News: iPhone Duo is available Oct 23, 2026 running iOS 27.1; Xcode 27.1 adds support; "Starting April 2027, any apps or games submitted will need to include screenshots for iPhone Duo." APIs (iOS 27.1, beta): toolbarVerticalBehavior(_:) (only .disabled documented; for full-screen video players or calculator-like layouts) and EnvironmentValues.toolbarVerticalEdge (HorizontalEdge?; nil where no vertical bar). Tech talk 111462: prefer symbol-only items plus .badge over inline text counts.
- **Availability:** iOS 27.1+ (beta), iPadOS 27.1+ (beta), Mac Catalyst/macOS/tvOS/visionOS/watchOS 27.1
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo (apple-other, confidence high)
- **Action:** Add an iPhone Duo section to the tab bar, toolbar and floating-toolbar patterns: use system bars; give every item a title plus a symbol; avoid manual spacing; position custom glass palettes with toolbarVerticalEdge; opt out with toolbarVerticalBehavior(.disabled) only for the cases Apple lists. Add an iPhone Duo row to the Devices checklist.

```swift
var toolbarVerticalEdge: HorizontalEdge? { get }
nonisolated func toolbarVerticalBehavior(_ behavior: ToolbarVerticalBehavior) -> some View
```

### 22. `new-api-ios27` — "The role: .search tab is special: it surfaces the system search field at the top of the screen automatically." (glass-search-field.md line 79 says the same)  
_patterns/glass-tab-bar.md:85_

- **Correct / new info:** New TabRole.prominent (iOS 27.0): "A tab role that provides prominent visual treatment to one of the tabs in supported tab bars. Only one tab can receive the prominent treatment. When there are no tabs with an explicit .prominent role, then a .search role tab may receive the prominent visual treatment by default." SwiftUI updates (June 2026): the prominent role places the tab "in a separate, trailing position of the tab bar." HIG Search fields (June 8, 2026) describes two search-tab styles: Standard tab ("navigates people to a search landing page with a search field at the top") and Button appearance ("brings focus to the search field and displays the keyboard"). WWDC26 292: "use a button appearance by making Search a prominent tab". UIKit (278): "The prominent tab is always visible, even when the tab bar collapses during scrolling."
- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/tabrole/prominent (apple-doc, confidence high)
- **Action:** Document both search-tab styles and how to choose between them (exploratory content → standard tab; quick lookup → button appearance or prominent). Add Tab(role: .prominent) for a single trailing action tab such as a cart, gated with if #available(iOS 27, *). Fix the 'always at top' claim.

```swift
static var prominent: TabRole { get }
```

### 23. `design-guidance` — "A native iOS 26 search field that lives in the nav bar"  
_patterns/glass-search-field.md:4_

- **Correct / new info:** HIG Search fields: "Place search at the bottom if there's room ... Search at the bottom is useful in any situation where search is a priority". WWDC26 'Design intuitive search experiences' (292): "While the bottom toolbar position is preferred, Search can also be placed in a Top Toolbar." "If you need more than two other toolbar items, search can also start as a button and then animate into a field when tapped." "Depending on where your Search Field is placed, it will automatically adopt the correct presentation style. Such as using glass when placed in a Toolbar or using standard content styling when placed in the scroll region".
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/search-fields (apple-other, confidence medium)
- **Action:** Reframe the pattern: bottom toolbar is the preferred iPhone placement; top or nav bar is the alternative; a field in the scroll content is not glass. Keep the 'don't hand-roll a glass TextField' gotcha.

### 24. `new-api-ios27` — Only tabBarMinimizeBehavior is covered; no navigation-bar/toolbar minimization  
_references/01-api-reference.md:372_

- **Correct / new info:** New in iOS 27: toolbarMinimizationBehavior(_:for:) — "Use this modifier to enable toolbar minimization in response to scrolling. The supported placement is navigationBar. When the navigation bar minimizes, an integrated top tab bar will also minimize. By default, the safe area adjusts as the navigation bar minimizes. Use toolbarMinimizationSafeAreaAdjustment(_:for:) to customize this." iOS 27 release notes: "You can use toolbarMinimizationBehavior to control bar minimization behavior. This modifier replaces toolbarMinimizeBehavior." The WWDC26 SwiftUI session (269) transcript still shows the pre-release name .toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar). tabBarMinimizeBehavior(_:) remains non-deprecated (iOS 26.0). UIKit: UINavigationItem.navigationBarMinimization replaces barMinimizeBehavior/barMinimizationSafeAreaAdjustment.
- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Evidence:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:) (apple-doc, confidence high)
- **Action:** Add the nav-bar minimization API (iOS 27, use if #available). Warn Claude not to copy the toolbarMinimizeBehavior spelling from the WWDC26 video.

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

### 25. `behavior-change` — Sheet pattern assumes control styling inherited from the presenter  
_patterns/glass-modal-sheet.md_

- **Correct / new info:** iOS 27 release notes (SwiftUI resolved issue 167448274): "In apps built with the 27.0 SDKs, the controlSize, buttonSizing, buttonRepeatBehavior, menuIndicatorVisibility, and ButtonBorderShape environment values are now reset to their default values in sheets and popovers."
- **Availability:** Apps built with the 27.0 SDKs
- **Evidence:** https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes (apple-doc, confidence high)
- **Action:** Add a gotcha: apply .buttonBorderShape, .controlSize and .buttonSizing for glass buttons inside the sheet or popover content. Values set on the presenting view no longer flow into the sheet.

### 26. `design-guidance` — InfoSheet toolbar has only a Done (confirmationAction) button  
_patterns/glass-modal-sheet.md:45_

- **Correct / new info:** HIG Sheets (updated March 24, 2026): "Provide an alternative to the Done button. If you provide a Done button, always pair it with a Cancel button ... or a Back button to move to a previous step in the sheet." "Avoid showing all three buttons — Cancel, Done, and Back — together." iOS/iPadOS: "for sheets with a single view, the Cancel button belongs on the leading edge of the top toolbar. When present, the Done button belongs on the trailing edge." Multi-step: first step Cancel leading + inactive Done trailing; later steps Back replaces Cancel; Done becomes active on the final step. Anatomy: "The Cancel (or Close) button dismisses a sheet without saving any changes." HIG Toolbars: use the standard Close symbol, not a 'Close' text label.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/sheets (apple-other, confidence medium)
- **Action:** For informational sheets, use a standard Close (xmark) button (.cancellationAction or role: .close). For task sheets, pair Cancel (leading) with Done (trailing, prominent). Add the multi-step placement rules.

### 27. `design-guidance` — A non-interactive Text tag chip gets .glassEffect() inside every card of a scrolling LazyVStack  
_patterns/glass-card-stack.md:39_

- **Correct / new info:** HIG Materials: "Don't use Liquid Glass in the content layer ... An exception to this is for controls in the content layer with a transient interactive element like sliders and toggles". "Use Liquid Glass effects sparingly ... Limit these effects to the most important functional elements in your app." Applying Liquid Glass to custom views: "Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance. Limit the use of Liquid Glass effects onscreen at the same time." This also conflicts with the skill's own 06-performance rule against glass on list cells.
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/materials (apple-other, confidence high)
- **Action:** Replace the glass tag chip with a standard material or a vibrancy-filled capsule (e.g. .background(.ultraThinMaterial, in: .capsule)). Keep glass only for interactive chrome.

### 28. `unverifiable-claim` — Instruments Metal System Trace (Xcode 26) shows glass passes as labeled phases 'GlassEffect: layout' / 'GlassEffect: composite'; '1 container of 5 children is ~5× cheaper'; '1–3 ms/frame on A13–A14'; 'Cheap on A17, noticeable on A13'  
_references/06-performance.md:147_

- **Correct / new info:** No Apple source documents these phase names or numbers. Apple's guidance (Applying Liquid Glass to custom views): "Use GlassEffectContainer when applying Liquid Glass effects on multiple views to achieve the best rendering performance" but "Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance. Limit the use of Liquid Glass effects onscreen at the same time." It points to 'Explore UI animation hitches and the render loop' and 'Optimize SwiftUI performance with Instruments'. Xcode 27: "The new Hitches metric replaces the Scrolling metric in the Organizer, now displaying animation hitches for all animations in your app". WWDC26 258: it "surfaces issues ... like understanding how apps use Liquid Glass and SwiftUI views." The SwiftUI instrument records more layout-pass detail.
- **Evidence:** https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views (apple-doc, confidence medium)
- **Action:** Remove the invented phase names and numeric costs, or mark them as estimates. Recommend the Animation Hitches and SwiftUI instruments and the Xcode 27 Organizer Hitches metric. Add Apple's warning against too many containers.

### 29. `inconsistency` — "Apple's Human Interface Guidelines for iOS 26 are organized around three pillars: Hierarchy, Harmony, and Consistency"; sources cite 'WWDC25 Session 284 — Get to know the new design system' (also 01-api-reference.md lines 3 and 585)  
_references/02-hig-principles.md:3_

- **Correct / new info:** The hierarchy/harmony/consistency triad comes from Apple's Liquid Glass technology overview ("establish hierarchy, create harmony, and maintain consistency"), not from HIG structure. The HIG reintroduced Design principles on June 8, 2026 as eight principles: Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, Delight (WWDC26 session 250 'Principles of great design'). Session numbers: WWDC25 356 = 'Get to know the new design system'; 284 = 'Build a UIKit app with the new design'; 323 = 'Build a SwiftUI app with the new design'; 219 = 'Meet Liquid Glass'; 310 = 'Build an AppKit app with the new design'.
- **Evidence:** https://developer.apple.com/documentation/technologyoverviews/liquid-glass (apple-doc, confidence high)
- **Action:** Attribute the triad to the Liquid Glass overview and add a short summary of the 2026 HIG Design principles. Fix the session number (284 → 356) in both reference files. Replace the secondary createwithswift source with HIG links.

### 30. `behavior-change` — "Respect platform idioms: floating buttons on iOS, sidebars on iPad/Mac"  
_references/02-hig-principles.md:28_

- **Correct / new info:** 27 releases: State of the Union: "Sidebars expand to the edges on Mac and iPad ... icons in the sidebar regain their color using your app's accent color ... List and Label APIs provide these updates automatically and support customizing the tint per item." HIG Sidebars (June 8, 2026) updated sidebar icon-color guidance (accent color by default; fixed colors sparingly). UIKit (278): "New in iOS 27, iPhone apps can also opt into sidebars by setting the tab bar controller's sidebar.preferredPlacement to .sidebar". iPad apps now dim icons and text in inactive windows (269), using the appearsActive environment value for custom elements. iPadOS/macOS 27 menu bars hide most menu-item images by default (use .labelStyle(.titleAndIcon) for key items).
- **Availability:** iOS/iPadOS/macOS 27
- **Evidence:** https://developer.apple.com/videos/play/wwdc2026/102/ (apple-video, confidence medium)
- **Action:** Add a 27 note: sidebars extend to the edges; sidebar icons use the accent color; custom glass controls on iPad should honor @Environment(\.appearsActive) for inactive dimming; iPhone sidebars are possible in UIKit.

### 31. `new-api-ios27` — Concentric corner trick: .rect(cornerRadius: .containerConcentric)  
_references/03-design-tokens.md:152_

- **Correct / new info:** iOS 27 release notes: "You can now access concentricCornerRadii and concentricCornerRadii(in:) on GeometryProxy. These APIs return the corner radii that are concentric with the view's container shape as a RectangleCornerRadii?. You can use these values to drive custom drawing or layout that responds to the container's corners without rendering a ConcentricRectangle directly." AppKit 27 adds NSView.cornerConfiguration with .containerConcentric (WWDC26 289). Exact signatures were not verified here (left to the API audit).
- **Availability:** iOS 27 SDK
- **Evidence:** https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes (apple-doc, confidence medium)
- **Action:** Verify the iOS 26 concentric API spelling in the API audit, and add GeometryProxy.concentricCornerRadii (27) for custom drawing.

### 32. `platform-requirement` — Build section lacks other iOS 27 SDK requirements  
_checklists/pre-ship-checklist.md:81_

- **Correct / new info:** iOS 27 release notes (UIKit): "Apps built with the latest SDK must adopt the scene-based life cycle or they fail to launch." "iOS and iPadOS apps built with the 27.0 SDK or later are required to include a launch screen ... Apps that don't include a launch screen are rejected when the App Store begins accepting apps built with the 27.0 SDK." State of the Union: "Once you rebuild with the latest SDK, your app is automatically opted in to resizability." Xcode 27 deprecates PreviewProvider (use #Preview). SwiftUI App-lifecycle apps are already scene-based.
- **Availability:** Apps built with iOS 27 SDK
- **Evidence:** https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes (apple-doc, confidence high)
- **Action:** Add Build checklist items: scene lifecycle, a launch screen key in Info.plist, resizable layouts tested in Device Hub resize mode or the Xcode 27 Resizable Canvas, #Preview only.

### 33. `other` — App icons / Icon Composer changes for 27 (skill does not cover icons)

- **Correct / new info:** HIG App icons (June 8, 2026: "Refined guidance for Liquid Glass"): layered icons take on "specular highlights, refraction, and translucency"; appearances are Default, dark, clear light, clear dark, tinted light, tinted dark. Xcode 27: "Icon Composer 2.0 supports a new sharper rendering mode for upcoming 2027 operating systems with support for refractivity, outside specular, and deeper shadows ... preview in either the new or original design generation." Keynote: icons integrate "additional layers of Liquid Glass directly into the icon artwork".
- **Evidence:** https://developer.apple.com/design/human-interface-guidelines/app-icons (apple-other, confidence high)
- **Action:** Optional: add a short pointer saying app icons are made in Icon Composer (2.0 for the 27 rendering) and are out of scope for SwiftUI code.

### 34. `other` — (Rumor/secondary context for the 27 slider)  
_references/05-accessibility.md:163_

- **Correct / new info:** Secondary beta-era reports (9to5Mac, Tom's Guide, MacRumors via search summaries; pages not fetchable here) place the iOS 27 control at Settings > Appearance > Liquid Glass and also show it in iPhone setup. They describe left as more transparent and right as more tint/frost, with the midpoint as the default. One hands-on review describes Clear/Default/Tinted stops, so reports on granularity conflict. A pre-WWDC AppleInsider report predicted that Xcode 27 would disable the deferral flags; Apple has since confirmed this (see the UIDesignRequiresCompatibility finding).
- **Evidence:** https://9to5mac.com/2026/06/15/ios-27-adds-new-liquid-glass-slider-on-iphone-heres-what-it-lets-you-do/ (secondary, confidence low)
- **Action:** If the skill names a Settings path for the 27 slider, mark it 'reported' or leave it out. Rely only on Apple's wording ('a new slider in settings ... from ultra clear to fully tinted').

## Symbols (15)

### `UIDesignRequiresCompatibility`

```swift
UIDesignRequiresCompatibility (Info.plist key, type boolean)
```

- **Availability:** iOS 26.0, iPadOS 26.0, macOS 26.0, tvOS 26.0 (not deprecated; ignored when building for 27 or later)
- **Members:** YES = compatibility mode (looks as built against previous SDKs); NO/absent = current design
- **Doc:** https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility
- **Skill uses it correctly:** NO
- **Notes:** Not mentioned by the skill. Doc: 'The system ignores this key when you build for iOS 27 or later, iPadOS 27 or later, Mac Catalyst 27 or later, macOS 27 or later, or tvOS 27 or later.' The skill needs a migration note.

### `Glass`

```swift
struct Glass
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (no visionOS)
- **Members:** static var clear: Glass, static var identity: Glass, static var regular: Glass, func interactive(_: Bool) -> Glass, func tint(_: Color?) -> Glass
- **Doc:** https://developer.apple.com/documentation/swiftui/glass
- **Skill uses it correctly:** yes
- **Notes:** No new members in 27. The docs say nothing about the user's Liquid Glass slider. visionOS is not listed, so the skill's visionOS claim is wrong.

### `View.glassEffect(_:in:)`

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (visionOS not listed)
- **Members:** glass (default .regular), shape (default DefaultGlassEffectShape, a Capsule)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Skill uses it correctly:** yes
- **Notes:** Signature unchanged in 27. The doc says to apply it after other modifiers that affect appearance and to use it with GlassEffectContainer.

### `GlassEffectContainer`

```swift
@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (no visionOS)
- **Doc:** https://developer.apple.com/documentation/swiftui/glasseffectcontainer
- **Skill uses it correctly:** yes
- **Notes:** Apple also warns that 'Creating too many Liquid Glass effect containers ... can degrade performance.' The skill's 'always container' plus '5× cheaper' wording overstates it.

### `PrimitiveButtonStyle.glass`

```swift
@export(implementation) nonisolated static var glass: GlassButtonStyle { get }
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (no visionOS)
- **Doc:** https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glass
- **Skill uses it correctly:** yes
- **Notes:** Discussion: 'In tvOS, this button style applies a Liquid Glass effect regardless of whether the button has focus.'

### `Glass.clear`

```swift
static var clear: Glass { get }
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/glass/clear
- **Skill uses it correctly:** NO
- **Notes:** Doc requires a dimming layer beneath clear glass (example .background(.black.opacity(0.3))). The HIG says 35% for bright content. The skill omits this and wrongly presents .clear as a performance optimization.

### `ScrollEdgeEffectStyle`

```swift
struct ScrollEdgeEffectStyle
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Members:** static var automatic: ScrollEdgeEffectStyle, static var hard: ScrollEdgeEffectStyle, static var soft: ScrollEdgeEffectStyle; related: scrollEdgeEffectStyle(_:for:), scrollEdgeEffectHidden(_:for:), safeAreaBar(edge:alignment:spacing:content:)
- **Doc:** https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle
- **Skill uses it correctly:** NO
- **Notes:** Not covered by the skill. In iOS 27, .automatic no longer switches between soft and hard and has its own visuals (WWDC26 278). The HIG (June 2026) says to prefer automatic.

### `TabRole.prominent`

```swift
static var prominent: TabRole { get }
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Members:** TabRole members: prominent, search
- **Doc:** https://developer.apple.com/documentation/swiftui/tabrole/prominent
- **Skill uses it correctly:** NO
- **Notes:** New in 27. Only one tab can be prominent. If no tab is explicitly .prominent, a .search tab may get the prominent treatment by default. The skill's claim that the search tab always shows the field at the top is incomplete.

### `View.tabBarMinimizeBehavior(_:)`

```swift
nonisolated func tabBarMinimizeBehavior(_ behavior: TabBarMinimizeBehavior) -> some View
```

- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+ (not deprecated)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/tabbarminimizebehavior(_:)
- **Skill uses it correctly:** yes
- **Notes:** Still valid in 27.

### `View.toolbarMinimizationBehavior(_:for:)`

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Members:** supported placement: navigationBar; example uses .onScrollDown; companion toolbarMinimizationSafeAreaAdjustment(_:for:)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)
- **Skill uses it correctly:** NO
- **Notes:** New in 27 and missing from the skill. The release notes say it replaces toolbarMinimizeBehavior, the pre-release name still shown in the WWDC26 269 transcript.

### `View.toolbarVerticalBehavior(_:)`

```swift
nonisolated func toolbarVerticalBehavior(_ behavior: ToolbarVerticalBehavior) -> some View
```

- **Availability:** iOS 27.1+ (beta), iPadOS 27.1+ (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Members:** ToolbarVerticalBehavior.disabled (only member documented on the page)
- **Doc:** https://developer.apple.com/documentation/swiftui/view/toolbarverticalbehavior(_:)
- **Skill uses it correctly:** NO
- **Notes:** For iPhone Duo vertical bars. Disable only for full-screen video or calculator-like layouts, and treat it as a stable choice.

### `EnvironmentValues.toolbarVerticalEdge`

```swift
var toolbarVerticalEdge: HorizontalEdge? { get }
```

- **Availability:** iOS 27.1+ (beta), iPadOS 27.1+ (beta), Mac Catalyst 27.1, macOS 27.1, tvOS 27.1, visionOS 27.1, watchOS 27.1
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarverticaledge
- **Skill uses it correctly:** NO
- **Notes:** Use it to position custom floating glass palettes relative to the system vertical bar. It is nil where there is no vertical bar.

### `EnvironmentValues.accessibilityShowBorders`

```swift
@backDeployed(before: iOS 26.1, macOS 26.1, tvOS 26.1, watchOS 26.1, visionOS 26.1)
var accessibilityShowBorders: Bool { get }
```

- **Availability:** iOS 14.0+, iPadOS 14.0+, Mac Catalyst 14.0+, macOS 11.0+, tvOS 14.0+, visionOS 1.0+, watchOS 7.0+
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityshowborders
- **Skill uses it correctly:** NO
- **Notes:** Renamed from accessibilityShowButtonShapes. macOS 27 has a dedicated Show Borders setting. The skill doesn't use it, but should for custom glass controls.

### `EnvironmentValues.accessibilityShowButtonShapes`

```swift
var accessibilityShowButtonShapes: Bool { get }
```

- **Availability:** iOS 14.0, iPadOS 14.0, Mac Catalyst 14.0, macOS 11.0, tvOS 14.0, visionOS 1.0, watchOS 7.0 (listed under Deprecated environment values; renamed: accessibilityShowBorders)
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityshowbuttonshapes
- **Skill uses it correctly:** yes
- **Notes:** Not used by the skill. If added, use the new name accessibilityShowBorders.

### `EnvironmentValues.accessibilityReduceHighlightingEffects`

```swift
var accessibilityReduceHighlightingEffects: Bool { get }
```

- **Availability:** iOS 26.4+, iPadOS 26.4+, Mac Catalyst 26.4+, macOS 26.4+, tvOS 26.4+, visionOS 26.4+, watchOS 26.4+
- **Doc:** https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducehighlightingeffects
- **Skill uses it correctly:** NO
- **Notes:** Reflects the 'Reduce Bright Effects' setting, added in iOS 26.4. Custom highlight or flash effects on glass controls should respect it. Missing from the skill.

