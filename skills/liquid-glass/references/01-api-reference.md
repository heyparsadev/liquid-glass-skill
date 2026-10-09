# API reference: custom Liquid Glass in SwiftUI

This file gives exact declarations as published in Apple's documentation (Xcode 27 SDK, October 2026). Every glass symbol here is available on **iOS, iPadOS, Mac Catalyst, macOS, tvOS, and watchOS 26.0+**, and **none of them exist on visionOS**. The core glass API did not change in iOS 27.

System chrome (toolbars, tab bars, search, sheets, scroll edge effects) is covered in [08-system-chrome.md](08-system-chrome.md).

## Contents

1. [`glassEffect(_:in:)`](#1-glasseffect_in)
2. [`Glass`](#2-glass)
3. [`GlassEffectContainer`](#3-glasseffectcontainer)
4. [`glassEffectID(_:in:)`](#4-glasseffectid_in)
5. [`glassEffectUnion(id:namespace:)`](#5-glasseffectunionidnamespace)
6. [`glassEffectTransition(_:)`](#6-glasseffecttransition_)
7. [Button styles](#7-button-styles)
8. [Shapes and concentric corners](#8-shapes-and-concentric-corners)
9. [Background extension and custom bars](#9-background-extension-and-custom-bars)
10. [Conditional glass (there is no `isEnabled`)](#10-conditional-glass-there-is-no-isenabled)
11. [Availability matrix](#11-availability-matrix)
12. [Names that do not exist](#12-names-that-do-not-exist)
13. [Requirements](#13-requirements)
14. [Cheat sheet](#14-cheat-sheet)

---

## 1. `glassEffect(_:in:)`

This modifier renders Liquid Glass in a shape anchored **behind** the view.

```swift
nonisolated func glassEffect(
    _ glass: Glass = .regular,
    in shape: some Shape = DefaultGlassEffectShape()
) -> some View
```

- There is only one method. `.glassEffect()` is the same call with both defaults.
- The defaults are the regular variant and a capsule (`DefaultGlassEffectShape()` is "the default shape applied by glass effects, a capsule").
- Apply it **after** padding and frames, so the shape fits the padded content.
- **There is no `isEnabled:` parameter.** See [§10](#10-conditional-glass-there-is-no-isenabled).

```swift
Text("Hello")
    .padding()
    .glassEffect()                                       // regular, capsule

Label("Filters", systemImage: "line.3.horizontal.decrease")
    .padding(.horizontal, 16).padding(.vertical, 10)
    .glassEffect(.regular, in: .rect(cornerRadius: 16))  // custom shape

Button { recenter() } label: {                          // custom tappable control
    Image(systemName: "location.fill").frame(width: 44, height: 44)
}
.buttonStyle(.plain)
.glassEffect(.regular.interactive(), in: .circle)
.accessibilityLabel("Show my location")
```

For an ordinary button, use `.buttonStyle(.glass)` ([§7](#7-button-styles)). A `.plain` button with `glassEffect`, as above, is for the cases the button styles can't express: a custom shape, a union, or a morphing group.

---

## 2. `Glass`

`Glass` is the configuration of the material. It is a value type conforming to `Equatable` and `Sendable`.

```swift
struct Glass {
    static var regular: Glass                        // the standard variant
    static var clear: Glass                          // more transparent, for media
    static var identity: Glass                       // no effect at all
    func tint(_ color: Color?) -> Glass              // nil removes the tint
    func interactive(_ isEnabled: Bool = true) -> Glass
}
```

| Variant | Use it for | Notes |
|---|---|---|
| `.regular` | Almost everything | "Regular is the most versatile and the one you will be using the most" (WWDC25 219). Use it whenever the background could hurt legibility or the element holds much text. |
| `.clear` | Controls floating over photos and video | Use it only when three things hold: the background is media-rich, the content can take a dimming layer, and the content on top is bold and bright. Add a dimming layer when the media is bright (HIG suggests about 35% black). Never mix it with `.regular` in one group. |
| `.identity` | Turning glass off without changing the view tree | "Your content remains unaffected as if no glass effect was applied." Content then has no backing at all. |

**`tint(_:)`.** Apple says to "assign a tint color to suggest prominence". Tint the one or two primary actions on screen, not every element. Tinting stays compatible with all the material's behaviors; the reason to limit it is hierarchy.

```swift
.glassEffect(.regular.tint(.accentColor))
```

**`interactive(_:)`.** Gives a *custom* view "the same responsive and fluid reactions that `glass` provides to standard buttons": scaling, bouncing, and shimmering on touch. In iOS 27 it also responds to pointer clicks on macOS. For a `Button`, use `.buttonStyle(.glass)` instead of `glassEffect(.regular.interactive())`.

```swift
.glassEffect(.regular.tint(.orange).interactive())
```

---

## 3. `GlassEffectContainer`

```swift
@MainActor @preconcurrency
struct GlassEffectContainer<Content> where Content : View {
    init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)
}
```

`@ContentBuilder` is Xcode 27's name for `ViewBuilder` (a `typealias`), so `@ViewBuilder` code keeps compiling.

**Why you need it.**
- *Visual correctness.* "Glass can not sample other glass, so having nearby glass elements in different containers will result in inconsistent behavior. Using a glass container allows these elements to share their sampling region" (WWDC25 323).
- *Performance.* "SwiftUI renders the effects together, improving rendering performance." Apple also warns: "Creating too many Liquid Glass effect containers and applying too many effects to views outside of containers can degrade performance."
- *Morphing.* Shapes inside one container can blend and morph into each other.

**`spacing` (blend distance).** "As shapes near one another, their paths start to blend into one another. The higher the spacing, the sooner blending begins." Spacing also affects shapes at rest: "A spacing value on the container that's larger than the spacing of an interior HStack, VStack, or other layout container causes Liquid Glass effects to blend together at rest."

- If shapes should stay separate at rest, set container spacing **≤** the stack spacing.
- If shapes should read as one blob, set container spacing **>** the stack spacing.

```swift
GlassEffectContainer(spacing: 12) {
    HStack(spacing: 12) {
        ForEach(["pencil", "eraser", "scissors"], id: \.self) { symbol in
            Button { } label: {
                Image(systemName: symbol).frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(symbol)
        }
    }
}
```

---

## 4. `glassEffectID(_:in:)`

```swift
nonisolated func glassEffectID(
    _ id: (some Hashable & Sendable)?,
    in namespace: Namespace.ID
) -> some View
```

This modifier identifies a glass shape across state changes, so the container can morph it in and out of its neighbors.

```swift
struct ActionMenu: View {
    @State private var expanded = false
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                if expanded {
                    menuButton("crop", "Crop").glassEffectID("crop", in: ns)
                    menuButton("rotate.right", "Rotate").glassEffectID("rotate", in: ns)
                }
                menuButton(expanded ? "xmark" : "slider.horizontal.3", expanded ? "Close" : "Edit") {
                    withAnimation { expanded.toggle() }
                }
                .glassEffectID("toggle", in: ns)
            }
        }
    }

    private func menuButton(_ symbol: String, _ label: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Image(systemName: symbol).frame(width: 48, height: 48)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}
```

For a morph you need all of these:
- Morphing views live in **one** `GlassEffectContainer`.
- Each has a unique ID in the same `@Namespace`.
- The state change happens inside `withAnimation`.

The ID and transition modifiers "only affect their content during view hierarchy transitions or animations".

---

## 5. `glassEffectUnion(id:namespace:)`

```swift
@MainActor @preconcurrency
func glassEffectUnion(
    id: (some Hashable & Sendable)?,
    namespace: Namespace.ID
) -> some View
```

This modifier merges separate glass views into one shape, even when they are too far apart to blend through `spacing`. Effects "with the same shape and Liquid Glass variant will be combined", so give the parts the same shape and variant.

```swift
@Namespace private var zoom

GlassEffectContainer {
    VStack(spacing: 0) {
        zoomButton("plus", "Zoom in")
        zoomButton("minus", "Zoom out")
    }
}

func zoomButton(_ symbol: String, _ label: String) -> some View {
    Button { } label: {
        Image(systemName: symbol).frame(width: 44, height: 44)
    }
    .buttonStyle(.plain)
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
    .glassEffectUnion(id: "zoom", namespace: zoom)     // same shape + variant → one body
    .accessibilityLabel(label)
}
```

---

## 6. `glassEffectTransition(_:)`

```swift
@MainActor @preconcurrency
func glassEffectTransition(_ transition: GlassEffectTransition) -> some View

struct GlassEffectTransition {
    static var identity: GlassEffectTransition
    static var matchedGeometry: GlassEffectTransition
    static var materialize: GlassEffectTransition
}
```

`GlassEffectTransition` is a struct with static members. It is not an enum, and there is no `isEnabled:` parameter.

- **`matchedGeometry`** is the default for glass added or removed *within* the container's spacing. The new shape grows out of the nearby shape.
- **`materialize`**: "Use the materialize transition for effects you want to add or remove that are farther from each other than the container's assigned spacing", or when you want a simpler transition. Glass "materializes in and out by gradually modulating the light bending and lensing" instead of fading.
- **`identity`** applies no glass transition.

```swift
if showBadge {
    Image(systemName: "sparkles")
        .frame(width: 44, height: 44)
        .glassEffect()
        .glassEffectTransition(.materialize)
}
```

---

## 7. Button styles

Prefer the system styles to hand-made glass buttons.

```swift
Button("Cancel") { }.buttonStyle(.glass)              // secondary (GlassButtonStyle)
Button("Save") { }.buttonStyle(.glassProminent)       // primary (GlassProminentButtonStyle)
Button("Play") { }.buttonStyle(.glass(.clear))        // configurable variant, iOS 26.1+
```

| Symbol | Declaration | Availability |
|---|---|---|
| `.glass` | `static var glass: GlassButtonStyle { get }` | 26.0 |
| `.glassProminent` | `static var glassProminent: GlassProminentButtonStyle { get }` | 26.0 |
| `.glass(_:)` | `static func glass(_ glass: Glass) -> Self` | Treat as **26.1** (`GlassButtonStyle.init(_:)` is 26.1) |

- **`.tint` with `.glassProminent`** fills the button's background with the color. This is how Apple emphasizes a primary action. Use one prominent button, or at most two, per view.
- **Mixing styles.** `.glass` and `.glassProminent` are different concrete types, so `.buttonStyle(isOn ? .glassProminent : .glass)` won't compile. Branch on the whole button instead (see `examples/07-ProfileScreen.swift`).
- **Destructive actions.** Use `role: .destructive` (system red). Don't make a destructive action the prominent primary (HIG Buttons).
- **`.buttonBorderShape(_:)`** accepts `.automatic` (the default), `.capsule`, `.circle`, `.roundedRectangle`, and `.roundedRectangle(radius:)`.
- **`.controlSize(_:)`** accepts `.mini`, `.small`, `.regular`, `.large`, and `.extraLarge`. `.extraLarge` dates from iOS 17. Apple's `ControlSize` reference says it resolves to `.large` outside visionOS, while the iOS 26 design material mentions an extra-large control option. Don't build layouts that depend on it rendering larger than `.large` on iOS.
- **iOS 27 SDK.** `controlSize`, `buttonSizing`, `buttonRepeatBehavior`, `menuIndicatorVisibility`, and `ButtonBorderShape` now reset to their defaults inside sheets and popovers. Apply them inside the presented content.

---

## 8. Shapes and concentric corners

Any `Shape` can be the `in:` argument:

```swift
.glassEffect(.regular, in: .capsule)        // default
.glassEffect(.regular, in: .circle)
.glassEffect(.regular, in: .ellipse)
.glassEffect(.regular, in: .rect(cornerRadius: 20))
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
```

Apple describes three kinds of corner (WWDC25 356). **Fixed** corners have a constant radius. **Capsules** use half the container height. **Concentric** corners subtract the padding from the parent's radius.

**Concentric corners** come from `ConcentricRectangle` and `Edge.Corner.Style`. These are 26.0 on every platform, including visionOS.

```swift
struct ConcentricRectangle: Shape {
    init()
    init(corners: Edge.Corner.Style, isUniform: Bool = false)
    // …plus per-corner initializers
}
static func rect(corners: Edge.Corner.Style, isUniform: Bool = false) -> Self   // on Shape

// Edge.Corner.Style
static var concentric: Edge.Corner.Style
static func concentric(minimum: Edge.Corner.Style?) -> Edge.Corner.Style
static func fixed(_ radius: CGFloat) -> Edge.Corner.Style
```

A concentric shape resolves against its **container shape**. That is either a system container (sheet, window, or device corners) or a shape you declare with `containerShape(_:)`. A plain `.background(RoundedRectangle(...))` does **not** declare one. If no radius can be resolved, it may come out as zero, so give it a minimum.

```swift
VStack(spacing: 12) {
    Text("Storage almost full").font(.headline)
    Button("Manage") { }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .glassEffect(.regular.interactive(),
                     in: .rect(corners: .concentric(minimum: 12), isUniform: true))
}
.padding(12)
.background(.background, in: .rect(cornerRadius: 28))
.containerShape(.rect(cornerRadius: 28))      // ← what makes the inner corners concentric
```

`containerShape(_:)` has two forms: `func containerShape(_ shape: some RoundedRectangularShape) -> some View` (26.0) and the older `InsettableShape` overload.

**iOS 27:** `GeometryProxy.concentricCornerRadii` and `concentricCornerRadii(in:)` return the resolved radii as a `RectangleCornerRadii?`, for custom drawing that must stay concentric.

---

## 9. Background extension and custom bars

**`backgroundExtensionEffect()`** extends an image or banner under a sidebar or inspector by mirroring and blurring it. Apply it to that single background view, not to a whole screen; it clips the view.

```swift
@MainActor @preconcurrency func backgroundExtensionEffect() -> some View
@MainActor @preconcurrency func backgroundExtensionEffect(isEnabled: Bool) -> some View
```

```swift
NavigationSplitView {
    Sidebar()
} detail: {
    ScrollView {
        Image("hero")
            .resizable().scaledToFill()
            .frame(height: 300)
            .backgroundExtensionEffect()      // extends under the sidebar's glass
        DetailBody()
    }
}
```

**`safeAreaBar(edge:alignment:spacing:content:)`** shows custom content as a bar beside the view. Unlike `safeAreaInset`, it takes part in **scroll edge effects**, so scrolling content stays legible under your custom floating glass.

```swift
nonisolated func safeAreaBar(edge: VerticalEdge, alignment: HorizontalAlignment = .center,
                             spacing: CGFloat? = nil,
                             @ContentBuilder content: () -> some View) -> some View
nonisolated func safeAreaBar(edge: HorizontalEdge, alignment: VerticalAlignment = .center,
                             spacing: CGFloat? = nil,
                             @ContentBuilder content: () -> some View) -> some View
```

The iOS 26.1 release notes list a known issue: `@FocusState` doesn't work inside `safeAreaBar`. For a text-input bar such as a chat composer, use `safeAreaInset` until that is fixed.

Scroll edge effect styles are covered in [08-system-chrome.md § Scroll edge effects](08-system-chrome.md#6-scroll-edge-effects).

---

## 10. Conditional glass (there is no `isEnabled`)

`glassEffect` and `glassEffectTransition` have no `isEnabled:` parameter. Use one of these instead:

```swift
// A. Swap the variant. Simple, but Apple doesn't document whether the switch animates.
.glassEffect(isOn ? .regular : .identity, in: .capsule)

// B. Insert or remove the view inside a container. This is the documented, animated way.
GlassEffectContainer {
    if isOn {
        control
            .glassEffect()
            .glassEffectTransition(.materialize)
    }
}
// toggle with: withAnimation { isOn.toggle() }
```

Don't fade glass with `.opacity`. Glass "materializes" instead of fading. If you remove glass from a control that sits over busy content, give it another backing, such as `.background(.background, in: .capsule)`.

---

## 11. Availability matrix

Versions are the first OS version that has the symbol. "—" means the symbol is not available.

| Symbol | iOS · iPadOS | Mac Catalyst | macOS | tvOS | watchOS | visionOS |
|---|---|---|---|---|---|---|
| `Glass`, `glassEffect(_:in:)`, `GlassEffectContainer`, `glassEffectID`, `glassEffectUnion`, `glassEffectTransition`, `.glass`, `.glassProminent` | 26.0 | 26.0 | 26.0 | 26.0 | 26.0 | — |
| `.glass(_:)` / `GlassButtonStyle.init(_:)` | 26.1 | 26.1 | 26.1 | 26.1 | 26.1 | — |
| `ConcentricRectangle`, `rect(corners:isUniform:)`, `containerShape(_:)` (RoundedRectangularShape) | 26.0 | 26.0 | 26.0 | 26.0 | 26.0 | 26.0 |
| `backgroundExtensionEffect()`, `safeAreaBar(…)` | 26.0 | 26.0 | 26.0 | 26.0 | 26.0 | 26.0 |
| `scrollEdgeEffectStyle(_:for:)`, `scrollEdgeEffectHidden(_:for:)` | 26.0 | 26.0 | 26.0 | 26.0 | 26.0 | — |
| `ToolbarSpacer`, `sharedBackgroundVisibility(_:)` | 26.0 | 26.0 | 26.0 | — | — | — |
| `DefaultToolbarItem`, `searchToolbarBehavior(_:)`, `tabBarMinimizeBehavior(_:)` | 26.0 | 26.0 | 26.0 | 26.0 | 26.0 | 26.0 |
| `tabViewBottomAccessory(content:)` | 26.0 | 26.0 | — | — | — | — |
| `tabViewBottomAccessory(isEnabled:content:)` | 26.1 | 26.1 | — | — | — | — |
| `ToolbarContent.matchedTransitionSource(id:in:)` | 26.0 | 26.0 | — | — | — | — |
| `ToolbarContent.hidden(_:)` | 26.4 | 26.4 | 15.0 | 27.2 β | 27.2 β | 26.4 |
| `accessibilityReduceHighlightingEffects` | 26.4 | 26.4 | 26.4 | 26.4 | 26.4 | 26.4 |
| `toolbarMinimizationBehavior(_:for:)` (+ `…Restoration`, `…SafeAreaAdjustment`) | 27.0 | 27.0 | 27.0 | 27.0 | 27.0 | 27.0 |
| `visibilityPriority(_:)` | 27.0 | 27.0 | 26.1 | 27.0 | 27.0 | 27.0 |
| `ToolbarOverflowMenu`, `toolbarOverflowMenu(content:)`, `.topBarPinnedTrailing` | 27.0 | 27.0 | — | — | — | 27.0 |
| `ToolbarContent.contentMarginsRemoved(_:)` | 27.0 | 27.0 | 27.0 | 27.0 | 27.0 | 27.0 |
| `TabRole.prominent`, `presentationPlacement(_:)`, `textInputBorderShape(_:)`, `GeometryProxy.concentricCornerRadii` | 27.0 | 27.0 | 27.0 | 27.0 | 27.0 | 27.0 |
| `NavigationTransition.crossFade` | 27.0 | 27.0 | — | 27.0 | 27.0 | 27.0 |
| `PickerStyle.tabs` | 27.0 | 27.0 | 27.0 | 27.0 | — | 27.0 |
| `ToolbarPlacement.statusBar` | 27.0 | 27.0 | — | — | — | — |
| `toolbarVerticalBehavior(_:)`, `toolbarVerticalEdge`, `axisBehavior(_:)`, `ReservedRegion` | 27.1 β | 27.1 | 27.1 | 27.1 | 27.1 | 27.1 |

β = marked beta in Apple's documentation as of October 2026.

---

## 12. Names that do not exist

These spellings appear in blog posts, WWDC videos, or older drafts of this skill. None of them compile against the shipping SDK.

| Wrong | Use instead |
|---|---|
| `glassEffect(_:in:isEnabled:)` | Swap to `.identity`, or insert/remove the view ([§10](#10-conditional-glass-there-is-no-isenabled)) |
| `glassEffectTransition(_:isEnabled:)` | `glassEffectTransition(_:)` |
| `.rect(cornerRadius: .containerConcentric)` | `.rect(corners: .concentric)` or `ConcentricRectangle()` plus `containerShape(_:)`. UIKit's `UICornerRadius.containerConcentric(minimum:)` is UIKit-only. |
| `scrollExtensionMode(_:)` | `backgroundExtensionEffect()` |
| `toolbarMinimizeBehavior(_:for:)` (WWDC26 video) | `toolbarMinimizationBehavior(_:for:)` |
| `TabViewBottomAccessoryPlacement.collapsed` | `.inline` (the environment value is Optional) |
| `SearchToolbarBehavior.minimized` (typo in an Apple sample) | `.minimize` |
| `ToolbarSpacer(spacing:)` | `ToolbarSpacer(.fixed, placement: …)` |
| `Glass.opacity(_:)` | Nothing. Don't fade glass. |
| `Button { … }.sharedBackgroundVisibility(.hidden)` | `ToolbarItem { … }.sharedBackgroundVisibility(.hidden)` |
| `ToolbarItem { DefaultToolbarItem(…) }` | Put `DefaultToolbarItem(kind:placement:)` directly in `.toolbar { }` |
| `.glassProminent.tint(.blue)` | `.buttonStyle(.glassProminent).tint(.blue)` |
| `.glassEffect(…)` on visionOS | `glassBackgroundEffect(…)` (visionOS only) |

---

## 13. Requirements

| Item | Value |
|---|---|
| Glass APIs | iOS, iPadOS, Mac Catalyst, macOS, tvOS, watchOS 26.0+. Not visionOS. |
| tvOS hardware | Apple TV 4K (2nd generation) and newer render Liquid Glass; older models keep their current appearance. |
| Xcode 26 | Swift 6.2 (26.0–26.3), Swift 6.3 (26.4 and later) |
| Xcode 27 | Swift 6.4, iOS 27 SDK, needs macOS Tahoe 26.6+. Deployment targets iOS 15–27. |
| iPhone | iOS 26 and iOS 27 both run on iPhone 11 and later. iOS 27 dropped no devices. |
| App Store | iOS 26 SDK required since April 28, 2026. iOS 27 SDK required from April 2027. |

---

## 14. Cheat sheet

```swift
// One element
.glassEffect()
.glassEffect(.regular.tint(.accentColor))                 // prominence
.glassEffect(.regular.interactive(), in: .circle)         // custom tappable view
.glassEffect(.clear, in: .rect(cornerRadius: 20))         // over media, plus a dimming layer

// Group and morph
@Namespace private var ns
GlassEffectContainer(spacing: 12) { … }
.glassEffectID("id", in: ns)
withAnimation { state.toggle() }
.glassEffectUnion(id: "group", namespace: ns)
.glassEffectTransition(.materialize)

// Buttons
.buttonStyle(.glass)
.buttonStyle(.glassProminent).tint(.accentColor)

// Concentric
.glassEffect(.regular, in: .rect(corners: .concentric(minimum: 12), isUniform: true))
.containerShape(.rect(cornerRadius: 28))                  // on the parent

// Conditional
.glassEffect(isOn ? .regular : .identity)
```

---

## Sources

- [`glassEffect(_:in:)`](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)) · [`Glass`](https://developer.apple.com/documentation/swiftui/glass) · [`GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) · [`GlassEffectTransition`](https://developer.apple.com/documentation/swiftui/glasseffecttransition) · [`ConcentricRectangle`](https://developer.apple.com/documentation/swiftui/concentricrectangle) · [`safeAreaBar`](https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:))
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views) · [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- WWDC25 219 *Meet Liquid Glass*, 323 *Build a SwiftUI app with the new design*, 356 *Get to know the new design system*. WWDC26 269 *What's new in SwiftUI*.
