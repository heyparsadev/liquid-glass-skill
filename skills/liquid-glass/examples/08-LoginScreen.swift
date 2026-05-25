// LoginScreen.swift
// iOS 26 Liquid Glass example — a showcase login screen.
//
// Demonstrates:
//  • Vivid mesh-gradient backdrop (so glass actually lenses something)
//  • Glass nav bar with title + close button (visible chrome)
//  • Glass segmented switcher (Sign In / Sign Up) morphing between states
//  • Glass text fields with leading icons + show/hide toggle
//  • Glass "Forgot password?" pill and Remember-me toggle
//  • .glassProminent primary CTA with full-width capsule
//  • Container-grouped glass social buttons (Apple / Google / Email) that
//    blend together
//  • Floating glass help bar pinned at the bottom via safeAreaInset
//
// Requires: Xcode 26+, iOS 26+.

import SwiftUI

struct LoginScreen: View {
    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
        var id: Self { self }
    }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var showPassword = false
    @State private var rememberMe = true
    @State private var showHelp = false

    @FocusState private var focused: Field?
    @Namespace private var ns

    enum Field { case email, password, confirm }

    var body: some View {
        ZStack {
            // ── Content layer: vivid backdrop (gives glass things to refract)
            backdrop.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Glass nav bar (visible chrome)
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 24) {
                        hero
                            .padding(.top, 24)

                        // Mode switcher — morphs between Sign In / Sign Up
                        segmentedSwitcher
                            .padding(.horizontal, 24)

                        // Form
                        VStack(spacing: 14) {
                            field(
                                "envelope.fill",
                                placeholder: "Email",
                                text: $email,
                                focus: .email,
                                keyboard: .emailAddress,
                                content: .username
                            )

                            secureField(
                                "lock.fill",
                                placeholder: "Password",
                                text: $password,
                                focus: .password
                            )

                            if mode == .signUp {
                                secureField(
                                    "lock.shield.fill",
                                    placeholder: "Confirm password",
                                    text: $confirm,
                                    focus: .confirm
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 24)

                        // Helper row — Remember me + Forgot password
                        if mode == .signIn {
                            helperRow
                                .padding(.horizontal, 24)
                                .transition(.opacity)
                        }

                        // Primary CTA
                        primaryButton
                            .padding(.horizontal, 24)
                            .padding(.top, 4)

                        // Divider with label
                        dividerLabel
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        // Social cluster
                        socialCluster
                            .padding(.horizontal, 24)

                        // Footer
                        footer
                            .padding(.top, 4)
                            .padding(.bottom, 80) // breathing room for floating help bar
                    }
                }
                .scrollIndicators(.hidden)
            }

            // Help bar floats over everything
            VStack {
                Spacer()
                if showHelp {
                    helpBar
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.bouncy, value: mode)
        .animation(.bouncy, value: showHelp)
    }

    // MARK: - Top bar (glass nav)

    private var topBar: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    // dismiss
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.white)
                .glassEffectID("back", in: ns)

                Spacer()

                Text("Welcome")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: .capsule)
                    .glassEffectID("title", in: ns)

                Spacer()

                Button {
                    withAnimation(.bouncy) { showHelp.toggle() }
                } label: {
                    Image(systemName: showHelp ? "xmark" : "questionmark")
                        .font(.body.weight(.semibold))
                        .frame(width: 40, height: 40)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.white)
                .glassEffectID("help", in: ns)
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 96, height: 96)
                .glassEffect(.regular.tint(.white.opacity(0.15)), in: .circle)

            VStack(spacing: 6) {
                Text(mode == .signIn ? "Welcome back" : "Create your account")
                    .font(.largeTitle.bold())
                    .contentTransition(.opacity)
                Text(mode == .signIn
                     ? "Sign in to pick up where you left off."
                     : "Join in under a minute. No spam, ever.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .contentTransition(.opacity)
            }
            .foregroundStyle(.white)
        }
    }

    // MARK: - Segmented switcher

    private var segmentedSwitcher: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(Mode.allCases) { m in
                    Button {
                        withAnimation(.bouncy) { mode = m }
                    } label: {
                        Text(m.rawValue)
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(m == mode ? .glassProminent : .glass)
                    .tint(m == mode ? .white.opacity(0.28) : .clear)
                    .foregroundStyle(.white)
                    .glassEffectID("seg-\(m.rawValue)", in: ns)
                }
            }
        }
    }

    // MARK: - Fields

    private func field(
        _ symbol: String,
        placeholder: String,
        text: Binding<String>,
        focus: Field,
        keyboard: UIKeyboardType = .default,
        content: UITextContentType? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 22)
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.55)))
                .focused($focused, equals: focus)
                .keyboardType(keyboard)
                .textContentType(content)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(focused == focus ? .white.opacity(0.6) : .clear, lineWidth: 1)
        )
    }

    private func secureField(
        _ symbol: String,
        placeholder: String,
        text: Binding<String>,
        focus: Field
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 22)
            Group {
                if showPassword {
                    TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.55)))
                } else {
                    SecureField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.55)))
                }
            }
            .focused($focused, equals: focus)
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .foregroundStyle(.white)

            Button {
                withAnimation(.snappy) { showPassword.toggle() }
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.white.opacity(0.7))
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(focused == focus ? .white.opacity(0.6) : .clear, lineWidth: 1)
        )
    }

    // MARK: - Helper row

    private var helperRow: some View {
        HStack {
            Toggle(isOn: $rememberMe) {
                Text("Remember me")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .toggleStyle(.switch)
            .tint(.white)
            .labelsHidden()

            Text("Remember me")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Button { } label: {
                Text("Forgot password?")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glass)
            .tint(.white)
            .foregroundStyle(.white)
        }
    }

    // MARK: - Primary CTA

    private var primaryButton: some View {
        Button {
            // submit
        } label: {
            HStack(spacing: 8) {
                Text(mode == .signIn ? "Sign In" : "Create Account")
                    .font(.body.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.black)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.extraLarge)
        .tint(.white)
    }

    // MARK: - Divider

    private var dividerLabel: some View {
        HStack(spacing: 12) {
            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
            Text("or continue with")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
        }
    }

    // MARK: - Social cluster

    private var socialCluster: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                socialButton("apple.logo", label: "Apple")
                socialButton("g.circle.fill", label: "Google")
                socialButton("envelope.fill", label: "Email")
            }
        }
    }

    private func socialButton(_ symbol: String, label: String) -> some View {
        Button { } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.title3)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 4) {
            Text(mode == .signIn ? "New here?" : "Already have an account?")
                .foregroundStyle(.white.opacity(0.7))
            Button(mode == .signIn ? "Create one" : "Sign in") {
                withAnimation(.bouncy) {
                    mode = (mode == .signIn) ? .signUp : .signIn
                }
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
        }
        .font(.callout)
    }

    // MARK: - Help bar (floating)

    private var helpBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                helpAction("Contact support", systemImage: "bubble.left.and.bubble.right.fill")
                helpAction("Privacy", systemImage: "hand.raised.fill")
                helpAction("Terms", systemImage: "doc.text.fill")
            }
        }
    }

    private func helpAction(_ title: String, systemImage: String) -> some View {
        Button { } label: {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.glass)
        .tint(.white)
        .foregroundStyle(.white)
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.05, blue: 0.45),
                    Color(red: 0.55, green: 0.10, blue: 0.55),
                    Color(red: 0.95, green: 0.35, blue: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft color orbs so glass has varied content to refract
            Circle().fill(.cyan).frame(width: 320, height: 320).blur(radius: 80)
                .offset(x: -130, y: -260)
            Circle().fill(.pink).frame(width: 360, height: 360).blur(radius: 100)
                .offset(x: 140, y: 80)
            Circle().fill(.orange).frame(width: 280, height: 280).blur(radius: 90)
                .offset(x: -80, y: 320)
            Circle().fill(.purple.opacity(0.7)).frame(width: 240, height: 240).blur(radius: 70)
                .offset(x: 160, y: -120)
        }
    }
}

#Preview {
    LoginScreen()
}
