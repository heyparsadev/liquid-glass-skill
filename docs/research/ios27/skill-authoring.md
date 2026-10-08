# skill-authoring

_Phase: Research_

## Summary

I compared the liquid-glass skill (SKILL.md, 7 references, 6 patterns, 9 example Swift files, the checklist, both .claude-plugin manifests and the README) against Anthropic's current guidance. The sources were the platform.claude.com skill best-practices and overview pages, code.claude.com pages on skills, plugin manifests, marketplaces, loading/versions, publishing and evals, the claude.com directory pre-submission checklist and submit pages, and the Agent Skills open spec. agentskills.io is blocked by proxy policy, so I read the spec from raw.githubusercontent.com/agentskills/agentskills. Where the skill makes Apple claims, I spot-checked them against Apple DocC JSON. Nothing in the repo was changed.

Highest-impact problems:
1. **Users never got the August fixes.** plugin.json has pinned version 1.0.0 since 2026-05-25. Per the docs, a pinned version keeps users on the cached copy, so marketplace installs likely never received the 2026-08-10/12 commits, including "Fix three APIs that don't exist". It must be bumped to 2.0.0 for the iOS 27 revision.
2. **Frontmatter uses non-spec keys.** `version` and `platforms` are not allowed by the Agent Skills spec. Claude Code ignores them, but a claude.ai upload, the Skills API or package_skill.py fails with a hard error. They belong under `metadata` (string values) and `compatibility`.
3. **The description won't trigger for iOS 27.** It has no iOS 27, Xcode 27, iPadOS 27, macOS 27, watchOS 27, tvOS 27 or WWDC26 terms, and no review, audit or migrate triggers. It is not in third person. It advertises visionOS 26, but Apple's docs list no visionOS availability for Glass, glassEffect or GlassEffectContainer. A ready-to-use 828-character rewrite is provided.
4. **The "When to activate" section can't work.** It sits in the SKILL.md body, which is only read after the skill has triggered.
5. **The examples contradict the rules, and the rules contradict the HIG.**
   - Golden rule 1, the HIG table and the checklist all say no glass on content. Example 09 still glasses a hero panel, a plan card and metric cards, and nests glass inside glass; example 08 glasses its text fields; anti-pattern #1's "Right" answer is a glass card. Apple's HIG Materials page says "Don't use Liquid Glass in the content layer".
   - Golden rule 5 bans standard materials, yet 06-performance allows `.regularMaterial`. The HIG says to use standard materials for content-layer backgrounds.
   - The accessibility guidance says use system tints, but the examples use `.tint(.white)` and `.tint(.clear)` 29 times.
6. **124 Swift code blocks in references/ and patterns/ are never compiled.** Apple's docs contradict several APIs they use:
   - `glassEffect(_:in:isEnabled:)` has no `isEnabled` parameter.
   - `.containerConcentric` does not appear; Apple's API is ConcentricRectangle with Edge.Corner.Style.concentric.
   - `DefaultToolbarItem` is ToolbarContent, not a View, so it can't be wrapped in a ToolbarItem. This bug is duplicated in two files.

Structural gaps:
- Seven reference files are over 100 lines with no table of contents (01-api-reference is 587 lines).
- A cross-reference is wrong (§ 4 instead of § 2), and file paths are written inconsistently.
- examples/ and patterns/ are only named as directories, with no index. Example 09 is 637 lines.
- The same content is repeated across 3–4 files and has already drifted: Reduce Motion is described three different ways, and the DefaultToolbarItem bug appears twice.
- Wording is tied to dates and versions ("compile in Xcode 26", "in 2026").
- There is no copyable build/review workflow, no validator script and no evals.
- The example code contains the author's personal email and first name, plus a comment carried over from a chat.

Missing high-value content:
- A "what's new in iOS 27" reference. Leads come from Apple's SwiftUI updates page: toolbarMinimizationBehavior(_:for:) (confirmed as introduced in 27.0 on all platforms), TabRole.prominent, ToolbarOverflowMenu, visibilityPriority, topBarPinnedTrailing, NavigationTransition.crossFade, ContentBuilder, and the September 2026 vertical-axis toolbar APIs.
- A 26→27 migration guide covering `#available(iOS 27.0, *)` gating. The current checklist says to remove `@available` checks, which no longer holds.
- An API availability matrix.
- HIG guidance on clear glass: use it only over visually rich backgrounds and add a 35% dimming layer over bright content.

Manifest and directory fixes:
- Update the marketplace entry's description; it overrides plugin.json's description in plugin listings.
- Drop the duplicated entry version.
- Add ios27 and related keywords/tags, and a displayName.
- Use Markdown image syntax in the README; the directory checklist holds HTML-embedded images for review.
- Add a LICENSE file.
- Run `claude plugin validate --strict` and `claude plugin eval` before each release.

## Findings (28)

### 0. `skill-authoring` — plugin.json pins "version": "1.0.0" (set 2026-05-25 in d89baa5) and it was never bumped, although later commits (c405981, 130ab51 on 2026-08-10; 870fda1 'Fix three APIs that don't exist, so the examples actually compile', 788bd1c, 5b947ac on 2026-08-12) changed skill content.  
_.claude-plugin/plugin.json:3_

- **Correct / new info:** Claude Code docs: version 'Setting it pins the plugin to that version until you change it'; 'a manifest that pins "version": "1.0.0" keeps every user on the cached copy until its author changes the string, however many commits they push.' Publish guide: 'If you set version in plugin.json and later push commits without changing it, claude plugin update prints <name> is already at the latest version (1.0.0). and users keep the old copy. Either increment version on every release, or omit it in a git-hosted marketplace so Claude Code uses the commit SHA instead.' Directory submit page: 'If your plugin.json sets version, raise it with every release.' Consequence: marketplace installs very likely never received the August compile fixes.
- **Evidence:** https://code.claude.com/docs/en/plugins/loading (anthropic-doc, confidence high)
- **Action:** Bump plugin.json version to 2.0.0 for the iOS 27 revision (major: new platform generation + frontmatter/scope changes). Treat plugin.json as the single version source and bump on every release thereafter (or deliberately remove version to track commit SHA). Add a CHANGELOG.md; optionally tag releases with `claude plugin tag`.

### 1. `skill-authoring` — Frontmatter contains `version: 1.0.0` and `platforms: [iOS 26+, iPadOS 26+, macOS 26+, watchOS 26+, tvOS 26+, visionOS 26+]` as top-level keys.  
_skills/liquid-glass/SKILL.md:4_

- **Correct / new info:** Agent Skills spec fields are only name, description, license, compatibility (max 500 chars, 'Indicates environment requirements'), metadata ('a map from string keys to string values', example `version: "1.0"`), allowed-tools. Claude Code 'ignores a field it doesn't recognize without reporting an error', but for 'claude.ai skill uploads, the Skills API, and packaging with package_skill.py' only those six fields are allowed: 'If you include any field the spec doesn't allow, packaging or upload fails with a hard error instead of ignoring the field' (error: 'Unexpected key(s) in SKILL.md frontmatter: ... Allowed properties are: allowed-tools, compatibility, description, license, metadata, name'). This skill is also distributed via claude.ai (it appears in this environment's synced skill list as anthropic-skills:liquid-glass), so portability matters.
- **Evidence:** https://code.claude.com/docs/en/skills (anthropic-doc, confidence high)
- **Action:** Replace lines 4-5 with spec-valid keys, e.g.
license: MIT
compatibility: SwiftUI apps built with Xcode 26 or later (Xcode 27 for iOS 27 / macOS 27 APIs) targeting iOS, iPadOS, macOS, watchOS or tvOS 26 or later.
metadata:
  version: "2.0.0"
  platforms: "iOS 26+, iPadOS 26+, Mac Catalyst 26+, macOS 26+, watchOS 26+, tvOS 26+"
  verified-sdk: "Xcode 27.0"
Keep metadata.version in sync with plugin.json. Do not add Claude Code-only keys (when_to_use, paths, argument-hint) — they break claude.ai/API distribution — and do not add `paths: **/*.swift`, which would restrict auto-loading to sessions touching Swift files.

### 2. `skill-authoring` — description: 'Build iOS 26+ SwiftUI interfaces with Apple's Liquid Glass design language. Use when writing SwiftUI for iOS 26 / iPadOS 26 / macOS Tahoe (26) / watchOS 26 / tvOS 26 / visionOS 26, when the user mentions Liquid Glass, `.glassEffect`, `GlassEffectContainer`, iOS 26 design, glass material, glass button, or asks to redesign / modernize a SwiftUI screen to the new system look.' (375 chars). No iOS 27 / iPadOS 27 / macOS 27 / watchOS 27 / tvOS 27 / Xcode 27 / WWDC26 terms; no review/audit/migrate triggers; imperative (not third-person) voice; advertises visionOS.  
_skills/liquid-glass/SKILL.md:3_

- **Correct / new info:** Best practices: 'Always write in third person'; 'Include both what the Skill does and specific triggers/contexts'; description max 1,024 chars, no XML tags. Claude Code: 'Put the key use case first: the combined description and when_to_use text is truncated at 1,536 characters in the skill listing.' Triggering happens only from name+description. Note: Apple newsroom refers to 'macOS 27'; a marketing name for macOS 27 was only found in secondary sources, so do not put one in the description until verified.
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence high)
- **Action:** Replace with (828 chars, third person, key use case first): "Builds, reviews, and migrates SwiftUI interfaces that use Apple's Liquid Glass design on iOS and iPadOS 26-27, macOS Tahoe 26 and macOS 27, watchOS 26-27, and tvOS 26-27 (Xcode 26 or Xcode 27). Covers glassEffect, Glass (regular, clear, identity, tint, interactive), GlassEffectContainer, glassEffectID and glassEffectUnion morphing, .glass and .glassProminent button styles, and system glass chrome: toolbars, tab bars, search, sheets, plus accessibility and performance. Use when writing or editing SwiftUI for iOS 26 or iOS 27, when the user mentions Liquid Glass, glassEffect, GlassEffectContainer, glass button, iOS 26 or iOS 27 design, Xcode 27, or WWDC25/WWDC26 design changes, or asks to redesign, modernize, audit, or migrate a SwiftUI screen to the current system look. Not for UIKit, AppKit, React Native, or Flutter." Then measure triggering with evals (see evals finding).

### 3. `wrong-availability` — Minimum-requirements table lists 'visionOS | 26.0+'; SKILL.md description and `platforms` key and README line 90 also present visionOS 26 as a Liquid Glass API target.  
_skills/liquid-glass/references/01-api-reference.md:532_

- **Correct / new info:** Apple DocC JSON metadata.platforms for Glass, View.glassEffect(_:in:) and GlassEffectContainer list only iOS, iPadOS, Mac Catalyst, macOS, tvOS, watchOS (introducedAt 26.0) and omit visionOS, while other 26.0 SwiftUI symbols fetched in the same session (ConcentricRectangle, DefaultToolbarItem, tabBarMinimizeBehavior(_:)) do list visionOS 26.0. HIG Materials: 'In visionOS, windows generally use an unmodifiable system-defined material called glass'. Mac Catalyst is listed by Apple but missing from the skill's table.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+ (visionOS not listed)
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/glass.json (apple-doc, confidence medium)
- **Action:** Remove visionOS from the description, metadata.platforms and README activation list, or state explicitly 'visionOS: system window glass only; Glass / glassEffect / GlassEffectContainer are not available'. Add Mac Catalyst. Re-verify against the Xcode 27 SDK docs when building the availability matrix.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 4. `skill-authoring` — SKILL.md body section 'When to activate' says 'Load this skill automatically when ... Editing a .swift file in a project with IPHONEOS_DEPLOYMENT_TARGET >= 26.0 ...'; README lines 88-92 likewise claim activation on deployment target >= 26.0.  
_skills/liquid-glass/SKILL.md:16_

- **Correct / new info:** Only name+description are preloaded; 'When you request something that matches a Skill's description, Claude reads SKILL.md from the filesystem'. Body text cannot influence whether the skill triggers, and Claude cannot evaluate a build setting before loading the skill. Claude Code troubleshooting: 'Check the description includes keywords users would naturally say'.
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview (anthropic-doc, confidence high)
- **Action:** Move all trigger keywords into the description (see description finding). Replace the body section with a short 'Scope' block (in/out of scope, supported OS versions) and a first workflow step: 'Check the deployment target (IPHONEOS_DEPLOYMENT_TARGET / Package.swift platforms) and decide 26-only code vs. #available(iOS 27.0, *)-gated code.' Rewrite README 'When it activates' to describe description-based matching.

### 5. `inconsistency` — Rules say glass is never for content: SKILL.md golden rule 1 (line 84) 'Not for content backgrounds', 02-hig table 'Content | List rows, cards ... ❌', checklist line 20 'No glass on List rows, card bodies, hero backgrounds'. But example 09 glasses the activity hero panel (203), plan card (315) and metric cards (462) and advertises 'Glass workout cards' (line 10); example 08 glasses its text fields (273, 313), against glass-search-field.md line 83 'Don't wrap a TextField and apply .glassEffect()'; example 03 glasses the onboarding hero icon (91); 07-anti-patterns #1 'Right' answer (lines 26-35) is a glass card; 02 line 65 says 'A glass card sitting on a glass nav bar = OK'; the card-stack pattern puts glass chips on content cards.  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:203_

- **Correct / new info:** Apple HIG Materials: 'Don't use Liquid Glass in the content layer. Liquid Glass works best when it provides a clear distinction between interactive elements and content ... Instead, use standard materials for elements in the content layer, such as app backgrounds. An exception to this is for controls in the content layer with a transient interactive element like sliders and toggles'. Anthropic best practices: examples convey desired style 'more clearly than descriptions alone', so Claude will copy the showcase examples over the stated rules.
- **Evidence:** https://developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json (apple-other, confidence high)
- **Action:** Rework examples 08/09 (and 03/05 chips, card-stack pattern) so content surfaces use solid fills or standard materials and only controls/navigation float as glass; change anti-pattern #1's 'Right' answer to a non-glass card with glass controls; fix 02 line 65; add a header comment to each example stating which views are content layer vs functional layer; re-render screenshots.

### 6. `inconsistency` — Golden rule 5: 'Never use .ultraThinMaterial or other legacy Material values in iOS 26+'; also SKILL.md line 12, 02 line 162, 07 anti-pattern #2 (line 40), checklist line 9 ('No .ultraThinMaterial / .regularMaterial / .thinMaterial left in iOS 26 code paths'), glass-navigation-bar.md line 58. Contradicted inside the skill by 06-performance line 74: '.background(.regularMaterial) (legacy) is still legal for full backgrounds'.  
_skills/liquid-glass/SKILL.md:88_

- **Correct / new info:** Apple HIG Materials explicitly recommends standard materials for the content layer: 'Instead, use standard materials for elements in the content layer, such as app backgrounds.' Standard materials are current (not legacy); what HIG rejects is Liquid Glass in the content layer.
- **Evidence:** https://developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json (apple-other, confidence high)
- **Action:** Rewrite golden rule 5 as: 'Don't fake glass on controls/navigation with Material or blur; do use standard materials (e.g. .regularMaterial) for content-layer backgrounds.' Align 02, 06, 07 #2, the checklist API-correctness item and glass-navigation-bar.md with that single rule.

### 7. `inconsistency` — activityHero applies .glassEffect to the panel (line 203) whose statChip children each apply their own .glassEffect (line 220) with no GlassEffectContainer; checklist line 11 forbids '.glassEffect() applied inside another .glassEffect()'. Also patterns/glass-tab-bar.md lines 61-63 and example 09's HydrationStrip put .glass/.glassProminent buttons inside .tabViewBottomAccessory, which the skill elsewhere treats as system glass chrome (07 #11 'Re-glassing system chrome').  
_skills/liquid-glass/examples/09-HealthTodayScreen.swift:220_

- **Correct / new info:** Internal rule (checklist line 11, 07 #1, 06 commandment 2) forbids nesting glass; the flagship example violates it. Whether glass buttons inside a bottom accessory are recommended is not stated in the skill's sources and must be verified against Apple docs/WWDC before being shown as a pattern.
- **Evidence:**  (reasoning, confidence medium)
- **Action:** Remove the nested glass in 09 (make chips plain or make the panel non-glass and wrap chips in a GlassEffectContainer); verify Apple's guidance for controls inside tabViewBottomAccessory and make the tab-bar pattern, example 09 and 07 #11 say the same thing.

### 8. `inconsistency` — 05 warns '.tint(.white) becomes .tint(.black)' under Smart Invert and says to use system colors; checklist line 32 'Tints are system colors'; 02 'Tint is a semantic signal, not a brand color'. Yet examples/patterns contain 29 `.tint(.white…)` / `.tint(.clear)` uses (e.g. 02-MusicPlayerScreen line 55 `.tint(.white.opacity(0.25))` on .glassProminent), and 03-design-tokens lines 55-56 offer `.purple // creative / playful` and `.pink // social / favorites`.  
_skills/liquid-glass/references/05-accessibility.md:174_

- **Correct / new info:** Within the skill, guidance and examples disagree; since examples drive imitation, Claude will emit the white/clear tints the accessibility file forbids.
- **Evidence:**  (reasoning, confidence medium)
- **Action:** Either document white/clear tints over dark media as an explicit, justified exception (with Smart Invert / Increase Contrast verification steps) or switch examples to semantic system tints; drop decorative purple/pink entries from the token palette or mark them content-only.

### 9. `compile-risk` — 01 documents `.glassEffect(_:in:isEnabled:)` with `isEnabled: Bool = true` (lines 7-29, example line 51) and `.glassEffectTransition(_:isEnabled:)` (line 224); prose in 02 (lines 133, 166), 06 (lines 63, 162) and 07 (line 127) relies on `.glassEffect(.regular, isEnabled: visible)`. The compiled examples never use isEnabled.  
_skills/liquid-glass/references/01-api-reference.md:7_

- **Correct / new info:** Apple's declaration has no isEnabled parameter, and the page references no glassEffect(_:in:isEnabled:) overload; the related transition symbol is listed as View/glassEffectTransition(_:). Glass.identity is documented as 'When applied, your content remains unaffected as if no glass effect was applied.'
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/view/glasseffect(_:in:).json (apple-doc, confidence high)
- **Action:** Remove isEnabled from 01 §1 and §6 and from 02/06/07; use `.glassEffect(isOn ? .regular : .identity, in: shape)` for conditional glass; re-check glassEffectTransition's exact signature against the Xcode 27 docs; compile every snippet (see snippet-harness finding).

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

### 10. `compile-risk` — Golden rule 4 and 01 §12, 02 Concentricity, 03 tokens, 07 #6, the checklist and the card-stack pattern prescribe `.rect(cornerRadius: .containerConcentric)`; no compiled example uses it.  
_skills/liquid-glass/SKILL.md:87_

- **Correct / new info:** Apple's concentric-corner API is ConcentricRectangle (26.0 on all platforms incl. visionOS) with Shape.rect(corners:isUniform:) taking Edge.Corner.Style and `static func concentric(minimum: Edge.Corner.Style?) -> Edge.Corner.Style`; the ConcentricRectangle page and its related symbols contain no 'containerConcentric'. View.containerShape(_:) sets 'the container shape to use for any container relative shape or concentric rectangle within this view.'
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/concentricrectangle.json (apple-doc, confidence medium)
- **Action:** Confirm in Xcode 27 whether `.containerConcentric` exists; if not, replace everywhere with the documented ConcentricRectangle / Edge.Corner.Style.concentric forms plus containerShape(_:) guidance, and compile the snippet in the Gallery.

```swift
struct ConcentricRectangle
```

### 11. `compile-risk` — 01 §10 (lines 418-424) and patterns/glass-search-field.md (lines 58-62) both wrap `DefaultToolbarItem(kind: .search, placement: .bottomBar)` inside `ToolbarItem(placement: .bottomBar) { ... }`.  
_skills/liquid-glass/references/01-api-reference.md:422_

- **Correct / new info:** DefaultToolbarItem conforms to ToolbarContent and not to View ('A toolbar item that represents a system component.'), so it belongs directly in the .toolbar builder, not inside a ToolbarItem's View content. The same bug is duplicated in two files, which shows how much duplication costs.
- **Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, visionOS 26.0+, watchOS 26.0+
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/defaulttoolbaritem.json (apple-doc, confidence high)
- **Action:** Change both to `.toolbar { DefaultToolbarItem(kind: .search, placement: .bottomBar) }`, keep one canonical copy (in 01) and link to it from the pattern; verify the 'pins the search field above the tab bar' claim.

```swift
nonisolated struct DefaultToolbarItem; init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement)
```

### 12. `skill-authoring` — 01 states it is 'Sourced from Xcode 26 SDK headers'; only examples/*.swift are compiled (Gallery/project.yml), while 124 ```swift fences in references/ (101) and patterns/ (23) are never compiled. Commit 870fda1 fixed nonexistent APIs in examples but left the same APIs in the prose.  
_skills/liquid-glass/references/01-api-reference.md:3_

- **Correct / new info:** Best practices: 'Validation/verification steps for critical operations'; 'Feedback loops included for quality-critical tasks'; prefer scripts for deterministic operations. The provenance claim is contradicted by the signatures that diverge from Apple docs (isEnabled, DefaultToolbarItem, containerConcentric).
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence high)
- **Action:** Add a compile harness: a script that extracts every ```swift fence from references/ and patterns/ into stub files (wrapped in a View body where needed) and a Gallery 'Snippets' target, built in CI with Xcode 26 and Xcode 27 (macOS runner). Replace the provenance line with per-section links to Apple doc pages; record 'verified against Xcode 27.x on <date>' in README / metadata.verified-sdk rather than in SKILL.md.

### 13. `skill-authoring` — Seven reference files exceed 100 lines with no table of contents at the top: 01-api-reference (587), 07-anti-patterns (365), 04-motion-and-interaction (267), 05-accessibility (190), 06-performance (187), 02-hig-principles (175), 03-design-tokens (155); the checklist is 100.  
_skills/liquid-glass/references/01-api-reference.md:1_

- **Correct / new info:** Best practices: 'For reference files longer than 100 lines, include a table of contents at the top. This ensures Claude can see the full scope of available information even when previewing with partial reads.' Spec: 'Keep individual reference files focused. Agents load these on demand, so smaller files mean less use of context.'
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence high)
- **Action:** Add a '## Contents' list to each file; split 01 into focused files (core glass API + morphing; system chrome: toolbar/tab/search/sheet; availability matrix) so a task loads only what it needs.

### 14. `inconsistency` — The Parameters table says Glass variants are in '(see § 4)', but the Glass type is § 2 (§ 4 is glassEffectID). The SKILL.md reading-order table (lines 46-50) cites bare names like `01-api-reference.md` and `07-anti-patterns.md` without `references/`. Nested pointers use mixed forms: 01 line 499 `references/05-accessibility.md`, but 02 lines 135/145 and 04 line 207 use bare names.  
_skills/liquid-glass/references/01-api-reference.md:27_

- **Correct / new info:** Best practices: use forward-slash paths relative to the skill root, make links explicit, and keep references one level deep from SKILL.md. Ambiguous bare names make Claude search instead of open.
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence high)
- **Action:** Fix '§ 4' to '§ 2'. Use markdown links relative to the skill root everywhere, e.g. [references/05-accessibility.md](references/05-accessibility.md), and add anchors for section references.

### 15. `skill-authoring` — SKILL.md points to `patterns/` and `examples/` only as directories ('examples/ (closest match)'). There is no index of what each of the 6 patterns and 9 examples demonstrates. The examples total about 3,300 lines (roughly 19k tokens estimated); 09 is 637 lines and 08 is 481 lines.  
_skills/liquid-glass/SKILL.md:36_

- **Correct / new info:** Claude Code: 'Reference supporting files from SKILL.md so Claude knows what each file contains and when to load it.' Best practices: SKILL.md 'serves as an overview that points Claude to detailed materials as needed'; 'Name files descriptively'; avoid loading irrelevant context.
- **Evidence:** https://code.claude.com/docs/en/skills (anthropic-doc, confidence high)
- **Action:** Add an index table to SKILL.md listing, for each file, the screen type, the APIs and patterns it shows, the minimum OS (26 or 27) and the line count. List each pattern file individually. Split 09 (app shell / Today screen / FAB menu), or add a MARK index comment at the top of 08 and 09.

### 16. `inconsistency` — The same content is repeated across files and has already drifted. The morphing-menu recipe appears in 01 §4, 04, patterns/glass-floating-toolbar.md and examples 04/09. The zoom transition appears in 01 §11, 04 and glass-modal-sheet.md. Accessibility adaptations appear in 01 §13 and 05; animation curves in 03 and 04; and there are three checklists (05 audit, 06 quick wins, pre-ship). Reduce Motion is described three ways: 'kills morphing, shimmer, specular animation' (01:496), 'state changes still happen, but instantly' (04:215) and 'morphing replaced with cross-fade or hard cut' (05:15).  
_skills/liquid-glass/references/04-motion-and-interaction.md:215_

- **Correct / new info:** Best practices: concise skills ('Does this paragraph justify its token cost?') and consistent statements. Each duplicated API fact multiplies the edits needed for iOS 27 and the risk of drift (the DefaultToolbarItem bug is duplicated too).
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence high)
- **Action:** Choose one source of truth: 01 for API facts and signatures, 05 for accessibility behavior (verified against Apple docs), and the pre-ship checklist as the only checklist. The other files keep a one-line rule and link to the anchor. Settle Reduce Motion behavior from an Apple source, or remove the claim.

### 17. `skill-authoring` — Wording is tied to dates and versions throughout: 'Full-screen examples that compile in Xcode 26' (SKILL 37), the title 'Liquid Glass — iOS 26 SwiftUI Skill' (line 8), plugin.json description '...compile in Xcode 26', README line 40 'all compile in Xcode 26', checklist line 3 'any iOS 26 build', 'You're shipping the iOS 7 look in 2026' (07:299), 'drop-shadows on everything in 2010' (06:79), 'Tinted Mode (iOS 26.1+)', 'SF Symbols 7'. About 48 lines in the markdown mention iOS 26, Xcode 26, WWDC25 or a year.  
_skills/liquid-glass/SKILL.md:37_

- **Correct / new info:** Best practices: 'Avoid time-sensitive information'. Put current guidance under 'Current method' and history in a collapsed 'Old patterns' section; checklist item: 'No time-sensitive information (or in "old patterns" section)'.
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence high)
- **Action:** Rewrite SKILL.md and the references to be version-neutral ('iOS 26 and later'; 'introduced in iOS 26, refined in iOS 27'). Keep per-version facts only in an availability matrix and a what's-new-in-27 file, with iOS 26.0-specific notes in a collapsed <details> 'Old patterns' section. Move 'verified with Xcode 26.3 / 27.x' claims to the README and metadata.verified-sdk. Drop the year jokes.

### 18. `skill-authoring` — The skill has no iOS 27 / Xcode 27 content; there is no 'what's new in 27' reference.

- **Correct / new info:** Apple's SwiftUI updates page (sections September 2026 and June 2026) lists additions that affect chrome and glass:
- View.toolbarMinimizationBehavior(_:for:), verified introducedAt 27.0 on all platforms, with example `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)`.
- TabRole.prominent ('place the tab in a separate, trailing position of the tab bar').
- ToolbarOverflowMenu, ToolbarContent.visibilityPriority(_:) and ToolbarItemPlacement.topBarPinnedTrailing.
- NavigationTransition.crossFade for sheets.
- ContentBuilder (Xcode 27; 'unified replacement for type-specific builders like ToolbarContentBuilder').
- Vertical-axis toolbar APIs (EnvironmentValues.toolbarVerticalEdge, toolbarVerticalBehavior(_:), axisBehavior(_:) with ToolbarItemAxisBehavior, toolbarVerticalCompressionBehavior(_:)).
- A new HIG page, 'designing-for-iphone-duo'.
The parts of the updates page I read listed no changes to the core Glass or glassEffect symbols.
- **Availability:** iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, tvOS 27.0+, visionOS 27.0+, watchOS 27.0+
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/updates/swiftui.json (apple-doc, confidence medium)
- **Action:** Add references/08-whats-new-ios27.md (with a table of contents). For each symbol give its verbatim declaration, availability and how it relates to glass, after per-symbol verification in the API phase. Link it from the SKILL.md reading table ('Adopting iOS 27 chrome changes'). Add iOS 27 variants to the tab-bar, nav-bar, toolbar and sheet patterns, gated with #available.

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

### 19. `skill-authoring` — Checklist: 'No @available(iOS 26.0, *) left over from migration (entire target is 26+)'; the SKILL.md scope says 'iOS 26+ only'; the SKILL.md reading-table row 'Migrating an old screen' (line 49) is ambiguous now; there is no API availability matrix.  
_skills/liquid-glass/checklists/pre-ship-checklist.md:85_

- **Correct / new info:** iOS 27 APIs such as toolbarMinimizationBehavior(_:for:) are introducedAt 27.0, so an app that keeps a 26.0 deployment target needs `if #available(iOS 27.0, macOS 27.0, *)` or `@available` gating. 'Remove @available' is wrong advice for apps that support both 26 and 27.
- **Evidence:** https://developer.apple.com/tutorials/data/documentation/swiftui/view/toolbarminimizationbehavior(_:for:).json (apple-doc, confidence high)
- **Action:** Add references/09-migrating-26-to-27.md covering:
- choosing a deployment target;
- the gating pattern;
- visual and behavior changes to re-check (verify each);
- deprecations;
- Xcode 27 rebuild notes (e.g. ContentBuilder).
Add an availability matrix (symbol × iOS/iPadOS/Mac Catalyst/macOS/watchOS/tvOS/visionOS × introduced version). Rewrite the checklist Build section as 'If deployment target is 26.x, every 27.0 API is behind #available'. Split the SKILL.md table row into 'Adopting Liquid Glass from pre-26 UI' and 'Moving an iOS 26 app to iOS 27'.

### 20. `design-guidance` — The HIG distillation leaves out Apple's explicit material guidance:
- when to use the clear variant and when to dim behind it;
- the content-layer exception for sliders and toggles;
- 'use sparingly';
- the user-selectable Liquid Glass look.
It asserts an unsourced 'Maximum two glass layers stacked' rule.  
_skills/liquid-glass/references/02-hig-principles.md:63_

- **Correct / new info:** HIG Materials:
- 'Only use clear Liquid Glass for components that appear over visually rich backgrounds.'
- 'If the underlying content is bright, consider adding a dark dimming layer of 35% opacity.'
- 'If the underlying content is sufficiently dark, or if you use standard media playback controls from AVKit that provide their own dimming layer, you don't need to apply a dimming layer.'
- 'Use the regular variant when background content might create legibility issues, or when components have a significant amount of text'.
- 'Use Liquid Glass effects sparingly.'
- The variants 'can differ in response to certain system settings, like if people choose a preferred look for Liquid Glass in their device's settings'.
The page's change log ends at 'September 9, 2025 — Updated guidance for Liquid Glass.'
- **Evidence:** https://developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json (apple-other, confidence high)
- **Action:** Add these rules, quoted and cited, to 02 and 03 (a dimming-layer token, clear vs regular decision). Use HIG wording for the user glass-look setting instead of 'Tinted Mode', and mark 'maximum two layers' as a heuristic or remove it. Re-check the HIG change log after the iOS 27 release.

### 21. `unverifiable-claim` — Unsourced numbers and specifics:
- '1 container of 5 children is ~5× cheaper' (06:25) and '1–3 ms/frame on A13–A14' (06:60);
- Instruments phases named 'GlassEffect: layout' and 'GlassEffect: composite' (06:148-149);
- checklist '~95% of glass-related ship issues' (line 3), '> 20 cells' (63), '> 8 elements' (66), and 'iPhone 11 (oldest supported)' (70);
- 01: 'Swift 6.1+' (534) and 'Hardware floor ... iPhone 11' (536);
- 05: 'Tinted Mode ... Settings → Accessibility → Display'.  
_skills/liquid-glass/references/06-performance.md:25_

- **Correct / new info:** Best practices: 'No "voodoo constants" (all values justified)'. Apple's GlassEffectContainer page only says spacing controls blending ('The higher the spacing, the sooner blending begins'); none of these numbers appear in the Apple pages I checked. The iOS 27 device list could not be confirmed from Apple; secondary sources conflict, so 'iPhone 11 oldest supported' must be re-verified.
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence medium)
- **Action:** Remove these, cite a source, or label them 'heuristic, unmeasured'. Verify Instruments template and phase names in Xcode 27. Verify the iOS 27 supported-device list on apple.com before keeping device-floor claims. Drop 'Swift 6.1+' or replace it with the verified Swift version that ships with Xcode 26 and 27.

### 22. `skill-authoring` — Example code embeds the author's personal iCloud address as the 'Apple ID' placeholder (line 24) and the author's first name (05-DashboardScreen line 26, 09-HealthTodayScreen line 131). 09 line 5 carries over chat text: '(the "menu bar" the user wanted to see)'.  
_skills/liquid-glass/examples/01-SettingsScreen.swift:24_

- **Correct / new info:** Claude copies example code verbatim into users' apps, so personal data spreads into third-party codebases. Anthropic's directory scan checks plugin files, and best practices require content that serves the agent, not authoring-session text.
- **Evidence:** https://claude.com/docs/plugins/pre-submission-checklist (anthropic-doc, confidence high)
- **Action:** Replace the email with a reserved-domain placeholder (e.g. appleseed@example.com) and the name with a neutral placeholder; delete the leftover chat comment; grep the repo for other personal identifiers before release.

### 23. `skill-authoring` — SKILL.md has a reading-order table but no step-by-step build/review workflow. The pre-ship checklist is not set up as a validate → fix → repeat loop, and there are no scripts.  
_skills/liquid-glass/SKILL.md:42_

- **Correct / new info:** Best practices:
- 'For particularly complex workflows, provide a checklist that Claude can copy into its response and check off as it progresses'
- 'Common pattern: Run validator → fix errors → repeat'
- 'Prefer scripts for deterministic operations'
- 'Make execution intent clear'
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence medium)
- **Action:** Add a copyable 'Workflow' checklist to SKILL.md:
1. Detect the deployment target and platforms.
2. Classify each view as content layer or functional layer.
3. Pick the API from the decision tree.
4. Write the code.
5. Run scripts/check_glass.sh, a read-only grep linter. It flags materials faking glass on controls, glassEffect inside List or ForEach rows, nested glassEffect, .linear animations on glass state, the nonexistent isEnabled: parameter, two or more glass siblings without a GlassEffectContainer, and 27.0 APIs without #available when the target is 26.
6. Walk the pre-ship checklist, fix and repeat.
Document the script in the README so the directory security scan sees what it runs.

### 24. `skill-authoring` — The plugin has no eval suite, so triggering on iOS 27 / Xcode 27 phrasing and output quality are untested.

- **Correct / new info:** Claude Code plugin evals:
- Cases live under evals/ as <case>/prompt.md plus graders.
- A trigger grader is `type: tool_used`, `tool: Skill`, `input_match: '"skill"\s*:\s*"(?:[\w-]+:)?your-skill-name"'`.
- The docs note: 'The most common first finding is a Δ near zero with the case's tool_used: Skill grader failing, which means Claude isn't choosing your skill on natural phrasing. Adjust the skill's description'.
Best practices: 'At least three evaluations created'; 'Tested with Haiku, Sonnet, and Opus'.
- **Evidence:** https://code.claude.com/docs/en/plugin-evals (anthropic-doc, confidence high)
- **Action:** Add evals/ (or run `claude plugin eval init`).
- Positive cases: 'Add a floating glass toolbar to this iOS 27 photo editor', 'Make the nav bar minimize on scroll in Xcode 27', 'Audit this SwiftUI view for Liquid Glass anti-patterns', 'Move our iOS 26 tab bar to the iOS 27 APIs'.
- Negative cases: 'UIVisualEffectView blur in UIKit', 'Jetpack Compose glassmorphism'.
- Graders: a tool_used Skill grader on liquid-glass, plus llm rubric graders (no isEnabled, no glass on list rows, #available gating).
Run `claude plugin eval .` after each description change and before each release, across Haiku, Sonnet and Opus.

### 25. `skill-authoring` — marketplace.json: top-level description 'iOS 26 Liquid Glass tooling for Claude Code.' (line 8); entry description 'Comprehensive iOS 26 Liquid Glass SwiftUI design skill ...' (13); entry 'version': '1.0.0' (14) duplicates plugin.json; tags only include ios26 (16). plugin.json description (line 4) says 'iOS 26 ... compile in Xcode 26' and its keywords (13-23) only include ios26. No displayName.  
_.claude-plugin/marketplace.json:13_

- **Correct / new info:** Marketplace reference:
- Display fields: 'For a field you set on the entry, users see the entry's value, even when plugin.json sets a different one.' So the entry's iOS-26-only description will hide an updated plugin.json description.
- Version: 'When plugin.json also sets version, plugin.json takes precedence and claude plugin validate warns' ('Entry declares version "x" but <path>/plugin.json says "y". At install time, plugin.json wins').
- keywords are 'Discovery tags'; displayName is the 'Name shown in UI in place of name'.
- A top-level marketplace description is valid.
- **Evidence:** https://code.claude.com/docs/en/plugins/marketplace-reference (anthropic-doc, confidence high)
- **Action:** Update the top-level, entry and plugin.json descriptions to say iOS 26 and iOS 27 (drop the 'compile in Xcode 26' wording). Remove the entry version, or keep it equal to plugin.json. Add keywords and tags: ios27, ipados, macos, watchos, tvos, xcode27, wwdc26, glasseffect, toolbar, tabview. Add "displayName": "Liquid Glass". Run `claude plugin validate --strict .` in CI.

### 26. `skill-authoring` — The README embeds bundled screenshots with HTML <img> tags inside a <table> (lines 5-26). The repository has no LICENSE file; only "license": "MIT" in plugin.json. README sources line 119 cites only WWDC25.  
_README.md:7_

- **Correct / new info:** Directory pre-submission checklist:
- 'To show a bundled image in the README, use Markdown image syntax.' (result if not: 'Held for a reviewer').
- 'Add a LICENSE file to the plugin folder, or set license in plugin.json'. The plugin.json key satisfies the check, but MIT terms expect the notice text to ship.
- 'Set description, author, and version'.
The portal 'applies additional directory rules that the CLI doesn't check'.
- **Evidence:** https://claude.com/docs/plugins/pre-submission-checklist (anthropic-doc, confidence medium)
- **Action:** Convert the screenshot grid to Markdown image syntax, add an MIT LICENSE file, and update the README for iOS 27 (activation, scope, sources incl. WWDC26, verified Xcode versions). Re-run the portal Validate after pushing 2.0.0.

### 27. `skill-authoring` — Terminology is mixed. One concept is called 'navigation layer', 'chrome', 'chrome layer' and 'navigation/chrome layer'. Container spacing is called 'morph threshold', 'spacing' and 'blend distance'. The user's glass-look setting is called 'Tinted Mode'.  
_skills/liquid-glass/SKILL.md:84_

- **Correct / new info:** Best practices: 'Choose one term and use it throughout the Skill.' Apple HIG wording: Liquid Glass 'forms a distinct functional layer for controls and navigation elements ... that floats above the content layer'. HIG calls the setting 'a preferred look for Liquid Glass in their device's settings'. GlassEffectContainer docs: spacing controls when shapes 'begin to blend'.
- **Evidence:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (anthropic-doc, confidence medium)
- **Action:** Add a 5-line glossary to SKILL.md using Apple's terms ('functional layer' vs 'content layer', 'spacing (blend distance)', 'Liquid Glass look setting') and normalize every file to it.

## Symbols (8)

### `View.glassEffect(_:in:)`

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 (not beta, not deprecated; visionOS not listed)
- **Members:** glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()
- **Doc:** https://developer.apple.com/tutorials/data/documentation/swiftui/view/glasseffect(_:in:).json
- **Skill uses it correctly:** NO
- **Notes:** The skill documents a nonexistent isEnabled parameter (01 §1; prose in 02, 06, 07) and lists visionOS 26 as a target. The compiled examples use only the two documented parameters.

### `Glass`

```swift
struct Glass (DocC type page exists; the declaration tokens were not quoted verbatim by the fetch)
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 (visionOS not listed)
- **Members:** static var clear: Glass, static var identity: Glass, static var regular: Glass, func interactive(Bool) -> Glass, func tint(Color?) -> Glass
- **Doc:** https://developer.apple.com/tutorials/data/documentation/swiftui/glass.json
- **Skill uses it correctly:** yes
- **Notes:** Variants and modifiers match the skill's code usage. The skill writes tint(_ color: Color), but Apple's parameter is Color?. The platform claims (visionOS) are wrong. identity is documented as 'your content remains unaffected as if no glass effect was applied', so conditional glass should use it instead of isEnabled.

### `GlassEffectContainer`

```swift
@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0 (visionOS not listed)
- **Members:** init(spacing: CGFloat?, content: () -> Content)
- **Doc:** https://developer.apple.com/tutorials/data/documentation/swiftui/glasseffectcontainer.json
- **Skill uses it correctly:** yes
- **Notes:** Usage like GlassEffectContainer(spacing: 12) { ... } matches Apple. The skill's 01 §3 also lists a separate init(@ViewBuilder content:) overload, which is not in Apple's topics list; verify whether spacing has a default. Apple: 'The higher the spacing, the sooner blending begins'. The skill's performance numbers ('~5× cheaper') are not in Apple docs.

### `ConcentricRectangle`

```swift
struct ConcentricRectangle
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** init(), init(corners:isUniform:), init(topLeadingCorner:topTrailingCorner:bottomLeadingCorner:bottomTrailingCorner:), init(uniformBottomCorners:topLeadingCorner:topTrailingCorner:), init(uniformLeadingCorners:topTrailingCorner:bottomTrailingCorner:), init(uniformLeadingCorners:uniformTrailingCorners:), init(uniformTopCorners:bottomLeadingCorner:bottomTrailingCorner:), init(uniformTopCorners:uniformBottomCorners:), init(uniformTrailingCorners:topLeadingCorner:bottomLeadingCorner:); related: static func concentric(minimum: Edge.Corner.Style?) -> Edge.Corner.Style
- **Doc:** https://developer.apple.com/tutorials/data/documentation/swiftui/concentricrectangle.json
- **Skill uses it correctly:** NO
- **Notes:** The skill instead prescribes `.rect(cornerRadius: .containerConcentric)` in about seven places. 'containerConcentric' does not appear on this page or its related symbols, so it should be checked in Xcode 27 and replaced with the documented concentric API.

### `DefaultToolbarItem`

```swift
nonisolated struct DefaultToolbarItem
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0
- **Members:** init(kind: ToolbarDefaultItemKind, placement: ToolbarItemPlacement); conforms to ToolbarContent (not View)
- **Doc:** https://developer.apple.com/tutorials/data/documentation/swiftui/defaulttoolbaritem.json
- **Skill uses it correctly:** NO
- **Notes:** 01 §10 and patterns/glass-search-field.md wrap it inside ToolbarItem { } (View content). Because it is ToolbarContent, it should be placed directly in .toolbar { }.

### `View.toolbarMinimizationBehavior(_:for:)`

```swift
nonisolated func toolbarMinimizationBehavior(_ behavior: ToolbarMinimizationBehavior, for bars: ToolbarPlacement...) -> some View
```

- **Availability:** iOS 27.0, iPadOS 27.0, Mac Catalyst 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 27.0 (not beta, not deprecated)
- **Members:** behavior: ToolbarMinimizationBehavior, bars: ToolbarPlacement... ; related: toolbarMinimizationRestoration(_:for:), toolbarMinimizationSafeAreaAdjustment(_:for:)
- **Doc:** https://developer.apple.com/tutorials/data/documentation/swiftui/view/toolbarminimizationbehavior(_:for:).json
- **Skill uses it correctly:** NO
- **Notes:** New in 27 and not covered by the skill. Discussion: 'The supported placement is navigationBar. When the navigation bar minimizes, an integrated top tab bar will also minimize.' Example: .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar). Needs #available gating when the deployment target is 26.

### `TabRole`

```swift
struct TabRole
```

- **Availability:** iOS 18.0, iPadOS 18.0, Mac Catalyst 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, watchOS 11.0 (type level; no per-member availability shown)
- **Members:** static var prominent: TabRole, static var search: TabRole
- **Doc:** https://developer.apple.com/tutorials/data/documentation/swiftui/tabrole.json
- **Skill uses it correctly:** yes
- **Notes:** The skill uses only .search, which is correct. Apple's SwiftUI updates page (June 2026) lists the new `prominent` role, which places the tab 'in a separate, trailing position of the tab bar'; the skill doesn't cover it. Per-member availability needs confirming (likely 27.0).

### `View.tabBarMinimizeBehavior(_:)`

```swift
nonisolated func tabBarMinimizeBehavior(_ behavior: TabBarMinimizeBehavior) -> some View
```

- **Availability:** iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, watchOS 26.0 (not deprecated as of fetch)
- **Members:** behavior: TabBarMinimizeBehavior
- **Doc:** https://developer.apple.com/tutorials/data/documentation/swiftui/view/tabbarminimizebehavior(_:).json
- **Skill uses it correctly:** yes
- **Notes:** The skill's .tabBarMinimizeBehavior(.onScrollDown) usage matches Apple's example. No deprecation or replacement text was found; the 27 toolbarMinimizationBehavior(_:for:) is a separate modifier for the navigation bar.

