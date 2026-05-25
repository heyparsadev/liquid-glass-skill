# Anti-patterns

Things that look like Liquid Glass but aren't, or that the API technically allows but the design language forbids. Each item has a wrong example and the right replacement.

---

## 1. Glass-on-glass-on-glass

❌ **Wrong**
```swift
ZStack {
    Color.gray
    VStack {
        Text("Card")
            .padding()
            .glassEffect()           // glass layer 1
    }
    .padding()
    .glassEffect()                   // glass layer 2 — wrapping layer 1
}
.glassEffect()                       // glass layer 3 — full screen
```

Glass can't sample glass. Each layer flattens into blur, lensing is gone, and you pay for three render passes.

✅ **Right** — one glass surface, one container
```swift
GlassEffectContainer(spacing: 16) {
    VStack {
        Text("Card")
            .padding()
    }
    .padding()
    .glassEffect(.regular, in: .rect(cornerRadius: 24))
}
```

---

## 2. `.ultraThinMaterial` everywhere

❌ **Wrong** — legacy material in iOS 26
```swift
Text("Header")
    .padding()
    .background(.ultraThinMaterial, in: Capsule())
```

In iOS 26, this renders as the **old** material — flat, no lensing, no specular. It looks out of place sitting next to system chrome that's full Liquid Glass.

✅ **Right**
```swift
Text("Header")
    .padding()
    .glassEffect()                   // gets the full iOS 26 treatment
```

---

## 3. Glass on content backgrounds

❌ **Wrong** — glass as the whole screen background
```swift
ZStack {
    Color.background
        .glassEffect()                // glass over nothing = gray blob
    List(items) { ... }
}
```

Glass refracts what's *behind* it. Over a flat color, there's nothing to refract — you get blur of the same flat color, which is just flat color again.

✅ **Right** — glass only on chrome that floats above varied content
```swift
ZStack {
    Image("hero").resizable().ignoresSafeArea()
    List(items) { ... }
        .scrollContentBackground(.hidden)
}
// Nav bar / tab bar / floating buttons get glass automatically
```

---

## 4. Brand-tinted glass

❌ **Wrong** — using glass tint as your brand color carrier
```swift
NavigationStack { ... }
    .toolbarBackground(.purple, for: .navigationBar)   // brand purple
// or, on a custom button:
Button("Browse") { }
    .glassEffect(.regular.tint(.purple).opacity(0.9))  // saturated tint
```

A saturated tint floods the refraction with one color. The lensing effect — the whole point of glass — is gone. You've made a purple pill, not glass.

✅ **Right** — tint the **content**, leave glass neutral
```swift
NavigationStack { ... }
    .tint(.purple)                                     // tints content (icons, labels)

Button(action: {}) {
    Label("Browse", systemImage: "magnifyingglass")
}
.buttonStyle(.glass)
.tint(.purple)                                         // content tint, not glass tint
```

---

## 5. Animating glass opacity

❌ **Wrong**
```swift
view
    .glassEffect()
    .opacity(visible ? 1 : 0)
    .animation(.smooth, value: visible)
```

Fading glass opacity dims the lensing as well, producing a muddy ghost that doesn't read as glass *or* solid.

✅ **Right** — use `isEnabled` or `.identity` and let the system materialize
```swift
view
    .glassEffect(.regular, isEnabled: visible)
    .animation(.smooth, value: visible)

// or with morph
.glassEffectTransition(.materialize)
```

---

## 6. Hardcoded corner radii inside rounded containers

❌ **Wrong**
```swift
VStack {
    Button("Save") {}
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
}
.padding()
.background(RoundedRectangle(cornerRadius: 28).fill(.background))
```

The inner radius (12) and outer radius (28) aren't concentric. The corners look subtly off.

✅ **Right**
```swift
VStack {
    Button("Save") {}
        .glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))
}
.padding()
.background(RoundedRectangle(cornerRadius: 28).fill(.background))
```

---

## 7. Glass per `List` row

❌ **Wrong**
```swift
List(items) { item in
    HStack { Image(item.icon); Text(item.title) }
        .padding()
        .glassEffect()
}
```

Each row gets its own glass pass; List virtualization fights the glass batching; the screen ends up at sub-30fps when scrolled.

✅ **Right** — content rows stay flat; chrome stays glassy
```swift
List(items) { item in
    HStack { Image(item.icon); Text(item.title) }
}
.scrollContentBackground(.hidden)
// The toolbar / tab bar above this list provides the glass
```

---

## 8. Skipping `GlassEffectContainer` for groups

❌ **Wrong**
```swift
HStack(spacing: 8) {
    iconButton("pencil")
    iconButton("eraser")
    iconButton("scissors")
    iconButton("trash")
}
```
Each `iconButton` uses `.glassEffect()` internally → 4 passes, no morphing, weird gap blending.

✅ **Right**
```swift
GlassEffectContainer(spacing: 8) {
    HStack(spacing: 8) {
        iconButton("pencil")
        iconButton("eraser")
        iconButton("scissors")
        iconButton("trash")
    }
}
```

---

## 9. `.interactive()` on everything

❌ **Wrong**
```swift
Text("Total")
    .glassEffect(.regular.interactive())   // not touchable, why interactive?

ForEach(0..<50) { _ in
    Image(systemName: "star")
        .glassEffect(.regular.interactive())  // 50 gesture recognizers
}
```

`.interactive()` installs gesture machinery and a per-frame highlight tracker. On static elements it's pure waste; at scale it's a hitch.

✅ **Right** — only on what users actually touch
```swift
Button("Tap me") { }.glassEffect(.regular.interactive())
Text("Total").glassEffect()                   // not touchable, no .interactive()
```

---

## 10. Forgetting `withAnimation` around morphing state

❌ **Wrong**
```swift
Button("Toggle") { expanded.toggle() }
    .glassEffectID("toggle", in: ns)

if expanded {
    Button("A").glassEffectID("a", in: ns)
}
```

Without `withAnimation`, the state flips instantly. The morph engine has no animation curve to interpolate along — you get a hard cut, exactly the thing morphing was supposed to fix.

✅ **Right**
```swift
Button("Toggle") {
    withAnimation(.bouncy) { expanded.toggle() }
}
.glassEffectID("toggle", in: ns)
```

---

## 11. Re-glassing system chrome

❌ **Wrong**
```swift
NavigationStack { ... }
    .toolbar { ToolbarItem { Button("Done") {}.glassEffect() } }
//                                            ^^^ system already gives it glass
```

System toolbar items, tab bars, and search fields are glass by default. Adding another `.glassEffect()` produces glass-on-glass (see #1).

✅ **Right** — just use the system items
```swift
.toolbar { ToolbarItem { Button("Done") {} } }   // glass, automatically
```

If you want a primary action style:
```swift
.toolbar {
    ToolbarItem {
        Button("Save") {}
            .buttonStyle(.glassProminent)
    }
}
```

---

## 12. Custom blurs to imitate glass

❌ **Wrong**
```swift
.background(
    Rectangle()
        .fill(.white.opacity(0.2))
        .blur(radius: 20)
)
```

A blur is not a lens. No refraction, no specular, no morph, no Reduce-Transparency adaptation. You're shipping the iOS 7 look in 2026.

✅ **Right**
```swift
.glassEffect()                                  // real Liquid Glass
```

---

## 13. Animating glass via `.linear`

❌ **Wrong**
```swift
withAnimation(.linear(duration: 0.3)) { state.toggle() }
```

Linear curves strip the elasticity Liquid Glass is built around — morphs feel mechanical.

✅ **Right**
```swift
withAnimation(.bouncy) { state.toggle() }
```

---

## 14. Color-only semantic state

❌ **Wrong**
```swift
Button("Delete") { delete() }
    .buttonStyle(.glassProminent)
    .tint(.red)               // only color says "destructive"
```

Color blindness, Smart Invert, or `Differentiate Without Color` strips your one signal.

✅ **Right** — color **plus** role **plus** icon
```swift
Button(role: .destructive) { delete() } label: {
    Label("Delete", systemImage: "trash")
}
.buttonStyle(.glassProminent)
```

---

## 15. Full-screen glass for "premium feel"

❌ **Wrong**
```swift
ZStack {
    Image("backdrop").resizable().ignoresSafeArea()
    ContentView()
}
.glassEffect()                                  // glass over the whole window
```

This is the iOS 7 frosted-overlay pattern. Liquid Glass is **not** a screen-wide veneer; it's a chrome material. A glass full-screen surface refracts itself into mud.

✅ **Right** — let glass live on the chrome layer only
```swift
ZStack {
    Image("backdrop").resizable().ignoresSafeArea()
    ContentView()
}
// nav bar / tab bar / floating controls — all glass via system
```
