# Pattern — Glass Modal Sheet

## Problem
A sheet that integrates with the iOS 26 design system: the grabber and surrounding chrome are glass (system-provided), content reads clearly through it, and presentation morphs from a source button.

## Solution — basic sheet

```swift
struct ParentView: View {
    @State private var showInfo = false

    var body: some View {
        ContentView()
            .toolbar {
                ToolbarItem {
                    Button("Info", systemImage: "info.circle") {
                        showInfo = true
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                InfoSheet()
                    .presentationDetents([.medium, .large])
            }
    }
}

struct InfoSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About this feature")
                        .font(.title2.bold())
                    Text("Long-form body text…")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

The system gives you:
- Glass grabber
- Glass toolbar chrome
- Adaptive corner radii for the sheet itself

You give it:
- `.presentationDetents` for sizing
- `.scrollContentBackground(.hidden)` so glass shows through scrollables

## Variations

### Morph from source button (zoom transition)
```swift
@Namespace private var ns
@State private var showSheet = false

Button("Open", systemImage: "doc.text") { showSheet = true }
    .matchedTransitionSource(id: "doc", in: ns)

.sheet(isPresented: $showSheet) {
    DocumentView()
        .navigationTransition(.zoom(sourceID: "doc", in: ns))
}
```

The button expands visually into the sheet — its glass morphs into the sheet's chrome glass.

### Tall sheet that doesn't dim background
```swift
.sheet(isPresented: $showSheet) {
    Content()
        .presentationDetents([.large])
        .presentationBackground(.clear)         // glass shows full background
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
}
```

### Custom detent
```swift
.presentationDetents([.height(220), .medium, .large])
```

## Gotchas

- Don't apply `.glassEffect()` to the sheet's root view. The system already handles sheet chrome glass; an extra layer creates glass-on-glass.
- `.containerBackground(.clear, for: .navigation)` lets the nav-bar glass blend with the sheet's glass behind it.
- For a fully opaque sheet (settings form), skip `.scrollContentBackground(.hidden)` — `Form` looks better with its default backing.
