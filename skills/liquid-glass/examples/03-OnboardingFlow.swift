// OnboardingFlow.swift
// iOS 26 Liquid Glass example — 3-step onboarding with morphing glass pagination,
// large prominent CTA, and glass skip pill in the corner.

import SwiftUI

struct OnboardingFlow: View {
    @State private var step = 0
    @Namespace private var ns

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
                // Top bar — skip pill
                HStack {
                    Spacer()
                    Button("Skip") { step = pages.count - 1 }
                        .buttonStyle(.glass)
                        .tint(.white)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Hero
                pageView(for: pages[step])
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer()

                // Pagination dots — morph as step changes
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(pages.indices, id: \.self) { i in
                            Capsule()
                                .fill(.white)
                                .frame(width: i == step ? 28 : 8, height: 8)
                                .glassEffect(.regular.tint(.white.opacity(0.2)), in: .capsule)
                                .glassEffectID("dot-\(i)", in: ns)
                        }
                    }
                }
                .padding(.bottom, 24)

                // CTA
                Button {
                    withAnimation(.bouncy) {
                        if step < pages.count - 1 { step += 1 }
                    }
                } label: {
                    Text(step == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .tint(.white.opacity(0.3))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Image(systemName: page.symbol)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 160, height: 160)
                .glassEffect(.regular.tint(.white.opacity(0.1)), in: .circle)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))
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
            // Soft orbs so glass has texture to refract
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
