# liquid-glass

A Claude Code **plugin + skill** for building iOS 26+ SwiftUI interfaces with Apple's **Liquid Glass** design language.

## What's inside

- **API reference** — every Liquid Glass SwiftUI symbol with exact signatures (`.glassEffect`, `GlassEffectContainer`, `Glass`, `.glassEffectID`, `.glassEffectUnion`, button styles, toolbar/nav/tab integration, `.tabBarMinimizeBehavior`, `.tabViewBottomAccessory`, …)
- **HIG principles** — Hierarchy, Harmony, Consistency distilled into actionable rules
- **Design tokens** — radii, spacing, tint palette, typography, animation curves
- **Motion & interaction** — morphing recipe, interactive glass, symbol-effect choreography, zoom transitions
- **Accessibility** — Reduce Transparency, Increase Contrast, Smart Invert, Dynamic Type, VoiceOver
- **Performance** — GPU cost model, batching rules, when glass is the wrong tool
- **Anti-patterns** — 15 ❌/✅ pairs of the most common mistakes
- **Pattern library** — copy-paste recipes for nav bar, tab bar, floating toolbar, card stack, modal sheet, search field
- **Nine full-screen examples** — Settings, Music Player, Onboarding, Photo Detail, Dashboard, Chat, Profile, Login, Health App (full TabView shell) — all compile in Xcode 26
- **Pre-ship checklist** with diagnostic table

## Install as a plugin (recommended)

In Claude Code:

```
/plugin marketplace add heyparsadev/liquid-glass-skill
/plugin install liquid-glass@liquid-glass
```

That's it — the skill activates automatically the next time you write SwiftUI for iOS 26+.

To update later:
```
/plugin marketplace update liquid-glass
```

To remove:
```
/plugin uninstall liquid-glass@liquid-glass
```

## Install as a bare skill (without the plugin system)

Symlink the inner skill folder:

```sh
git clone https://github.com/heyparsadev/liquid-glass-skill.git
ln -s "$(pwd)/liquid-glass-skill/skills/liquid-glass" ~/.claude/skills/liquid-glass
```

Or for a single project:
```sh
mkdir -p .claude/skills
ln -s /path/to/liquid-glass-skill/skills/liquid-glass .claude/skills/liquid-glass
```

## When it activates

- Editing SwiftUI in a project with iOS / iPadOS / macOS / watchOS / tvOS / visionOS deployment target ≥ **26.0**
- You mention any of: *liquid glass*, *iOS 26*, *macOS Tahoe*, *glass effect*, *glassEffect*, *GlassEffectContainer*, *glass button*, *.glassProminent*, *tab bar minimize*
- You ask to redesign / modernize a SwiftUI screen

## Scope

- ✅ SwiftUI
- ❌ UIKit / AppKit (separate skill)
- ❌ iOS < 26 fallbacks (intentionally — keeps generated code clean)
- ❌ React Native / Flutter

## Repository layout

```
.claude-plugin/
  plugin.json              ← plugin manifest
  marketplace.json         ← so this repo can also serve as a marketplace
skills/
  liquid-glass/
    SKILL.md               ← entry point, activation rules, golden rules
    references/            ← API + HIG + tokens + motion + a11y + perf + anti-patterns
    patterns/              ← copy-paste recipes per surface
    examples/              ← nine full-screen SwiftUI demos
    checklists/            ← pre-ship review
README.md                  ← this file
```

## License

MIT. Documentation derived from Apple's public WWDC25 sessions and developer documentation. Example code is original.
