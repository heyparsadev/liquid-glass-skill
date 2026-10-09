# Pattern: glass sheet

## Problem
You want a sheet that fits the design system: the system glass background, correct Close, Cancel, and Done placement, sizing with detents, and a presentation that grows out of the control that opened it.

## Solution: informational sheet

```swift
struct ParentView: View {
    @State private var showInfo = false
    @Namespace private var ns

    var body: some View {
        NavigationStack {
            ContentView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("About", systemImage: "info.circle") { showInfo = true }
                    }
                    .matchedTransitionSource(id: "info", in: ns)   // ToolbarContent version, iOS 26
                }
                .sheet(isPresented: $showInfo) {
                    InfoSheet()
                        .presentationDetents([.medium, .large])
                        .navigationTransition(.zoom(sourceID: "info", in: ns))
                }
        }
    }
}

struct InfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("About this feature") {
                    Text("Long-form explanation…")
                }
            }
            .scrollContentBackground(.hidden)              // List/Form only: lets the sheet's glass show
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }     // standard ✕ (iOS 26 default label)
                }
            }
        }
    }
}
```

The system provides the Liquid Glass sheet background, inset from the edges at partial heights, along with the glass grabber, the toolbar, and corner radii. You provide the detents, the buttons, and the content.

## Variation: task sheet (Cancel + Done)

HIG Sheets (March 2026) says that for a single-view sheet, "the Cancel button belongs on the leading edge of the top toolbar", and Done belongs on the trailing edge. Always pair Done with Cancel, or with Back in multi-step sheets, and never show all three.

```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel", role: .cancel) { dismiss() }
    }
    ToolbarItem(placement: .confirmationAction) {
        Button("Done") { save(); dismiss() }
            .buttonStyle(.glassProminent)
            .disabled(!isValid)
    }
}
```

## Variation: interact with the content behind

```swift
.sheet(isPresented: .constant(true)) {
    PlaceDetail()
        .presentationDetents([.height(220), .medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))   // .medium must be a detent
        .interactiveDismissDisabled()
}
```

## iOS 27 variations

```swift
// Fade in over the content instead of sliding up (not macOS)
.sheet(isPresented: $showFilters) {
    FiltersView()
        .presentationDetents([.medium])
        .navigationTransition(.crossFade)
}

// Dock the sheet to an edge in wide layouts. Only sheets respect it.
.sheet(item: $place) { place in
    PlaceDetail(place: place)
        .presentationDetents([.medium, .large])
        .presentationPlacement(.leading)
}
```

Both are iOS 27.0+. Gate them on a 26 target ([10 § 3](../references/10-migrating-to-ios27.md#3-gating-ios-27-apis)).

## Gotchas
- **Never add `.glassEffect()` to the sheet's root, and never set `.presentationBackground(…)`.** Both replace or stack on the system glass.
- **`.scrollContentBackground(.hidden)`** only affects `List`, `Form`, and other views with a system background. A plain `ScrollView` has none. For a settings-style sheet, keep the `Form`'s default backing.
- **iOS 27 SDK.** `controlSize`, `buttonSizing`, and `ButtonBorderShape` reset inside sheets and popovers. Set them on the controls inside the sheet, not on the presenting view.
- **Dialogs.** Attach `.confirmationDialog` to the button that triggers it, so it morphs out of that button.
- **Zoom transitions.** For a toolbar source, attach `matchedTransitionSource` to the `ToolbarItem`, not to the `Button` inside. For an ordinary button, the `View` version works.
