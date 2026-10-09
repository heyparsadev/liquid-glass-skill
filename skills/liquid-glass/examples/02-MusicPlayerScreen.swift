// MusicPlayerScreen.swift
// Liquid Glass example: full-bleed artwork with floating media controls.
//
// Functional layer: the transport and secondary controls, in clear glass.
// Clear glass fits here because all three of Apple's conditions hold: the
// controls float over media-rich artwork, the artwork can take a dimming layer,
// and the symbols on the glass are bold and bright. Every control uses .clear,
// never mixed with .regular.
// Content layer: the artwork, the dimming layer, the track info, the progress bar.
//
// Requires: Xcode 26 or later, iOS 26 or later.

import SwiftUI

struct MusicPlayerScreen: View {
    @State private var playing = true
    @State private var liked = false
    @State private var progress: Double = 0.34

    var body: some View {
        ZStack {
            // Content layer: full-bleed artwork
            artwork
                .ignoresSafeArea()

            // Dimming layer beneath the clear glass. The HIG suggests about 35%
            // over bright content.
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                Spacer()

                // Track info
                VStack(spacing: 6) {
                    Text("Vesper Tide")
                        .font(.title.bold())
                    Text("Lyra Calder · Equinox")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
                .padding(.bottom, 24)

                // Progress
                progressBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                // Transport controls: one container, so the shapes are sampled
                // and rendered together.
                GlassEffectContainer(spacing: 20) {
                    HStack(spacing: 20) {
                        controlButton("backward.fill", label: "Previous", size: 52) { }

                        controlButton(playing ? "pause.fill" : "play.fill",
                                      label: playing ? "Pause" : "Play",
                                      size: 76, weight: .bold) {
                            playing.toggle()
                        }

                        controlButton("forward.fill", label: "Next", size: 52) { }
                    }
                }
                .padding(.bottom, 24)

                // Secondary controls
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            liked.toggle()
                        } label: {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .contentTransition(.symbolEffect(.replace))
                                .symbolEffect(.bounce, value: liked)
                                .font(.title3.weight(.semibold))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(liked ? Color.red : Color.white)   // red means "liked"
                        .glassEffect(.clear.interactive(), in: .circle)
                        .accessibilityLabel(liked ? "Unlike" : "Like")

                        controlButton("quote.bubble", label: "Lyrics", size: 44) { }
                        controlButton("square.and.arrow.up", label: "Share", size: 44) { }
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
            // Grain with deterministic positions, so it stays put across redraws.
            Canvas { ctx, size in
                for i in 0..<400 {
                    let x = Double((i * 7_919) % 1_000) / 1_000 * size.width
                    let y = Double((i * 104_729) % 1_000) / 1_000 * size.height
                    let r = 0.5 + Double((i * 1_299_709) % 1_000) / 1_000 * 1.5
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
                    Capsule().fill(.white.opacity(0.25))
                    Capsule().fill(.white).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)
            .accessibilityElement()
            .accessibilityLabel("Playback position")
            .accessibilityValue("1 minute 14 seconds of 3 minutes 35 seconds")

            HStack {
                Text("1:14")
                Spacer()
                Text("-2:21")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.75))
        }
    }

    /// A circular clear-glass control. `.buttonStyle(.glass(.clear))` would also work,
    /// but it needs iOS 26.1. A plain button with an interactive glass effect works on 26.0.
    private func controlButton(_ symbol: String, label: String, size: CGFloat,
                               weight: Font.Weight = .semibold,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: weight))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .glassEffect(.clear.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}

#Preview {
    MusicPlayerScreen()
}
