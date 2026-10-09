#!/usr/bin/env python3
"""Lint SwiftUI sources for Liquid Glass mistakes.

Read-only. Standard library only. Reports three severities:

  error  code that won't compile against the iOS 26/27 SDKs, or is plainly wrong
  warn   a Liquid Glass design rule is broken (glass on chrome, faked glass, ...)
  info   availability gating or a migration worth doing

Usage:
  python3 check_glass.py [paths ...] [--target 26.0] [--format text|json]
                         [--min-severity info|warn|error] [--strict]

Paths may be files or directories (searched recursively for .swift, .plist,
.pbxproj, project.yml and Package.swift). With --target, APIs newer than the
deployment target are reported unless they sit inside a matching
`if #available`, `guard #available` or `@available` scope.

Silence a finding by putting `check-glass: ignore` (all rules) or
`check-glass: ignore=<rule-id>[,<rule-id>]` in a comment on the same line.

Exit status: 1 if any error is reported (or any warn with --strict), else 0.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, asdict

SEVERITY_RANK = {"info": 0, "warn": 1, "error": 2}
SOURCE_SUFFIXES = (".swift",)
CONFIG_NAMES = ("project.yml", "project.yaml", "Package.swift")
CONFIG_SUFFIXES = (".plist", ".pbxproj", ".xcconfig")


@dataclass
class Finding:
    path: str
    line: int
    column: int
    severity: str
    rule: str
    message: str
    fix: str


# --------------------------------------------------------------------------
# Source preparation: blank out comments and string literals, keep offsets.
# --------------------------------------------------------------------------

def strip_comments_and_strings(src: str) -> str:
    """Return src with comments and string-literal contents replaced by spaces.

    Newlines are preserved so offsets, lines and columns stay valid. String
    interpolations are kept as code, so `"\\(a ? "x" : "y")"` is handled.
    """
    out = list(src)
    n = len(src)
    i = 0
    # Stack of modes for nested interpolation: ("code", paren_depth) or ("str", kind, hashes)
    stack: list[tuple] = [("code", 0)]

    def blank(a: int, b: int) -> None:
        for k in range(a, min(b, n)):
            if out[k] != "\n":
                out[k] = " "

    while i < n:
        mode = stack[-1]
        c = src[i]
        if mode[0] == "code":
            if src.startswith("//", i):
                j = src.find("\n", i)
                j = n if j == -1 else j
                blank(i, j)
                i = j
                continue
            if src.startswith("/*", i):
                depth, j = 1, i + 2
                while j < n and depth:
                    if src.startswith("/*", j):
                        depth, j = depth + 1, j + 2
                    elif src.startswith("*/", j):
                        depth, j = depth - 1, j + 2
                    else:
                        j += 1
                blank(i, j)
                i = j
                continue
            # String start, possibly raw (#"...") and/or multi-line (""")
            m = re.match(r'(#*)("""|")', src[i:i + 8])
            if m:
                hashes = len(m.group(1))
                kind = m.group(2)
                stack.append(("str", kind, hashes))
                i += len(m.group(0))
                continue
            if c == "(":
                stack[-1] = ("code", mode[1] + 1)
            elif c == ")":
                if mode[1] == 0 and len(stack) > 1:
                    # end of an interpolation \( ... ) - back into the string
                    stack.pop()
                    i += 1
                    continue
                stack[-1] = ("code", max(0, mode[1] - 1))
            i += 1
            continue

        # inside a string literal
        _, kind, hashes = mode
        closing = kind + "#" * hashes
        escape = "\\" + "#" * hashes
        if src.startswith(escape + "(", i):
            blank(i, i + len(escape) + 1)
            i += len(escape) + 1
            stack.append(("code", 0))
            continue
        if src.startswith(escape, i):
            blank(i, i + len(escape) + 1)
            i += len(escape) + 1
            continue
        if src.startswith(closing, i):
            stack.pop()
            i += len(closing)
            continue
        if kind == '"' and c == "\n":   # unterminated single-line string: recover
            stack.pop()
            i += 1
            continue
        if c != "\n":
            out[i] = " "
        i += 1
    return "".join(out)


def matching(code: str, open_index: int) -> int:
    """Index of the bracket that closes code[open_index], or len(code)."""
    pairs = {"(": ")", "{": "}", "[": "]"}
    opener = code[open_index]
    closer = pairs[opener]
    depth = 0
    for k in range(open_index, len(code)):
        ch = code[k]
        if ch == opener:
            depth += 1
        elif ch == closer:
            depth -= 1
            if depth == 0:
                return k
    return len(code)


def split_top_level(args: str) -> list[str]:
    """Split a call's argument text on commas at bracket depth 0."""
    parts, depth, start = [], 0, 0
    for k, ch in enumerate(args):
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            parts.append(args[start:k])
            start = k + 1
    parts.append(args[start:])
    return [p.strip() for p in parts if p.strip()]


def top_level_members(expr: str) -> list[str]:
    """Member names chained at depth 0, e.g. '.regular.tint(.red).opacity(1)' -> ['regular','tint','opacity']."""
    names, depth, k = [], 0, 0
    while k < len(expr):
        ch = expr[k]
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "." and depth == 0:
            m = re.match(r"\.([A-Za-z_]\w*)", expr[k:])
            if m:
                names.append(m.group(1))
                k += len(m.group(0))
                continue
        k += 1
    return names


def modifier_chain_after(code: str, end_index: int, limit: int = 10) -> list[tuple[str, int]]:
    """Modifiers chained after code[end_index] (exclusive): [(name, offset), ...]."""
    chain = []
    k = end_index
    while len(chain) < limit:
        m = re.compile(r"\s*\.\s*([A-Za-z_]\w*)").match(code, k)
        if not m:
            break
        name, k = m.group(1), m.end()
        chain.append((name, m.start(1)))
        rest = re.compile(r"\s*([({])").match(code, k)
        while rest:
            close = matching(code, rest.start(1))
            k = close + 1
            rest = re.compile(r"\s*\{").match(code, k)   # trailing closure after (...)
    return chain


# --------------------------------------------------------------------------
# Availability scopes
# --------------------------------------------------------------------------

def normalize(version: tuple[int, ...]) -> tuple[int, ...]:
    return (tuple(version) + (0, 0, 0))[:3]


def parse_version(text: str) -> tuple[int, ...] | None:
    m = re.search(r"\biOS(?:ApplicationExtension)?\s+(\d+(?:\.\d+)*)", text)
    if not m:
        m = re.search(r"\b(?:iPadOS|macOS|tvOS|watchOS|visionOS|macCatalyst)\s+(\d+(?:\.\d+)*)", text)
    if not m:
        return None
    return normalize(tuple(int(p) for p in m.group(1).split(".")))


def availability_scopes(code: str) -> list[tuple[int, int, tuple[int, ...]]]:
    """(start, end, version) ranges where code may use APIs up to `version`."""
    scopes = []
    for m in re.finditer(r"(#available|@available|#unavailable)\s*\(", code):
        if m.group(1) == "#unavailable":
            continue
        args_open = m.end() - 1
        args_close = matching(code, args_open)
        version = parse_version(code[args_open:args_close])
        if version is None:
            continue
        before = code[max(0, m.start() - 12):m.start()]
        brace = code.find("{", args_close)
        if brace == -1:
            continue
        if m.group(1) == "@available":
            between = code[args_close:brace]
            if between.count("\n") > 4 or ";" in between:
                continue
            scopes.append((brace, matching(code, brace), version))
        elif re.search(r"\bguard\s*$", before):
            else_end = matching(code, brace)
            # the rest of the enclosing scope is available
            depth, k = 0, else_end + 1
            while k < len(code):
                if code[k] == "{":
                    depth += 1
                elif code[k] == "}":
                    if depth == 0:
                        break
                    depth -= 1
                k += 1
            scopes.append((else_end, k, version))
        else:
            scopes.append((brace, matching(code, brace), version))
    return scopes


def available_version_at(scopes, offset: int) -> tuple[int, ...]:
    best: tuple[int, ...] = (0, 0, 0)
    for start, end, version in scopes:
        if start <= offset <= end and version > best:
            best = version
    return best


# --------------------------------------------------------------------------
# Rules
# --------------------------------------------------------------------------

# (rule id, regex, introduced version, label)
VERSIONED_APIS = [
    # iOS 27.0
    ("ios27-api", r"\.toolbarMinimizationBehavior\s*\(", (27, 0), "toolbarMinimizationBehavior(_:for:)"),
    ("ios27-api", r"\.toolbarMinimizationRestoration\s*\(", (27, 0), "toolbarMinimizationRestoration(_:for:)"),
    ("ios27-api", r"\.toolbarMinimizationSafeAreaAdjustment\s*\(", (27, 0), "toolbarMinimizationSafeAreaAdjustment(_:for:)"),
    ("ios27-api", r"\.visibilityPriority\s*\(", (27, 0), "visibilityPriority(_:)"),
    ("ios27-api", r"\bToolbarOverflowMenu\b", (27, 0), "ToolbarOverflowMenu"),
    ("ios27-api", r"\.toolbarOverflowMenu\s*[({]", (27, 0), "toolbarOverflowMenu(content:)"),
    ("ios27-api", r"\.topBarPinnedTrailing\b", (27, 0), ".topBarPinnedTrailing"),
    ("ios27-api", r"\.contentMarginsRemoved\s*\(", (27, 0), "contentMarginsRemoved(_:)"),
    ("ios27-api", r"\brole\s*:\s*\.prominent\b", (27, 0), "TabRole.prominent"),
    ("ios27-api", r"\.navigationTransition\s*\(\s*\.crossFade\b", (27, 0), "NavigationTransition.crossFade"),
    ("ios27-api", r"\.presentationPlacement\s*\(", (27, 0), "presentationPlacement(_:)"),
    ("ios27-api", r"\.textInputBorderShape\s*\(", (27, 0), "textInputBorderShape(_:)"),
    ("ios27-api", r"\.textFieldStyle\s*\(\s*\.bordered\b", (27, 0), "TextFieldStyle.bordered"),
    ("ios27-api", r"\.pickerStyle\s*\(\s*\.tabs\b", (27, 0), "PickerStyle.tabs"),
    ("ios27-api", r"\bfor\s*:\s*\.statusBar\b", (27, 0), "ToolbarPlacement.statusBar"),
    ("ios27-api", r"\.concentricCornerRadii\b", (27, 0), "GeometryProxy.concentricCornerRadii"),
    ("ios27-api", r"\.swipeActionsContainer\s*\(|\.reorderContainer\s*\(|\.reorderable\s*\(", (27, 0), "swipe/reorder containers"),
    # iOS 27.1 (beta as of the 27.0 SDK)
    ("ios27-api", r"\.toolbarVerticalBehavior\s*\(|\btoolbarVerticalEdge\b|\.toolbarVerticalCompressionBehavior\s*\(|\.axisBehavior\s*\(", (27, 1), "vertical toolbar API (iOS 27.1, beta)"),
    ("ios27-api", r"\bReservedRegion\b|\.onHingeChange\s*\(|\bArrangementView\b", (27, 1), "iPhone Duo layout API (iOS 27.1, beta)"),
    # iOS 26.x
    ("ios26x-api", r"\.tabViewBottomAccessory\s*\(\s*isEnabled\s*:", (26, 1), "tabViewBottomAccessory(isEnabled:content:)"),
    ("ios26x-api", r"\.buttonStyle\s*\(\s*\.glass\s*\(", (26, 1), "PrimitiveButtonStyle.glass(_:)"),
    ("ios26x-api", r"\bGlassButtonStyle\s*\(\s*\.", (26, 1), "GlassButtonStyle.init(_:)"),
    ("ios26x-api", r"\baccessibilityReduceHighlightingEffects\b", (26, 4), "accessibilityReduceHighlightingEffects"),
    # iOS 26.0 (only relevant for targets below 26)
    ("ios26-api", r"\.glassEffect\s*\(|\bGlassEffectContainer\b|\.glassEffectID\s*\(|\.glassEffectUnion\s*\(|\.glassEffectTransition\s*\(", (26, 0), "Liquid Glass API"),
    ("ios26-api", r"\.buttonStyle\s*\(\s*\.glass(?:Prominent)?\s*\)", (26, 0), "glass button style"),
    ("ios26-api", r"\bToolbarSpacer\b|\.sharedBackgroundVisibility\s*\(|\bDefaultToolbarItem\b", (26, 0), "iOS 26 toolbar API"),
    ("ios26-api", r"\.tabBarMinimizeBehavior\s*\(|\.tabViewBottomAccessory\s*\(|\.searchToolbarBehavior\s*\(", (26, 0), "iOS 26 tab/search API"),
    ("ios26-api", r"\bConcentricRectangle\b|\.rect\s*\(\s*corners\s*:|\.backgroundExtensionEffect\s*\(|\.safeAreaBar\s*\(|\.scrollEdgeEffect(?:Style|Hidden)\s*\(", (26, 0), "iOS 26 layout API"),
]

SHAPESTYLE_TYPES = {
    "Color", "LinearGradient", "RadialGradient", "AngularGradient", "EllipticalGradient",
    "MeshGradient", "Material", "AnyShapeStyle", "ImagePaint", "HierarchicalShapeStyle",
    "TintShapeStyle", "ForegroundStyle", "BackgroundStyle", "SeparatorShapeStyle", "Gradient",
}

TOOLBAR_CONTENT_ONLY_MODIFIERS = ("sharedBackgroundVisibility", "visibilityPriority", "contentMarginsRemoved", "axisBehavior")


class Linter:
    def __init__(self, target: tuple[int, ...] | None):
        self.target = target
        self.findings: list[Finding] = []

    # -- helpers ---------------------------------------------------------
    def _add(self, path, raw, code, offset, severity, rule, message, fix=""):
        line = raw.count("\n", 0, offset) + 1
        line_start = raw.rfind("\n", 0, offset) + 1
        column = offset - line_start + 1
        line_text = raw[line_start:raw.find("\n", offset) if raw.find("\n", offset) != -1 else len(raw)]
        m = re.search(r"check-glass:\s*ignore(?:=([\w,\-]+))?", line_text)
        if m and (m.group(1) is None or rule in m.group(1).split(",")):
            return
        if any(f.path == path and f.line == line and f.rule == rule for f in self.findings):
            return
        self.findings.append(Finding(path, line, column, severity, rule, message, fix))

    @staticmethod
    def _calls(code, pattern):
        """Yield (match, open_paren_index, close_paren_index, args_text) for calls matching pattern + '('."""
        for m in re.finditer(pattern + r"\s*\(", code):
            open_i = m.end() - 1
            close_i = matching(code, open_i)
            yield m, open_i, close_i, code[open_i + 1:close_i]

    @staticmethod
    def _blocks(code, pattern):
        """Yield (match, brace_open, brace_close) for `pattern [ (args) ] {`."""
        for m in re.finditer(pattern, code):
            k = m.end()
            ws = re.compile(r"\s*").match(code, k)
            k = ws.end()
            if k < len(code) and code[k] == "(":
                k = matching(code, k) + 1
                k = re.compile(r"\s*").match(code, k).end()
            if k < len(code) and code[k] == "{":
                yield m, k, matching(code, k)

    # -- swift -----------------------------------------------------------
    def lint_swift(self, path: str, raw: str) -> None:
        code = strip_comments_and_strings(raw)
        scopes = availability_scopes(code)
        add = lambda off, sev, rule, msg, fix="": self._add(path, raw, code, off, sev, rule, msg, fix)

        # E: glassEffect / glassEffectTransition have no isEnabled:
        for m, o, c, args in self._calls(code, r"\.glassEffect"):
            for part in split_top_level(args):
                if re.match(r"isEnabled\s*:", part):
                    add(m.start(), "error", "glass-isenabled",
                        "glassEffect(_:in:) has no isEnabled: parameter.",
                        "Use `.glassEffect(isOn ? .regular : .identity, in: shape)`, or insert/remove the view inside a GlassEffectContainer.")
            first = split_top_level(args)[0] if split_top_level(args) else ""
            if not re.match(r"\w+\s*:", first) and "opacity" in top_level_members(first):
                add(m.start(), "error", "glass-opacity",
                    "Glass has no opacity(_:) member.",
                    "Don't fade glass. Use .regular/.clear/.identity, and insert or remove the view to animate it.")
        for m, o, c, args in self._calls(code, r"\.glassEffectTransition"):
            if re.search(r"(^|,)\s*isEnabled\s*:", args):
                add(m.start(), "error", "transition-isenabled",
                    "glassEffectTransition(_:) has no isEnabled: parameter.",
                    "Call `.glassEffectTransition(.materialize)` (or .matchedGeometry / .identity) only.")

        simple_errors = [
            (r"\.containerConcentric\b(?!\s*\()", "container-concentric",
             "`.containerConcentric` does not exist in SwiftUI.",
             "Use `.rect(corners: .concentric(minimum: 12), isUniform: true)` or `ConcentricRectangle()`, and declare `.containerShape(_:)` on the parent."),
            (r"\.scrollExtensionMode\s*\(", "scroll-extension-mode",
             "`scrollExtensionMode(_:)` does not exist.",
             "Use `.backgroundExtensionEffect()` on the background image."),
            (r"\.toolbarMinimizeBehavior\s*\(", "toolbar-minimize-behavior",
             "`toolbarMinimizeBehavior` is the pre-release spelling from the WWDC26 video; it doesn't exist in the SDK.",
             "Use `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)` (iOS 27)."),
            (r"\.searchToolbarBehavior\s*\(\s*\.minimized\b", "search-minimized",
             "SearchToolbarBehavior has `.minimize`, not `.minimized`.",
             "Use `.searchToolbarBehavior(.minimize)`."),
            (r"\bToolbarSpacer\s*\([^)]*\bspacing\s*:", "toolbar-spacer-spacing",
             "ToolbarSpacer has no spacing: argument.",
             "Use `ToolbarSpacer(.fixed, placement: …)` or `.flexible`."),
            (r"\.glass(?:Prominent)?\.tint\s*\(", "button-style-tint-chain",
             "`.glassProminent.tint(…)` is not a valid expression.",
             "Use `.buttonStyle(.glassProminent).tint(…)`."),
            (r"\.buttonStyle\s*\([^()]*\?\s*\.glass(?:Prominent)?\s*:\s*\.glass(?:Prominent)?\s*\)", "button-style-ternary",
             "`.glass` and `.glassProminent` are different types and can't be chosen with a ternary.",
             "Branch on the whole Button (if/else) and apply each style in its own branch."),
        ]
        for pattern, rule, msg, fix in simple_errors:
            for m in re.finditer(pattern, code):
                add(m.start(), "error", rule, msg, fix)

        if "tabViewBottomAccessoryPlacement" in code:
            for m in re.finditer(r"(?:==\s*|case\s+)\.collapsed\b", code):
                add(m.start(), "error", "accessory-collapsed",
                    "TabViewBottomAccessoryPlacement has `.expanded` and `.inline`; there is no `.collapsed`.",
                    "Use `.inline`. The environment value is Optional.")

        # ToolbarItem { … } blocks: nested DefaultToolbarItem, ToolbarContent-only modifiers, re-glassing
        for m, bo, bc in self._blocks(code, r"\bToolbarItem(?:Group)?\b"):
            body = code[bo:bc]
            for d in re.finditer(r"\bDefaultToolbarItem\s*\(", body):
                add(bo + d.start(), "error", "default-toolbar-item-nested",
                    "DefaultToolbarItem is ToolbarContent and can't sit inside ToolbarItem/ToolbarItemGroup.",
                    "Put `DefaultToolbarItem(kind: .search, placement: …)` directly in `.toolbar { }`.")
            for name in TOOLBAR_CONTENT_ONLY_MODIFIERS:
                for d in re.finditer(r"\.%s\s*\(" % name, body):
                    add(bo + d.start(), "error", "toolbar-content-modifier-on-view",
                        f"`{name}` is a ToolbarContent modifier; here it's applied to a view inside the item.",
                        "Move it after the ToolbarItem/ToolbarItemGroup's closing brace.")
            for d in re.finditer(r"\.glassEffect\s*\(", body):
                add(bo + d.start(), "warn", "glass-on-system-chrome",
                    "Toolbar items are already Liquid Glass; adding glassEffect stacks glass on glass.",
                    "Remove it. For the one primary action use `.buttonStyle(.glassProminent)`.")
            if re.search(r"\bMenu\b", body) and "ellipsis" in raw[bo:bc]:
                add(bo, "info", "custom-overflow-menu",
                    "A hand-made '…' menu in the toolbar.",
                    "On iOS 27 use `.toolbarOverflowMenu { … }` / `ToolbarOverflowMenu` (gate on a 26 target).")

        for m, bo, bc in self._blocks(code, r"\.tabViewBottomAccessory\b"):
            for d in re.finditer(r"\.glassEffect\s*\(|\.buttonStyle\s*\(\s*\.glass", code[bo:bc]):
                add(bo + d.start(), "warn", "glass-in-accessory",
                    "The tab bar accessory is already glass; glass controls inside it are glass on glass.",
                    "Use plain/borderless buttons inside the accessory.")

        for m, bo, bc in self._blocks(code, r"\bList\b"):
            for d in re.finditer(r"\.glassEffect\s*\(", code[bo:bc]):
                add(bo + d.start(), "warn", "glass-in-list",
                    "glassEffect inside a List: rows are content, and glass multiplies per row.",
                    "Keep rows plain; let the bars provide the glass.")

        for m, bo, bc in self._blocks(code, r"\bGlassEffectContainer\b"):
            for d in re.finditer(r"\bGlassEffectContainer\b", code[bo + 1:bc]):
                add(bo + 1 + d.start(), "warn", "nested-container",
                    "GlassEffectContainer nested inside another one.",
                    "Use one container per cluster of nearby glass.")

        # Faking glass / materials / bar backgrounds / sheet backgrounds
        for m in re.finditer(r"\.toolbarBackground\s*\(\s*(?:Color\b|\.(?:red|orange|yellow|green|mint|teal|cyan|blue|indigo|purple|pink|brown|black|white|gray|accentColor|tint)\b|\.\w+Material\b)", code):
            add(m.start(), "warn", "bar-background",
                "A custom bar background over Liquid Glass bars.",
                "Remove it; put brand color in the content layer (HIG: reduce toolbar backgrounds).")
        for m in re.finditer(r"\.presentationBackground\s*\(", code):
            add(m.start(), "warn", "presentation-background",
                "presentationBackground replaces the sheet's Liquid Glass background.",
                "Remove it and keep the system sheet background.")
        for m in re.finditer(r"\.background\s*\(\s*\.(?:ultraThin|thin|regular|thick|ultraThick)Material\b", code):
            add(m.start(), "info", "material-usage",
                "A standard material: right for content-layer surfaces, wrong for floating controls or navigation.",
                "If this is a control or bar, use `.buttonStyle(.glass)` or `.glassEffect()`.")
        for m in re.finditer(r"reduceTransparency\s*\?\s*\.identity\b|accessibilityReduceTransparency[^\n]*\?\s*\.identity\b", code):
            add(m.start(), "warn", "identity-for-reduce-transparency",
                "Swapping to .identity removes the backing under Reduce Transparency.",
                "Keep the glass; the system makes it frostier automatically.")
        for m in re.finditer(r'systemName\s*:\s*"apple\.logo"', raw):
            add(m.start(), "warn", "custom-apple-logo",
                "A custom button with the Apple logo.",
                "Use `SignInWithAppleButton` (AuthenticationServices); the HIG forbids custom Apple-logo buttons.")

        # Opacity applied to glass views
        for m, o, c, args in self._calls(code, r"\.glassEffect"):
            for name, off in modifier_chain_after(code, c + 1, limit=8):
                if name == "opacity":
                    add(off, "warn", "glass-opacity-fade",
                        "Opacity on a glass view fades the lensing into a muddy ghost.",
                        "Insert/remove the view inside a GlassEffectContainer with withAnimation (materialize).")
                    break

        # Clear glass is the exception
        for m in re.finditer(r"\.glassEffect\s*\(\s*\.clear\b|\.buttonStyle\s*\(\s*\.glass\s*\(\s*\.clear\b", code):
            add(m.start(), "info", "clear-glass",
                "Clear glass: only over media-rich content, with bold content on top and a ~35% dimming layer over bright media.",
                "Otherwise use .regular. Never mix .clear and .regular in one group.")

        # Destructive action styled as the prominent primary
        for m in re.finditer(r"\.buttonStyle\s*\(\s*\.glassProminent\s*\)", code):
            window_start = max(0, m.start() - 600)
            window = code[window_start:m.start()]
            last_button = max(window.rfind("Button("), window.rfind("Button {"), window.rfind("Button{"))
            if last_button != -1 and re.search(r"role\s*:\s*\.destructive\b", window[last_button:]):
                add(m.start(), "warn", "destructive-prominent",
                    "A destructive action styled as the prominent primary.",
                    "Use `role: .destructive` with `.buttonStyle(.glass)` and confirm the action (HIG Buttons).")

        # Deprecated in the 27 SDK (deprecatedAt 27.2)
        deprecations = [
            (r"\.toolbarBackground\s*\(\s*\.(?:hidden|visible|automatic)\b", "toolbarBackground(_:for:) with Visibility",
             "`.toolbarBackgroundVisibility(_:for:)`"),
            (r"\.toolbar\s*\(\s*\.(?:hidden|visible|automatic)\s*,\s*for\s*:", "toolbar(_:for:) with Visibility",
             "`.toolbarVisibility(_:for:)`"),
            (r"\.statusBarHidden\s*\(", "statusBarHidden(_:)", "`.toolbarVisibility(.hidden, for: .statusBar)` (iOS 27)"),
            (r"\bScrollView\s*\([^()]*showsIndicators\s*:", "ScrollView(_:showsIndicators:)",
             "`ScrollView(_:)` + `.scrollIndicators(.hidden)`"),
            (r"\.textFieldStyle\s*\(\s*\.(?:roundedBorder|squareBorder)\b", "TextFieldStyle.roundedBorder/.squareBorder",
             "`.textFieldStyle(.bordered).textInputBorderShape(.roundedRectangle)` (iOS 27)"),
            (r"\baccessibilityShowButtonShapes\b", "accessibilityShowButtonShapes (renamed)", "`accessibilityShowBorders`"),
            (r"\bPreviewProvider\b", "PreviewProvider", "`#Preview`"),
        ]
        for pattern, what, repl in deprecations:
            for m in re.finditer(pattern, code):
                add(m.start(), "info", "deprecated-27",
                    f"{what} is deprecated in the 27 SDK (deprecatedAt 27.2).", f"Use {repl}.")
        for m, o, c, args in self._calls(code, r"\.(?:overlay|background)"):
            parts = split_top_level(args)
            if not parts or any(re.match(r"in\s*:", p) for p in parts):
                continue
            first = parts[0]
            ident = re.match(r"([A-Z]\w*)\s*[(.]", first)
            if ident and ident.group(1) not in SHAPESTYLE_TYPES and not re.match(r"\w+\s*:", first):
                add(m.start(), "info", "deprecated-27",
                    "overlay(_:alignment:)/background(_:alignment:) with a view argument is deprecated in the 27 SDK (deprecatedAt 27.2).",
                    "Use the closure form: `.overlay(alignment: …) { … }` / `.background(alignment: …) { … }`.")

        # Availability against the deployment target
        if self.target is not None:
            for rule, pattern, introduced, label in VERSIONED_APIS:
                introduced = normalize(introduced)
                if self.target >= introduced:
                    continue
                for m in re.finditer(pattern, code):
                    if available_version_at(scopes, m.start()) >= introduced:
                        continue
                    ver = ".".join(str(p) for p in introduced[:2])
                    tgt = ".".join(str(p) for p in self.target[:2])
                    add(m.start(), "info", rule,
                        f"{label} needs iOS {ver}; the deployment target is {tgt}.",
                        f"Gate it with `if #available(iOS {ver}, *)` (see references/08-system-chrome.md § 9).")

    # -- config files ----------------------------------------------------
    def lint_config(self, path: str, raw: str) -> None:
        for m in re.finditer(r"UIDesignRequiresCompatibility", raw):
            self._add(path, raw, raw, m.start(), "warn", "design-requires-compatibility",
                      "UIDesignRequiresCompatibility is ignored when building with the 27 SDKs.",
                      "Remove it; Xcode 27 builds always use the Liquid Glass design.")


def iter_files(paths):
    for p in paths:
        if os.path.isdir(p):
            for root, dirs, files in os.walk(p):
                dirs[:] = [d for d in dirs if not d.startswith(".") and d not in ("build", "DerivedData", ".build", "Pods")]
                for f in sorted(files):
                    yield os.path.join(root, f)
        else:
            yield p


def parse_target(text: str | None):
    if not text:
        return None
    try:
        return normalize(tuple(int(x) for x in text.split(".")))
    except ValueError:
        raise SystemExit(f"--target must look like 26.0, got {text!r}")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*", default=["."], help="files or directories (default: .)")
    ap.add_argument("--target", help="iOS deployment target, e.g. 26.0; enables availability checks")
    ap.add_argument("--format", choices=("text", "json"), default="text")
    ap.add_argument("--min-severity", choices=("info", "warn", "error"), default="info")
    ap.add_argument("--strict", action="store_true", help="exit 1 on warnings too")
    args = ap.parse_args(argv)

    linter = Linter(parse_target(args.target))
    for path in iter_files(args.paths):
        name = os.path.basename(path)
        try:
            if name.endswith(SOURCE_SUFFIXES) and name != "Package.swift":
                with open(path, encoding="utf-8", errors="replace") as fh:
                    linter.lint_swift(path, fh.read())
            elif name.endswith(CONFIG_SUFFIXES) or name in CONFIG_NAMES:
                with open(path, encoding="utf-8", errors="replace") as fh:
                    linter.lint_config(path, fh.read())
        except OSError as exc:
            print(f"{path}: cannot read ({exc})", file=sys.stderr)

    floor = SEVERITY_RANK[args.min_severity]
    findings = sorted((f for f in linter.findings if SEVERITY_RANK[f.severity] >= floor),
                      key=lambda f: (f.path, f.line, f.column))
    if args.format == "json":
        print(json.dumps([asdict(f) for f in findings], indent=2))
    else:
        for f in findings:
            print(f"{f.path}:{f.line}:{f.column}: {f.severity}: [{f.rule}] {f.message}")
            if f.fix:
                print(f"    fix: {f.fix}")
        counts = {s: sum(1 for f in findings if f.severity == s) for s in ("error", "warn", "info")}
        print(f"\n{counts['error']} error(s), {counts['warn']} warning(s), {counts['info']} info")

    if any(f.severity == "error" for f in findings):
        return 1
    if args.strict and any(f.severity == "warn" for f in findings):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
