# API Reference — Liquid Glass in SwiftUI (iOS 26+)

Every public symbol you need, with exact signatures, parameters, and minimal examples. Sourced from Xcode 26 SDK headers, Apple Developer documentation, and WWDC25 sessions 219, 284, 323.

---

## 1. `.glassEffect(_:in:isEnabled:)`

Apply Liquid Glass to any view.

### Signatures
```swift
extension View {
    func glassEffect() -> some View

    func glassEffect<S: Shape>(
        _ glass: Glass = .regular,
        in shape: S = DefaultGlassEffectShape,
        isEnabled: Bool = true
    ) -> some View
}
```

### Parameters
| Param | Type | Default | Notes |
|---|---|---|---|
| `glass` | `Glass` | `.regular` | Variant: `.regular`, `.clear`, `.identity` (see § 4) |
| `shape` | any `Shape` | `Capsule()` | Use `.capsule`, `.circle`, `.rect(cornerRadius:)`, or any custom `Shape` |
| `isEnabled` | `Bool` | `true` | Conditionally disable without changing the view tree |

### Examples
```swift
// Default: regular glass, capsule shape
Text("Hello")
    .padding()
    .glassEffect()

// Custom shape
Text("Card")
    .padding(20)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))

// Clear variant over media
Text("Overlay")
    .padding()
    .glassEffect(.clear, in: .capsule)

// Conditional
Image(systemName: "star")
    .padding()
    .glassEffect(.regular, in: .circle, isEnabled: highlighted)
```

### Rules
- Apply **after** sizing and padding modifiers, not before.
- Default shape is `.capsule` — change it explicitly for non-pill controls.
- Glass cannot sample other glass; nest only when you understand the cost (§ 3).

---

## 2. The `Glass` type

A value type configuring the glass appearance. Built via static factories, then chained with modifiers.

### Declaration
```swift
struct Glass {
    static var regular: Glass     // standard, adaptive
    static var clear: Glass       // higher transparency, for media-rich backgrounds
    static var identity: Glass    // no effect (accessibility / conditional opt-out)

    func tint(_ color: Color) -> Glass
    func interactive(_ isInteractive: Bool = true) -> Glass
}
```

### Variants
| Variant | Use when… | Transparency | Adaptivity |
|---|---|---|---|
| `.regular` | 95% of UI chrome | medium | full lensing + tinting |
| `.clear` | Over photos, video, vivid imagery | high | limited |
| `.identity` | Reduce Transparency / disabled state | none | n/a |

### Modifiers

#### `.tint(_:)`
Adds a color cast for **semantic prominence** (primary action, destructive, success). Subtle by design — heavy tints destroy refraction.
```swift
.glassEffect(.regular.tint(.blue))
.glassEffect(.regular.tint(.red.opacity(0.7)))
```

#### `.interactive(_:)`
Enables touch-responsive behavior: scaling on press, gentle bounce, specular shimmer following the touch point, drag awareness.
```swift
.glassEffect(.regular.interactive())
.glassEffect(.clear.interactive(true).tint(.green))
```

### Chaining
Order doesn't matter; each modifier returns a new `Glass` value:
```swift
.glassEffect(.regular.tint(.orange).interactive())
.glassEffect(.clear.interactive().tint(.blue))
```

---

## 3. `GlassEffectContainer`

Combines multiple glass shapes into a single morphing surface. **Required** whenever two or more glass elements live near each other — both for visual correctness (blending) and for rendering performance.

### Signature
```swift
struct GlassEffectContainer<Content: View>: View {
    init(@ViewBuilder content: () -> Content)
    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content)
}
```

### `spacing` parameter
The **morph threshold**. Glass elements within `spacing` points of each other visually blend into a single fluid blob during transitions. Larger values = elements merge from further away.

### Example — toolbar of glass icons
```swift
GlassEffectContainer(spacing: 12) {
    HStack(spacing: 12) {
        Image(systemName: "pencil")
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive())

        Image(systemName: "eraser")
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive())

        Image(systemName: "scissors")
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive())
    }
}
```

### What it does automatically
- Blends overlapping glass shapes into one
- Unifies blur, lensing, and lighting across children
- Enables morphing when children appear/disappear
- Batches the glass render pass (significant GPU savings vs. N independent passes)

---

## 4. `.glassEffectID(_:in:)`

Identifies a glass element across state changes so SwiftUI can morph between configurations.

### Signature
```swift
extension View {
    func glassEffectID<ID: Hashable>(_ id: ID, in namespace: Namespace.ID) -> some View
}
```

### Example — expanding action menu
```swift
struct ActionMenu: View {
    @State private var expanded = false
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 30) {
            VStack(spacing: 30) {
                if expanded {
                    iconButton("crop").glassEffectID("crop", in: ns)
                    iconButton("rotate.right").glassEffectID("rotate", in: ns)
                }
                iconButton(expanded ? "xmark" : "slider.horizontal.3") {
                    withAnimation(.bouncy) { expanded.toggle() }
                }
                .glassEffectID("toggle", in: ns)
            }
        }
    }
}
```

### Rules
- Always pair with `withAnimation { ... }`.
- Must be inside a `GlassEffectContainer` to morph.
- Each ID must be unique within its namespace.

---

## 5. `.glassEffectUnion(id:namespace:)`

Forces two **non-adjacent** glass views to render as a single unified glass shape. Use when distance > `spacing` but you still want one fluid surface.

### Signature
```swift
extension View {
    func glassEffectUnion<ID: Hashable>(id: ID, namespace: Namespace.ID) -> some View
}
```

### Example
```swift
@Namespace var tools

HStack {
    Button("Edit") {}
        .buttonStyle(.glass)
        .glassEffectUnion(id: "tools", namespace: tools)

    Spacer(minLength: 200)   // far apart

    Button("Delete") {}
        .buttonStyle(.glass)
        .glassEffectUnion(id: "tools", namespace: tools)
}
```

Both buttons render as one continuous glass body even with the spacer between them.

---

## 6. `.glassEffectTransition(_:isEnabled:)`

Controls how a glass view enters/exits.

### Signature
```swift
extension View {
    func glassEffectTransition(_ transition: GlassEffectTransition, isEnabled: Bool = true) -> some View
}

enum GlassEffectTransition {
    case identity         // no transition
    case matchedGeometry  // morph between IDs (default with glassEffectID)
    case materialize      // gradual light modulation; glass "materializes" from the background
}
```

### Example
```swift
Image(systemName: "sparkles")
    .frame(width: 60, height: 60)
    .glassEffect()
    .glassEffectID("spark", in: ns)
    .glassEffectTransition(.materialize)
```

---

## 7. Button styles

iOS 26 adds two glass-native button styles. Use them — don't roll your own with `.glassEffect()` on a `Button` unless you have a real reason.

### Styles
```swift
Button("Cancel") { }.buttonStyle(.glass)            // secondary / neutral
Button("Save")   { }.buttonStyle(.glassProminent)   // primary / opaque tint surface
```

### Control sizes
```swift
.controlSize(.mini)
.controlSize(.small)
.controlSize(.regular)     // default
.controlSize(.large)
.controlSize(.extraLarge)  // new in iOS 26 — for floating CTAs
```

### Border shapes
```swift
.buttonBorderShape(.capsule)                          // default
.buttonBorderShape(.roundedRectangle(radius: 12))
.buttonBorderShape(.circle)
```

### Composing
```swift
Button("Continue") { }
    .buttonStyle(.glassProminent)
    .tint(.blue)
    .controlSize(.extraLarge)
    .buttonBorderShape(.capsule)
```

### Gotcha — circle artifacts
With `.buttonBorderShape(.circle)`, rendering artifacts can appear at extreme sizes. Workaround:
```swift
Button(action: {}) { Image(systemName: "plus") }
    .buttonStyle(.glassProminent)
    .buttonBorderShape(.circle)
    .clipShape(Circle())  // clamps the render bounds
```

---

## 8. Toolbar integration

In iOS 26, `Toolbar` items automatically receive glass styling — **don't add `.glassEffect()` to them**. New APIs let you arrange, space, and badge them.

### Basic
```swift
NavigationStack {
    ContentView()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") { }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") { }
            }
        }
}
```

### `ToolbarSpacer`
Insert visible breathing room between glass toolbar items.
```swift
.toolbar {
    ToolbarItemGroup(placement: .topBarTrailing) {
        Button("Draw", systemImage: "pencil") { }
        Button("Erase", systemImage: "eraser") { }
    }
    ToolbarSpacer(.fixed, placement: .topBarTrailing)
    ToolbarItem(placement: .topBarTrailing) {
        Button("Save", systemImage: "checkmark") { }
            .buttonStyle(.glassProminent)
    }
}
```

Signature: `ToolbarSpacer(_ sizing: SpacerSizing = .flexible, placement: ToolbarItemPlacement = .automatic)`. There is no `spacing:` argument — the fixed size is fixed by the system.

### Badges
```swift
ToolbarItem(placement: .topBarLeading) {
    Button("Inbox", systemImage: "tray") { }
        .badge(5)
        .tint(.red)
}
```

### `.sharedBackgroundVisibility(_:)`
Detach an item from the shared toolbar glass slab.
```swift
ToolbarItem {
    Button("Profile", systemImage: "person.crop.circle") { }
        .sharedBackgroundVisibility(.hidden)
}
```

---

## 9. `TabView` integration

`TabView` in iOS 26 is glass by default. You don't apply `.glassEffect()` to it — you configure its behavior.

### `Tab` declarative API
```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Library", systemImage: "books.vertical") { LibraryView() }
    Tab("Search", systemImage: "magnifyingglass", role: .search) {
        NavigationStack { SearchView() }
    }
}
```

`role: .search` integrates with `.searchable` and dedicates the tab to system search behavior.

### `.tabBarMinimizeBehavior(_:)`
```swift
.tabBarMinimizeBehavior(.automatic)    // system chooses (default)
.tabBarMinimizeBehavior(.onScrollDown) // collapse when content scrolls down
.tabBarMinimizeBehavior(.never)        // always full
```

### `.tabViewBottomAccessory { … }`
Persistent floating element above the tab bar (think: now-playing strip in Music).
```swift
TabView { /* tabs */ }
    .tabViewBottomAccessory {
        HStack {
            Image(systemName: "play.fill")
            Text("Now Playing")
            Spacer()
        }
        .padding()
    }
```

Inside the accessory, observe `\.tabViewBottomAccessoryPlacement`:
```swift
@Environment(\.tabViewBottomAccessoryPlacement) var placement
// .expanded | .collapsed
```

---

## 10. Search

### `.searchable(text:)`
Renders the new iOS 26 glass search field automatically.
```swift
NavigationStack {
    ResultsView()
}
.searchable(text: $query)
```

### `.searchToolbarBehavior(_:)`
```swift
.searchToolbarBehavior(.minimize)   // collapses to icon until tapped
```

### Default toolbar item
Pin search to a specific toolbar placement:
```swift
.toolbar {
    ToolbarItem(placement: .bottomBar) {
        DefaultToolbarItem(kind: .search, placement: .bottomBar)
    }
}
```

---

## 11. Sheets and presentations

Sheets in iOS 26 inherit glass on their grabber and surrounding chrome. Use detents normally; clear backgrounds where the design calls for it.

### Detents + clear content
```swift
.sheet(isPresented: $showInfo) {
    InfoView()
        .presentationDetents([.medium, .large])
        .scrollContentBackground(.hidden)         // let glass show through scrollables
        .containerBackground(.clear, for: .navigation)
}
```

### Zoom transitions (matched morph)
```swift
@Namespace var ns

Button("Info", systemImage: "info") { showInfo = true }
    .matchedTransitionSource(id: "info", in: ns)

.sheet(isPresented: $showInfo) {
    InfoView()
        .navigationTransition(.zoom(sourceID: "info", in: ns))
}
```

---

## 12. Shape primitives for glass

Use these as the `in:` argument to `glassEffect`:

```swift
.capsule                                         // default
.circle
.rect(cornerRadius: 16)
.rect(cornerRadius: .containerConcentric)        // matches parent radius
.ellipse
RoundedRectangle(cornerRadius: 20, style: .continuous)
UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 4, ...)
```

### Concentric corners
When a glass shape lives inside another rounded container (a card inside a sheet, a button inside a panel), use `.containerConcentric` so the inner radius is computed to be visually concentric with the outer one:
```swift
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))
```

---

## 13. Accessibility hooks

Glass automatically reacts to most accessibility settings, but you can opt out or strengthen behavior:

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion)       var reduceMotion

Text("Adaptive")
    .padding()
    .glassEffect(reduceTransparency ? .identity : .regular)
```

Automatic adaptations baked in:
- **Reduce Transparency** → glass densifies into an opaque material
- **Increase Contrast** → adds stark borders, raises tint saturation
- **Reduce Motion** → kills morphing, shimmer, specular animation
- **Tinted Mode** (iOS 26.1+) → user-controlled opacity multiplier

Full guidance: `references/05-accessibility.md`.

---

## 14. Layout helpers introduced alongside

### Background extension (`NavigationSplitView`)
Stretch background imagery beneath a sidebar instead of cutting at the divider:
```swift
NavigationSplitView {
    Sidebar()
} detail: {
    Detail()
        .backgroundExtensionEffect()   // extends content under the sidebar's glass
}
```

### Scroll extension
```swift
ScrollView(.horizontal) { /* … */ }
    .scrollExtensionMode(.underSidebar)
```

---

## 15. Minimum requirements

| Target | Version |
|---|---|
| iOS / iPadOS | 26.0+ |
| macOS | 26.0 (Tahoe) |
| watchOS | 26.0+ |
| tvOS | 26.0+ |
| visionOS | 26.0+ |
| Xcode | 26.0+ |
| Swift | 6.1+ |

Hardware floor on iPhone: **iPhone 11 or later** (older devices fall back to a flat translucent material managed by the system; you don't need to write the fallback).

---

## 16. Cheat sheet

```swift
// Single control
.glassEffect()
.glassEffect(.regular.tint(.blue))
.glassEffect(.regular.interactive())
.glassEffect(.clear, in: .rect(cornerRadius: 24))

// Group
GlassEffectContainer(spacing: 20) { /* glassy children */ }

// Morphing
@Namespace var ns
.glassEffect().glassEffectID("foo", in: ns)
withAnimation(.bouncy) { state.toggle() }

// Distant union
.glassEffectUnion(id: "tools", namespace: ns)

// Buttons
.buttonStyle(.glass)
.buttonStyle(.glassProminent)

// Tabs
TabView { Tab(...) { ... } }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory { ... }

// Search
.searchable(text: $q)
.searchToolbarBehavior(.minimize)

// A11y
.glassEffect(reduceTransparency ? .identity : .regular)
```

---

## Sources

- Apple Developer: [`glassEffect(_:in:)`](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))
- Apple Developer: [`GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- Apple Developer: [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- WWDC25 Session 219 — *Meet Liquid Glass*
- WWDC25 Session 284 — *Get to know the new design system*
- WWDC25 Session 323 — *Build a SwiftUI app with the new design*
- [LiquidGlassReference](https://github.com/conorluddy/LiquidGlassReference) by Conor Luddy
