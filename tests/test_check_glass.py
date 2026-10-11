"""Tests for skills/liquid-glass/scripts/check_glass.py.

Run from the repository root:  python3 -m unittest discover -s tests
"""

import contextlib
import importlib.util
import io
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "..", "skills", "liquid-glass", "scripts", "check_glass.py")
spec = importlib.util.spec_from_file_location("check_glass", SCRIPT)
check_glass = importlib.util.module_from_spec(spec)
sys.modules["check_glass"] = check_glass
spec.loader.exec_module(check_glass)


def lint(src, target=None):
    linter = check_glass.Linter(check_glass.parse_target(target))
    linter.lint_swift("Test.swift", src)
    return linter.findings


def rules(src, target=None):
    return [f.rule for f in lint(src, target)]


class StripTests(unittest.TestCase):
    def test_comments_and_strings_are_blanked_but_offsets_kept(self):
        src = 'let a = "x.glassEffect(isEnabled: true)" // .containerConcentric\n/* .scrollExtensionMode() */ b'
        out = check_glass.strip_comments_and_strings(src)
        self.assertEqual(len(out), len(src))
        self.assertNotIn("glassEffect", out)
        self.assertNotIn("containerConcentric", out)
        self.assertNotIn("scrollExtensionMode", out)
        self.assertTrue(out.endswith(" b"))

    def test_interpolation_stays_code(self):
        out = check_glass.strip_comments_and_strings('Text("\\(x ? "a" : "b") done").glassEffect()')
        self.assertIn(".glassEffect()", out)
        self.assertNotIn("done", out)


class ErrorRuleTests(unittest.TestCase):
    def test_isenabled(self):
        self.assertIn("glass-isenabled", rules("v.glassEffect(.regular, isEnabled: on)"))
        self.assertNotIn("glass-isenabled", rules("v.glassEffect(on ? .regular : .identity)"))

    def test_transition_isenabled(self):
        self.assertIn("transition-isenabled", rules("v.glassEffectTransition(.materialize, isEnabled: x)"))
        self.assertNotIn("transition-isenabled", rules("v.glassEffectTransition(.materialize)"))

    def test_glass_opacity(self):
        self.assertIn("glass-opacity", rules("v.glassEffect(.regular.tint(.purple).opacity(0.9))"))
        self.assertNotIn("glass-opacity", rules("v.glassEffect(.regular.tint(.red.opacity(0.7)))"))

    def test_container_concentric(self):
        self.assertIn("container-concentric", rules("v.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))"))
        # UIKit's UICornerRadius.containerConcentric(minimum:) is real
        self.assertNotIn("container-concentric", rules("view.cornerConfiguration = .corners(radius: .containerConcentric(minimum: 8))"))

    def test_misc_names(self):
        self.assertIn("scroll-extension-mode", rules("v.scrollExtensionMode(.underSidebar)"))
        self.assertIn("toolbar-minimize-behavior", rules("v.toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)"))
        self.assertIn("search-minimized", rules("v.searchToolbarBehavior(.minimized)"))
        self.assertNotIn("search-minimized", rules("v.searchToolbarBehavior(.minimize)"))
        self.assertIn("toolbar-spacer-spacing", rules("ToolbarSpacer(.fixed, spacing: 8)"))
        self.assertNotIn("toolbar-spacer-spacing", rules("ToolbarSpacer(.fixed, placement: .topBarTrailing)"))
        self.assertIn("button-style-tint-chain", rules("b.buttonStyle(.glassProminent.tint(.blue))"))
        self.assertIn("button-style-ternary", rules("b.buttonStyle(on ? .glassProminent : .glass)"))

    def test_accessory_collapsed(self):
        src = "@Environment(\\.tabViewBottomAccessoryPlacement) var p\nif p == .collapsed { }"
        self.assertIn("accessory-collapsed", rules(src))
        self.assertNotIn("accessory-collapsed", rules("if state == .collapsed { }"))

    def test_default_toolbar_item_nested(self):
        bad = ".toolbar { ToolbarItem(placement: .bottomBar) { DefaultToolbarItem(kind: .search, placement: .bottomBar) } }"
        good = ".toolbar { DefaultToolbarItem(kind: .search, placement: .bottomBar) }"
        self.assertIn("default-toolbar-item-nested", rules(bad))
        self.assertNotIn("default-toolbar-item-nested", rules(good))

    def test_toolbar_content_modifier_on_view(self):
        bad = 'ToolbarItem { Button("Me") { }.sharedBackgroundVisibility(.hidden) }'
        good = 'ToolbarItem { Button("Me") { } }.sharedBackgroundVisibility(.hidden)'
        self.assertIn("toolbar-content-modifier-on-view", rules(bad))
        self.assertNotIn("toolbar-content-modifier-on-view", rules(good))


class DesignRuleTests(unittest.TestCase):
    def test_glass_on_toolbar_item(self):
        self.assertIn("glass-on-system-chrome", rules('ToolbarItem { Button("Done") { }.glassEffect() }'))

    def test_glass_in_accessory_and_list(self):
        self.assertIn("glass-in-accessory", rules('.tabViewBottomAccessory { Button("Play") { }.buttonStyle(.glass) }'))
        self.assertIn("glass-in-list", rules("List(items) { item in Text(item.title).glassEffect() }"))

    def test_nested_container(self):
        self.assertIn("nested-container", rules("GlassEffectContainer { GlassEffectContainer { a } }"))
        self.assertNotIn("nested-container", rules("GlassEffectContainer { a }\nGlassEffectContainer { b }"))

    def test_backgrounds(self):
        self.assertIn("bar-background", rules("v.toolbarBackground(.purple, for: .navigationBar)"))
        self.assertIn("presentation-background", rules("v.presentationBackground(.clear)"))
        self.assertIn("identity-for-reduce-transparency", rules("v.glassEffect(reduceTransparency ? .identity : .regular)"))

    def test_opacity_fade(self):
        self.assertIn("glass-opacity-fade", rules("v.glassEffect()\n    .opacity(visible ? 1 : 0)"))
        self.assertNotIn("glass-opacity-fade", rules("v.glassEffect()\n    .padding()"))

    def test_destructive_prominent(self):
        bad = 'Button(role: .destructive) { delete() } label: { Text("Delete") }\n    .buttonStyle(.glassProminent)'
        good = 'Button(role: .destructive) { delete() } label: { Text("Delete") }\n    .buttonStyle(.glass)'
        self.assertIn("destructive-prominent", rules(bad))
        self.assertNotIn("destructive-prominent", rules(good))

    def test_apple_logo(self):
        self.assertIn("custom-apple-logo", rules('Image(systemName: "apple.logo")'))

    def test_ignore_comment(self):
        self.assertNotIn("presentation-background", rules("v.presentationBackground(.clear) // check-glass: ignore"))
        self.assertNotIn("presentation-background", rules("v.presentationBackground(.clear) // check-glass: ignore=presentation-background"))
        self.assertIn("presentation-background", rules("v.presentationBackground(.clear) // check-glass: ignore=other-rule"))


class DeprecationTests(unittest.TestCase):
    def test_deprecated_27(self):
        for src in [
            "v.toolbarBackground(.hidden, for: .navigationBar)",
            "v.toolbar(.hidden, for: .tabBar)",
            "ScrollView(.horizontal, showsIndicators: false) { }",
            "v.overlay(Circle().stroke(), alignment: .center)",
            "v.background(RoundedRectangle(cornerRadius: 8).fill(.red))",
            "t.textFieldStyle(.roundedBorder)",
        ]:
            self.assertIn("deprecated-27", rules(src), src)

    def test_not_deprecated(self):
        for src in [
            "v.background(.background)",
            "v.background(Color.red)",
            "v.background(.ultraThinMaterial, in: Capsule())",
            "v.overlay(alignment: .topTrailing) { Badge() }",
            "v.toolbarBackgroundVisibility(.hidden, for: .navigationBar)",
            "ScrollView(.horizontal) { }.scrollIndicators(.hidden)",
        ]:
            self.assertNotIn("deprecated-27", rules(src), src)


class AvailabilityTests(unittest.TestCase):
    def test_ungated_27_api_on_26_target(self):
        self.assertIn("ios27-api", rules("v.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)", "26.0"))

    def test_an_ungated_api_is_a_warning_because_it_does_not_compile(self):
        findings = lint("v.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)", "26.0")
        self.assertEqual([(f.rule, f.severity) for f in findings], [("ios27-api", "warn")])

    def test_no_check_without_target_or_on_27_target(self):
        src = "v.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)"
        self.assertNotIn("ios27-api", rules(src))
        self.assertNotIn("ios27-api", rules(src, "27.0"))

    def test_if_available_scope(self):
        src = """
        if #available(iOS 27.0, *) {
            v.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
        } else {
            v
        }
        """
        self.assertNotIn("ios27-api", rules(src, "26.0"))

    def test_else_branch_is_not_available(self):
        src = """
        if #available(iOS 27.0, *) {
            a
        } else {
            v.toolbarMinimizationBehavior(.never, for: .navigationBar)
        }
        """
        self.assertIn("ios27-api", rules(src, "26.0"))

    def test_attribute_scope(self):
        src = "@available(iOS 27.0, *)\nstruct Inbox: View {\n  var body: some View { List { }.toolbarOverflowMenu { } }\n}"
        self.assertNotIn("ios27-api", rules(src, "26.0"))

    def test_guard_scope(self):
        src = """
        func f() {
            guard #available(iOS 27.0, *) else { return }
            v.presentationPlacement(.leading)
        }
        """
        self.assertNotIn("ios27-api", rules(src, "26.0"))

    def test_glass_needs_gate_below_26(self):
        self.assertIn("ios26-api", rules("v.glassEffect()", "18.0"))
        self.assertNotIn("ios26-api", rules("v.glassEffect()", "26"))
        self.assertNotIn("ios26-api", rules("if #available(iOS 26.0, *) { v.glassEffect() }", "18.0"))

    def test_status_bar_anywhere_in_a_list_of_bars(self):
        for src in ["v.toolbarColorScheme(.light, for: .navigationBar, .statusBar)",
                    "v.toolbarVisibility(.hidden, for: .navigationBar, .statusBar)",
                    "v.toolbarColorScheme(.dark, for: .statusBar)"]:
            self.assertIn("ios27-api", rules(src, "26.0"), src)
        self.assertNotIn("ios27-api", rules("v.toolbarColorScheme(.light, for: .navigationBar)", "26.0"))

    def test_targets_below_26_point_to_the_migration_guide(self):
        [finding] = lint("v.glassEffect()", "18.0")
        self.assertIn("10-migrating-to-ios27.md", finding.fix)

    def test_point_release(self):
        self.assertIn("ios26x-api", rules("t.tabViewBottomAccessory(isEnabled: on) { Bar() }", "26.0"))
        self.assertNotIn("ios26x-api", rules("t.tabViewBottomAccessory(isEnabled: on) { Bar() }", "26.1"))


class CommandLineTests(unittest.TestCase):
    SOURCE = "a.background(.ultraThinMaterial)\nb.glassEffect(.clear)\nc.presentationBackground(.clear)\n"

    def run_main(self, *args):
        with tempfile.TemporaryDirectory() as folder:
            path = os.path.join(folder, "Screen.swift")
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(self.SOURCE)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                code = check_glass.main([path, *args])
            return code, out.getvalue()

    def test_clear_glass_and_material_usage_are_hidden_by_default(self):
        code, out = self.run_main()
        self.assertEqual(code, 0)
        self.assertIn("presentation-background", out)
        self.assertNotIn("material-usage", out)
        self.assertNotIn("clear-glass", out)
        self.assertIn("0 error(s), 1 warning(s), 0 info", out)

    def test_verbose_shows_them(self):
        code, out = self.run_main("--verbose")
        self.assertIn("material-usage", out)
        self.assertIn("clear-glass", out)
        self.assertIn("0 error(s), 1 warning(s), 2 info", out)

    def test_the_summary_says_how_many_notes_are_hidden(self):
        _, out = self.run_main()
        self.assertIn("2 notes hidden", out)
        _, out = self.run_main("--verbose")
        self.assertNotIn("hidden", out)

    def test_strict_fails_on_an_ungated_api(self):
        self.SOURCE = "v.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)\n"
        self.assertEqual(self.run_main("--target", "26.0")[0], 0)
        self.assertEqual(self.run_main("--target", "26.0", "--strict")[0], 1)

    def test_json_output_follows_the_same_filter(self):
        _, out = self.run_main("--format", "json")
        self.assertEqual([f["rule"] for f in json.loads(out)], ["presentation-background"])


class ConfigTests(unittest.TestCase):
    def test_design_requires_compatibility(self):
        linter = check_glass.Linter(None)
        linter.lint_config("Info.plist", "<key>UIDesignRequiresCompatibility</key><true/>")
        self.assertEqual([f.rule for f in linter.findings], ["design-requires-compatibility"])


if __name__ == "__main__":
    unittest.main()
