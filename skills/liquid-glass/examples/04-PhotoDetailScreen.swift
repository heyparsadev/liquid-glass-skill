// PhotoDetailScreen.swift
// Liquid Glass example: a full-bleed photo with a floating glass toolbar
// that morphs when its extra tools expand.
//
// Functional layer (glass): the close button, and the floating toolbar in one
// GlassEffectContainer. The expanded tools grow out of their neighbors
// (matchedGeometry, the default within the container's spacing), so they get
// no opacity transitions.
// Content layer (no glass): the photo.
//
// Requires: Xcode 26 or later, iOS 26 or later.

import SwiftUI

struct PhotoDetailScreen: View {
    @State private var expanded = false
    @State private var favorited = false
    @Namespace private var ns

    var body: some View {
        ZStack {
            // Content layer: the photo
            photo
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Floating toolbar: one container, and an ID on every member so the
                // new tools can grow out of their neighbors.
                GlassEffectContainer(spacing: 14) {
                    HStack(spacing: 14) {
                        toolButton("square.and.arrow.up", label: "Share") { }
                            .glassEffectID("share", in: ns)

                        Button {
                            favorited.toggle()
                        } label: {
                            Image(systemName: favorited ? "heart.fill" : "heart")
                                .contentTransition(.symbolEffect(.replace))
                                .symbolEffect(.bounce, value: favorited)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .tint(favorited ? .red : .primary)    // red means "favorite"; otherwise monochrome
                        .accessibilityLabel(favorited ? "Remove from Favorites" : "Favorite")
                        .glassEffectID("favorite", in: ns)

                        toolButton("info.circle", label: "Info") { }
                            .glassEffectID("info", in: ns)

                        if expanded {
                            toolButton("crop", label: "Crop") { }
                                .glassEffectID("crop", in: ns)
                            toolButton("wand.and.stars", label: "Enhance") { }
                                .glassEffectID("enhance", in: ns)
                        }

                        Button {
                            withAnimation(.bouncy) { expanded.toggle() }
                        } label: {
                            Image(systemName: expanded ? "xmark" : "ellipsis")
                                .contentTransition(.symbolEffect(.replace))
                                .font(.title3)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .tint(.primary)
                        .accessibilityLabel(expanded ? "Fewer Tools" : "More Tools")
                        .glassEffectID("more", in: ns)
                    }
                }
                .padding(.bottom, 28)
            }

            // Top-leading close button: a single glass element, far from the toolbar
            VStack {
                HStack {
                    Button { } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .tint(.primary)
                    .accessibilityLabel("Close")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func toolButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(.primary)                       // monochrome labels; tint is reserved for meaning
        .accessibilityLabel(label)
    }

    private var photo: some View {
        // Stand-in for a real image. Varied content gives the glass something to lens.
        // Positions are derived from the index, so they don't change on every redraw.
        LinearGradient(
            colors: [.orange, .red, .purple, .indigo],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 80 + CGFloat((i * 37) % 160))
                    .blur(radius: 30)
                    .offset(x: CGFloat((i * 53) % 320) - 160,
                            y: CGFloat(i * 80) - 320)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    PhotoDetailScreen()
}
