# liquid-glass-skill

A comprehensive Claude Code skill for building iOS 26+ SwiftUI interfaces with Apple's **Liquid Glass** design language.

## What's inside

- Complete SwiftUI API reference for every Liquid Glass symbol (`.glassEffect`, `GlassEffectContainer`, `Glass`, `.glassEffectID`, button styles, toolbar/nav/tab integration)
- Apple HIG principles distilled into actionable rules
- Design tokens, motion, accessibility, performance
- Anti-patterns with concrete ✅ / ❌ pairs
- Pattern library for nav bars, tab bars, toolbars, cards, sheets, search
- Seven full-screen SwiftUI examples that compile in Xcode 26
- Pre-submission checklist

## Installation

### As a global skill

```sh
ln -s "$(pwd)" ~/.claude/skills/liquid-glass
```

### As a project skill

```sh
mkdir -p .claude/skills
ln -s /path/to/liquid-glass-skill .claude/skills/liquid-glass
```

After linking, Claude Code auto-loads `SKILL.md` and consults the references on demand.

## When it activates

- SwiftUI work targeting iOS / iPadOS / macOS / watchOS / tvOS / visionOS **26 or later**
- Any mention of Liquid Glass, `glassEffect`, `GlassEffectContainer`, "iOS 26 design"
- Modernization requests on existing SwiftUI screens

## Scope

- ✅ SwiftUI
- ❌ UIKit / AppKit (separate skill)
- ❌ iOS < 26 fallbacks (intentionally — keep code clean)
- ❌ React Native / Flutter / Expo

## Layout

```
SKILL.md                  ← entry point
references/               ← API + HIG + tokens + motion + a11y + perf + anti-patterns
patterns/                 ← copy-paste recipes per surface
examples/                 ← full screens that build in Xcode 26
checklists/               ← pre-ship review
```

## License

Documentation derived from Apple's public WWDC25 sessions and developer documentation. Example code is original and provided as-is.
