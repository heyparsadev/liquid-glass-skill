// PhotoDetailScreen.swift
// iOS 26 Liquid Glass example — full-bleed photo with a floating glass toolbar
// that morphs when an actions menu expands. Mirrors the Photos app pattern.

import SwiftUI

struct PhotoDetailScreen: View {
    @State private var expanded = false
    @State private var favorited = false
    @Namespace private var ns

    var body: some View {
        ZStack {
            // Content layer — the photo itself
            photo
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Floating glass toolbar — morphs on expand
                GlassEffectContainer(spacing: 14) {
                    HStack(spacing: 14) {
                        toolButton(systemImage: "square.and.arrow.up") { }
                            .glassEffectID("share", in: ns)

                        Button {
                            withAnimation(.bouncy) { favorited.toggle() }
                        } label: {
                            Image(systemName: favorited ? "heart.fill" : "heart")
                                .symbolEffect(.bounce, value: favorited)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .tint(favorited ? .red : .white)
                        .glassEffectID("favorite", in: ns)

                        toolButton(systemImage: "info.circle") { }
                            .glassEffectID("info", in: ns)

                        if expanded {
                            toolButton(systemImage: "crop") { }
                                .glassEffectID("crop", in: ns)
                                .transition(.scale.combined(with: .opacity))
                            toolButton(systemImage: "wand.and.stars") { }
                                .glassEffectID("ai", in: ns)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Button {
                            withAnimation(.bouncy) { expanded.toggle() }
                        } label: {
                            Image(systemName: expanded ? "xmark" : "ellipsis")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .tint(.white)
                        .glassEffectID("more", in: ns)
                    }
                }
                .padding(.bottom, 28)
            }

            // Top-left close button — independent glass element
            VStack {
                HStack {
                    Button { } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .tint(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func toolButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(.white)
    }

    private var photo: some View {
        // Stand-in for a real image — vivid varied content gives glass something to lens
        LinearGradient(
            colors: [.orange, .red, .purple, .indigo],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: CGFloat.random(in: 80...240))
                    .blur(radius: 30)
                    .offset(
                        x: CGFloat.random(in: -160...160),
                        y: CGFloat(i * 80) - 320
                    )
            }
        }
    }
}

#Preview {
    PhotoDetailScreen()
}
