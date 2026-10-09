# Anti-patterns

Use this file when reviewing or fixing code. Each entry pairs a ❌ snippet with a ✅ one and gives the reason. The [linter](../scripts/check_glass.py) catches the ones marked 🔎.

## Contents

| # | Anti-pattern | Category |
|---|---|---|
| 1 | [Glass on content](#1-glass-on-content) | Layering |
| 2 | [Glass on glass](#2-glass-on-glass) | Layering |
| 3 | [Nearby glass without one shared container](#3-nearby-glass-without-one-shared-container) | Grouping |
| 4 | [Re-glassing system chrome](#4-re-glassing-system-chrome) | Chrome |
| 5 | [Custom bar backgrounds](#5-custom-bar-backgrounds) | Chrome |
| 6 | [Faking glass with materials or blur](#6-faking-glass-with-materials-or-blur) 🔎 | Material |
| 7 | [Dropping glass for Reduce Transparency](#7-dropping-glass-for-reduce-transparency) | Accessibility |
| 8 | [Invented API](#8-invented-api) 🔎 | Correctness |
| 9 | [Hard-coded inner corner radii](#9-hard-coded-inner-corner-radii) | Shape |
| 10 | [Fading glass with opacity](#10-fading-glass-with-opacity) | Motion |
| 11 | [A morph missing a piece](#11-a-morph-missing-a-piece) | Motion |
| 12 | [Container spacing that fuses controls by accident](#12-container-spacing-that-fuses-controls-by-accident) | Grouping |
| 13 | [Tinting everything](#13-tinting-everything) | Color |
| 14 | [A destructive action as the prominent primary](#14-a-destructive-action-as-the-prominent-primary) | Color |
| 15 | [Clear glass without its conditions](#15-clear-glass-without-its-conditions) | Material |
| 16 | [Interactive glass on things nobody touches](#16-interactive-glass-on-things-nobody-touches) | Interaction |
| 17 | [Overriding the sheet background](#17-overriding-the-sheet-background) | Presentations |
| 18 | [Dialogs attached to the screen, not the button](#18-dialogs-attached-to-the-screen-not-the-button) | Presentations |
| 19 | [Glass controls inside the tab bar accessory](#19-glass-controls-inside-the-tab-bar-accessory) | Chrome |
| 20 | [Hand-made chrome that iOS 27 provides](#20-hand-made-chrome-that-ios-27-provides) | Chrome |
| 21 | [iOS 27 APIs without a gate on a 26 target](#21-ios-27-apis-without-a-gate-on-a-26-target) 🔎 | Availability |
| 22 | [A custom Sign in with Apple button](#22-a-custom-sign-in-with-apple-button) | Platform rules |

---

## 1. Glass on content

❌
```swift
VStack(alignment: .leading) {
    Text(order.title).font(.headline)
    Text(order.status).foregroundStyle(.secondary)
}
.padding()
.glassEffect(.regular, in: .rect(cornerRadius: 20))      // a content card made of glass
```

✅
```swift
VStack(alignment: .leading) {
    Text(order.title).font(.headline)
    Text(order.status).foregroundStyle(.secondary)
}
.padding()
.frame(maxWidth: .infinity, alignment: .leading)
.background(.background, in: .rect(cornerRadius: 20))    // solid content surface
// over imagery: .background(.regularMaterial, in: .rect(cornerRadius: 20))
```

"Don't use Liquid Glass in the content layer … use standard materials for elements in the content layer" (HIG Materials). Cards, rows, chips, heroes, and backgrounds are content. A glass full-screen background is the same mistake on a larger scale.

---

## 2. Glass on glass

❌
```swift
HStack {
    Text("Now Playing")
    Text("LIVE").padding(6).glassEffect()                 // glass…
}
.padding()
.glassEffect()                                            // …on glass
```

✅
```swift
HStack {
    Text("Now Playing")
    Text("LIVE")
        .font(.caption.bold())
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(.red, in: .capsule)                   // a fill on top of the glass
        .foregroundStyle(.white)
}
.padding()
.glassEffect()
```

"Always avoid glass on glass … use fills, transparency, and vibrancy for the top elements" (WWDC25 219).

---

## 3. Nearby glass without one shared container

❌
```swift
HStack(spacing: 8) {
    GlassEffectContainer { formatButton("bold", "Bold") }
    GlassEffectContainer { formatButton("italic", "Italic") }   // or no container at all
}
```

✅
```swift
GlassEffectContainer(spacing: 8) {
    HStack(spacing: 8) {
        formatButton("bold", "Bold")
        formatButton("italic", "Italic")
    }
}
```

"Glass can not sample other glass, so having nearby glass elements in different containers will result in inconsistent behavior" (WWDC25 323). A single container also renders the group together.

---

## 4. Re-glassing system chrome

❌
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button("Done") { }.glassEffect()                  // the item is already glass
    }
}
```

✅
```swift
.toolbar {
    ToolbarItem(placement: .confirmationAction) {
        Button("Done") { }
            .buttonStyle(.glassProminent)                  // only for the one primary action
    }
}
```

Toolbar items, bars, tab bars, search fields, and sheets render glass by themselves.

---

## 5. Custom bar backgrounds

❌
```swift
NavigationStack { … }
    .toolbarBackground(Color.purple, for: .navigationBar)
    .toolbarBackgroundVisibility(.visible, for: .navigationBar)
```

✅
```swift
NavigationStack {
    ScrollView {
        BrandHeader()                                      // brand color lives in the content…
        Feed()
    }
}                                                          // …and scrolls under the untouched glass bar
```

"Reduce the use of toolbar backgrounds and tinted controls" (HIG Toolbars). "To express your brand through color, consider moving it into the content layer" (HIG Branding).

---

## 6. Faking glass with materials or blur

❌
```swift
Button("Filter", systemImage: "line.3.horizontal.decrease") { }
    .padding()
    .background(.ultraThinMaterial, in: .capsule)         // a material on a floating control

Text("Card").padding()
    .background(Rectangle().fill(.white.opacity(0.2)).blur(radius: 20))   // hand-made "glass"
```

✅
```swift
Button("Filter", systemImage: "line.3.horizontal.decrease") { }
    .buttonStyle(.glass)
```

A blur is not a lens. It doesn't refract, it has no highlights, and it doesn't adapt to accessibility settings or to the iOS 27 slider. Standard materials are still right for **content-layer** surfaces.

---

## 7. Dropping glass for Reduce Transparency

❌
```swift
.glassEffect(reduceTransparency ? .identity : .regular)
```

✅
```swift
.glassEffect()        // the system makes glass frostier under Reduce Transparency
```

`.identity` means "your content remains unaffected as if no glass effect was applied". The control loses its backing exactly when the user asked for *more* separation.

---

## 8. Invented API

❌ None of these compile against the shipping SDK:
```swift
.glassEffect(.regular, isEnabled: isOn)                           // no isEnabled:
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))
.toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)       // WWDC26 video spelling
ToolbarItem { DefaultToolbarItem(kind: .search, placement: .bottomBar) }
ToolbarItem { Button("Me", systemImage: "person") { }.sharedBackgroundVisibility(.hidden) }
if placement == .collapsed { … }                                   // TabViewBottomAccessoryPlacement
```

✅
```swift
.glassEffect(isOn ? .regular : .identity)
.glassEffect(.regular, in: .rect(corners: .concentric(minimum: 12), isUniform: true))
.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)   // iOS 27
DefaultToolbarItem(kind: .search, placement: .bottomBar)           // directly in .toolbar { }
ToolbarItem { Button("Me", systemImage: "person") { } }.sharedBackgroundVisibility(.hidden)
if placement == .inline { … }
```

The full list is in [01 § 12](01-api-reference.md#12-names-that-do-not-exist).

---

## 9. Hard-coded inner corner radii

❌
```swift
VStack { Button("Save") { }.padding().glassEffect(.regular, in: .rect(cornerRadius: 12)) }
    .padding()
    .background(.background, in: .rect(cornerRadius: 28))
```

✅
```swift
VStack {
    Button("Save") { }
        .padding()
        .glassEffect(.regular.interactive(), in: .rect(corners: .concentric(minimum: 12), isUniform: true))
}
.padding()
.background(.background, in: .rect(cornerRadius: 28))
.containerShape(.rect(cornerRadius: 28))
```

Without `containerShape`, a concentric shape resolves against the sheet, window, or device instead of the card.

---

## 10. Fading glass with opacity

❌
```swift
control
    .glassEffect()
    .opacity(visible ? 1 : 0)
    .animation(.smooth, value: visible)
```

✅
```swift
GlassEffectContainer {
    if visible {
        control
            .glassEffect()
            .glassEffectTransition(.materialize)
    }
}
// withAnimation { visible.toggle() }
```

Glass "materializes in and out by gradually modulating the light bending and lensing". Fading it produces a muddy ghost.

---

## 11. A morph missing a piece

❌
```swift
Button("More") { expanded.toggle() }               // no animation
    .glassEffectID("more", in: ns)                 // and no shared container
if expanded { Button("Share") { }.glassEffectID("share", in: ns) }
```

✅
```swift
GlassEffectContainer(spacing: 16) {
    VStack(spacing: 16) {
        if expanded {
            Button("Share") { }.buttonStyle(.glass).glassEffectID("share", in: ns)
        }
        Button("More") { withAnimation { expanded.toggle() } }
            .buttonStyle(.glass)
            .glassEffectID("more", in: ns)
    }
}
```

A morph needs a container, IDs in one namespace, and `withAnimation`. Without them it cuts silently.

---

## 12. Container spacing that fuses controls by accident

❌
```swift
GlassEffectContainer(spacing: 40) {               // larger than the layout gap…
    HStack(spacing: 8) { undoButton; redoButton }  // …so the buttons blend into one blob at rest
}
```

✅
```swift
GlassEffectContainer(spacing: 8) {
    HStack(spacing: 8) { undoButton; redoButton }
}
```

"A spacing value on the container that's larger than the spacing of an interior HStack … causes Liquid Glass effects to blend together at rest." Do it only if you want them fused.

---

## 13. Tinting everything

❌
```swift
HStack {
    Button("Log", systemImage: "plus") { }.buttonStyle(.glass).tint(.blue)
    Button("Water", systemImage: "drop") { }.buttonStyle(.glass).tint(.orange)
    Button("Sleep", systemImage: "moon") { }.buttonStyle(.glass).tint(.yellow)
}
```

✅
```swift
GlassEffectContainer(spacing: 12) {
    HStack(spacing: 12) {
        Button("Log", systemImage: "plus") { }.buttonStyle(.glassProminent)   // the one primary
        Button("Water", systemImage: "drop") { }.buttonStyle(.glass)
        Button("Sleep", systemImage: "moon") { }.buttonStyle(.glass)
    }
}
```

"When every element is tinted, nothing stands out" (WWDC25 219). Tint icons only "to convey meaning … not just for visual effect" (WWDC25 323).

---

## 14. A destructive action as the prominent primary

❌
```swift
Button("Delete Account") { delete() }
    .buttonStyle(.glassProminent)
    .tint(.red)
```

✅
```swift
Button(role: .destructive) { confirmDelete = true } label: {
    Label("Delete Account", systemImage: "trash")
}
.buttonStyle(.glass)
.confirmationDialog("Delete your account?", isPresented: $confirmDelete) {
    Button("Delete", role: .destructive) { delete() }
}
```

"Don't assign the primary role to a button that performs a destructive action" (HIG Buttons). Use the role, a symbol, and text; color alone is not enough.

---

## 15. Clear glass without its conditions

❌
```swift
ZStack(alignment: .bottom) {
    BrightPhoto()
    Text("Edit").font(.footnote).padding().glassEffect(.clear)    // thin text, bright photo, no dimming
}
```

✅
```swift
ZStack(alignment: .bottom) {
    BrightPhoto()
    Color.black.opacity(0.35).allowsHitTesting(false)              // dimming beneath the glass
    Label("Edit", systemImage: "slider.horizontal.3")
        .font(.headline)                                            // bold, bright content on top
        .padding()
        .glassEffect(.clear)
}
// or simply use .regular
```

Use clear glass only over media-rich content, with bold content on top and dimming over bright media. Never mix `.clear` and `.regular` in one group.

---

## 16. Interactive glass on things nobody touches

❌
```swift
Text("Total: $42").padding().glassEffect(.regular.interactive())   // not a control
```

✅
```swift
Text("Total: $42").padding().glassEffect()
```

Don't stack a hand-made press effect (`scaleEffect` plus a zero-distance `DragGesture`) on interactive glass either. It already scales, bounces, and shimmers.

---

## 17. Overriding the sheet background

❌
```swift
.sheet(isPresented: $show) {
    Details()
        .presentationBackground(.ultraThinMaterial)       // replaces the system glass
}
```

✅
```swift
.sheet(isPresented: $show) {
    Details()
        .presentationDetents([.medium, .large])
}
```

---

## 18. Dialogs attached to the screen, not the button

❌
```swift
List { … Button("Sign Out", role: .destructive) { ask = true } … }
    .confirmationDialog("Sign out?", isPresented: $ask) { … }
```

✅
```swift
Button("Sign Out", role: .destructive) { ask = true }
    .confirmationDialog("Sign out?", isPresented: $ask) { … }
```

"Dialogs also automatically morph out of the buttons that present them" (WWDC25 323). That only works if the dialog is attached to the button.

---

## 19. Glass controls inside the tab bar accessory

❌
```swift
.tabViewBottomAccessory {
    HStack { Text(track.title); Spacer(); Button("Play", systemImage: "play.fill") { }.buttonStyle(.glass) }
}
```

✅
```swift
.tabViewBottomAccessory {
    HStack {
        Text(track.title).lineLimit(1)
        Spacer()
        Button("Play", systemImage: "play.fill") { }.labelStyle(.iconOnly)   // plain: the accessory is already glass
    }
    .padding(.horizontal)
}
```

---

## 20. Hand-made chrome that iOS 27 provides

❌ (on iOS 27)
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Menu { … } label: { Image(systemName: "ellipsis") }               // custom overflow
    }
}
// …and a floating glass "Cart" button imitating a separated tab
```

✅
```swift
.toolbarOverflowMenu { Button("Archive", systemImage: "archivebox") { } }
// TabView { …; Tab("Cart", systemImage: "cart", role: .prominent) { CartView() } }
```

Both are iOS 27. Gate them on a 26 target ([08 § 9](08-system-chrome.md#9-gating-ios-27-chrome-apis-on-a-26-target)).

---

## 21. iOS 27 APIs without a gate on a 26 target

❌
```swift
// IPHONEOS_DEPLOYMENT_TARGET = 26.0
List(items) { … }
    .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)   // error: only available in iOS 27.0 or newer
```

✅
```swift
extension View {
    @ViewBuilder
    func minimizingNavigationBarOnScroll() -> some View {
        if #available(iOS 27.0, *) {
            toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
        } else {
            self
        }
    }
}

List(items) { … }
    .minimizingNavigationBarOnScroll()
```

---

## 22. A custom Sign in with Apple button

❌
```swift
Button { signIn() } label: {
    VStack { Image(systemName: "apple.logo"); Text("Apple") }
}
.buttonStyle(.glass)
```

✅
```swift
import AuthenticationServices

SignInWithAppleButton(.signIn) { request in
    request.requestedScopes = [.fullName, .email]
} onCompletion: { result in
    handle(result)
}
.signInWithAppleButtonStyle(.white)
.frame(height: 50)
```

The HIG for Sign in with Apple says: "never create a custom Apple logo", "never use the Apple logo as a button", and use only the approved titles. The button's background must be black or white, so it can't be glass. App Review checks custom versions.
