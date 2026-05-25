// MusicPlayerScreen.swift
// iOS 26 Liquid Glass example — full-bleed artwork with floating glass controls.
// Demonstrates: glass play/pause + skip controls in a container,
// interactive glass tint on the like button, morphing favorite toggle.

import SwiftUI

struct MusicPlayerScreen: View {
    @State private var playing = true
    @State private var liked = false
    @State private var progress: Double = 0.34
    @Namespace private var ns

    var body: some View {
        ZStack {
            // Content layer — full-bleed artwork
            artwork
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Track info
                VStack(spacing: 6) {
                    Text("Vesper Tide")
                        .font(.title.bold())
                    Text("Lyra Calder · Equinox")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
                .padding(.bottom, 24)

                // Progress
                progressBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                // Glass control cluster — single container, batched render
                GlassEffectContainer(spacing: 20) {
                    HStack(spacing: 20) {
                        controlButton("backward.fill", size: 48) { }
                            .glassEffectID("back", in: ns)

                        Button {
                            withAnimation(.bouncy) { playing.toggle() }
                        } label: {
                            Image(systemName: playing ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .frame(width: 72, height: 72)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                        .tint(.white.opacity(0.25))
                        .glassEffectID("play", in: ns)

                        controlButton("forward.fill", size: 48) { }
                            .glassEffectID("forward", in: ns)
                    }
                }
                .padding(.bottom, 24)

                // Secondary glass cluster — like + lyrics + share
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.bouncy) { liked.toggle() }
                        } label: {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .symbolEffect(.bounce, value: liked)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .tint(liked ? .red : .white)

                        Button { } label: {
                            Image(systemName: "text.bubble")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .tint(.white)

                        Button { } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .tint(.white)
                    }
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal)
        }
        .preferredColorScheme(.dark)
    }

    private var artwork: some View {
        LinearGradient(
            colors: [.indigo, .purple, .pink, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            // Subtle grain so glass has something to lens
            Canvas { ctx, size in
                for _ in 0..<400 {
                    let x = Double.random(in: 0...size.width)
                    let y = Double.random(in: 0...size.height)
                    let r = Double.random(in: 0.5...2.0)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                             with: .color(.white.opacity(0.08)))
                }
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule().fill(.white).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)

            HStack {
                Text("1:14")
                Spacer()
                Text("-2:21")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func controlButton(_ symbol: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: size, height: size)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(.white)
    }
}

#Preview {
    MusicPlayerScreen()
}
