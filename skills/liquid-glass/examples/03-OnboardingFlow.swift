// OnboardingFlow.swift
// Liquid Glass example: three-step onboarding over a live gradient.
//
// Functional layer (glass): the Skip button, the page indicator (glass dots
// that resize and blend as the step changes), and the prominent Continue
// button, which is the one primary action.
// Content layer (no glass): the gradient backdrop, the hero symbol (on a
// standard material), and the text.
// Motion follows Reduce Motion: pages fade instead of sliding, and springs calm down.
//
// Requires: Xcode 26 or later, iOS 26 or later.

import SwiftUI

struct OnboardingFlow: View {
    @State private var step = 0
    @Namespace private var ns
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        .init(symbol: "wand.and.stars",
              title: "Made for you",
              body: "Hand-curated recommendations that adapt as you listen."),
        .init(symbol: "headphones",
              title: "Lossless, everywhere",
              body: "Hi-Res Audio streams over Wi-Fi, AirPlay, and CarPlay."),
        .init(symbol: "person.2.fill",
              title: "Share the moment",
              body: "Listen together with friends in real time, anywhere.")
    ]

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                // Top bar: Skip
                HStack {
                    Spacer()
                    if step < pages.count - 1 {        // removed rather than faded: glass materializes out
                        Button("Skip") {
                            withAnimation(stepAnimation) { step = pages.count - 1 }
                        }
                        .buttonStyle(.glass)
                        .tint(.primary)                // monochrome label
                    }
                }
                .frame(minHeight: 44)                  // keeps the layout steady when Skip goes away
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Hero: content, not glass
                pageView(for: pages[step])
                    .id(step)
                    .transition(pageTransition)

                Spacer()

                // Page indicator: glass capsules that resize and blend inside one container
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(pages.indices, id: \.self) { i in
                            Color.clear
                                .frame(width: i == step ? 28 : 8, height: 8)
                                .glassEffect(.regular.tint(i == step ? .white : nil), in: .capsule)
                                .glassEffectID("dot-\(i)", in: ns)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page \(step + 1) of \(pages.count)")
                .padding(.bottom, 24)

                // The one primary action
                Button {
                    withAnimation(stepAnimation) {
                        if step < pages.count - 1 { step += 1 }
                    }
                } label: {
                    Text(step == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)          // accent-colored background by default
                .controlSize(.large)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var stepAnimation: Animation {
        reduceMotion ? .smooth : .bouncy
    }

    private var pageTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                          removal: .move(edge: .leading).combined(with: .opacity))
    }

    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Image(systemName: page.symbol)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 160, height: 160)
                .background(.ultraThinMaterial, in: .circle)   // content layer: a material, not glass
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 40)
            }
            .foregroundStyle(.white)
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [.cyan, .blue, .indigo, .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay {
            // Soft orbs give the glass varied content to refract.
            Circle().fill(.purple.opacity(0.5)).frame(width: 280, height: 280).blur(radius: 60).offset(x: -120, y: -200)
            Circle().fill(.pink.opacity(0.4)).frame(width: 300, height: 300).blur(radius: 80).offset(x: 140, y: 220)
        }
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
}

#Preview {
    OnboardingFlow()
}
