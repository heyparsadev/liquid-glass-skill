// LoginScreen.swift
// Liquid Glass example: a sign-in screen over a vivid backdrop.
//
// Functional layer (glass):
//  • The navigation bar with Close and Help items: a real NavigationStack, not
//    a hand-built glass HStack.
//  • The Sign In / Sign Up switcher. It's a custom glass control: the selected
//    segment is prominent, and the segments blend inside one container.
//    `.glass` and `.glassProminent` are different concrete types, so each
//    segment branches on the whole button rather than a ternary. For a
//    standard look, a Picker with .segmented (or .tabs on iOS 27) is simpler.
//  • The primary CTA (.glassProminent): the one primary action.
//  • The Google / Email buttons and the floating help bar, each cluster in
//    one GlassEffectContainer.
// Content layer (no glass): the backdrop, the hero, and the form fields
// (standard material).
// Sign in with Apple uses Apple's SignInWithAppleButton. The HIG doesn't allow
// a custom Apple-logo button, and the button's background must be black or white.
//
// Requires: Xcode 26 or later, iOS 26 or later.

import SwiftUI
import AuthenticationServices

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Field { case email, password, confirm }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                        .padding(.top, 8)

                    segmentedSwitcher
                        .padding(.horizontal, 24)

                    // Form: content layer, so the fields use a standard material
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
                            .transition(confirmFieldTransition)
                        }
                    }
                    .padding(.horizontal, 24)

                    if mode == .signIn {
                        helperRow
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    primaryButton
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                    dividerLabel
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    socialOptions
                        .padding(.horizontal, 24)

                    footer
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
            .background {
                backdrop.ignoresSafeArea()               // content scrolls under the glass bar
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { }                // standard ✕ (iOS 26)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Help", systemImage: showHelp ? "xmark" : "questionmark") {
                        withAnimation(switchAnimation) { showHelp.toggle() }
                    }
                }
            }
            .safeAreaBar(edge: .bottom) {                   // a custom bar that joins the scroll edge effect
                if showHelp {
                    helpBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(switchAnimation, value: mode)
    }

    private var switchAnimation: Animation {
        reduceMotion ? .smooth : .bouncy
    }

    // The field isn't glass, so an ordinary transition is fine. Under Reduce
    // Motion it fades instead of sliding.
    private var confirmFieldTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }

    // MARK: - Hero (content)

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 96, height: 96)
                .background(.ultraThinMaterial, in: .circle)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(mode == .signIn ? "Welcome back" : "Create your account")
                    .font(.largeTitle.bold())
                    .contentTransition(.opacity)
                Text(mode == .signIn
                     ? "Sign in to pick up where you left off."
                     : "Join in under a minute. No spam, ever.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .contentTransition(.opacity)
            }
            .foregroundStyle(.white)
        }
    }

    // MARK: - Segmented switcher (custom glass control)

    private var segmentedSwitcher: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(Mode.allCases) { m in
                    segment(m)
                }
            }
        }
    }

    // The two button styles are different concrete types, so a ternary
    // can't choose between them. Branch on the whole button instead.
    @ViewBuilder
    private func segment(_ m: Mode) -> some View {
        if m == mode {
            segmentButton(m)
                .buttonStyle(.glassProminent)
                .accessibilityAddTraits(.isSelected)
                .glassEffectID("seg-\(m.rawValue)", in: ns)
        } else {
            segmentButton(m)
                .buttonStyle(.glass)
                .tint(.primary)
                .glassEffectID("seg-\(m.rawValue)", in: ns)
        }
    }

    private func segmentButton(_ m: Mode) -> some View {
        Button {
            withAnimation(switchAnimation) { mode = m }
        } label: {
            Text(m.rawValue)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Fields (content layer: standard material)

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
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 22)
                .accessibilityHidden(true)
            TextField(placeholder, text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.6)))
                .focused($focused, equals: focus)
                .keyboardType(keyboard)
                .textContentType(content)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(focused == focus ? .white.opacity(0.6) : .clear, lineWidth: 1)
        }
    }

    private func secureField(
        _ symbol: String,
        placeholder: String,
        text: Binding<String>,
        focus: Field
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 22)
                .accessibilityHidden(true)
            Group {
                if showPassword {
                    TextField(placeholder, text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.6)))
                } else {
                    SecureField(placeholder, text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.6)))
                }
            }
            .focused($focused, equals: focus)
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .foregroundStyle(.white)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.vertical, 2)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(focused == focus ? .white.opacity(0.6) : .clear, lineWidth: 1)
        }
    }

    // MARK: - Helper row

    private var helperRow: some View {
        HStack {
            Toggle("Remember me", isOn: $rememberMe)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.green)

            Text("Remember me")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityHidden(true)               // the toggle already carries this label

            Spacer()

            Button("Forgot password?") { }               // a link in the form, not floating chrome
                .buttonStyle(.borderless)
                .font(.footnote.weight(.semibold))
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
                Image(systemName: "arrow.right")
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)                   // accent-colored background by default
        .controlSize(.large)
    }

    // MARK: - Divider

    private var dividerLabel: some View {
        HStack(spacing: 12) {
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
            Text("or continue with")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
        }
    }

    // MARK: - Other sign-in options

    private var socialOptions: some View {
        VStack(spacing: 10) {
            SignInWithAppleButton(mode == .signIn ? .signIn : .signUp) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { _ in
                // handle the authorization result
            }
            .signInWithAppleButtonStyle(.white)          // black or white only; never glass
            .frame(height: 50)
            .clipShape(.capsule)

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    socialButton("g.circle.fill", label: "Google")
                    socialButton("envelope.fill", label: "Email Link")
                }
            }
        }
    }

    private func socialButton(_ symbol: String, label: String) -> some View {
        Button { } label: {
            Label(label, systemImage: symbol)
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 34)
        }
        .buttonStyle(.glass)
        .tint(.primary)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 4) {
            Text(mode == .signIn ? "New here?" : "Already have an account?")
                .foregroundStyle(.white.opacity(0.75))
            Button(mode == .signIn ? "Create one" : "Sign in") {
                withAnimation(switchAnimation) {
                    mode = (mode == .signIn) ? .signUp : .signIn
                }
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
        }
        .font(.callout)
    }

    // MARK: - Help bar (floating functional layer)

    private var helpBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                helpAction("Support", systemImage: "bubble.left.and.bubble.right.fill")
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
                .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
        .tint(.primary)
    }

    // MARK: - Backdrop (content layer)

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

            // Soft color orbs give the glass varied content to refract
            Circle().fill(.cyan).frame(width: 320, height: 320).blur(radius: 80)
                .offset(x: -130, y: -260)
            Circle().fill(.pink).frame(width: 360, height: 360).blur(radius: 100)
                .offset(x: 140, y: 80)
            Circle().fill(.orange).frame(width: 280, height: 280).blur(radius: 90)
                .offset(x: -80, y: 320)
            Circle().fill(.purple.opacity(0.7)).frame(width: 240, height: 240).blur(radius: 70)
                .offset(x: 160, y: -120)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    LoginScreen()
}
