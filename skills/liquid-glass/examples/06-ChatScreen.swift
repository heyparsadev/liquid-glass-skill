// ChatScreen.swift
// Liquid Glass example: a message thread with a floating glass composer.
// While the field is focused, the camera and mic buttons merge into the + button.
//
// Functional layer (glass): the navigation bar (system), and the composer: one
// GlassEffectContainer holding the + button, the camera and mic buttons, and
// the text field. The field's shape is a rounded rectangle so multi-line input
// stays legible.
// Content layer (no glass): the message bubbles.
//
// The composer is pinned with safeAreaInset, not safeAreaBar. The iOS 26.1
// release notes list a known issue (158720838): @FocusState doesn't work
// inside safeAreaBar.
//
// Requires: Xcode 26 or later, iOS 26 or later.

import SwiftUI

struct ChatScreen: View {
    @State private var draft = ""
    @FocusState private var inputFocused: Bool
    @Namespace private var ns
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var messages: [Message] = .sample

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { msg in
                            MessageRow(message: msg).id(msg.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .navigationTitle("Lyra Calder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Call", systemImage: "phone.fill") { }
                    Button("Video", systemImage: "video.fill") { }
                }
            }
            .safeAreaInset(edge: .bottom) {
                inputBar
                    .padding(.horizontal)
                    .padding(.bottom, 6)
            }
        }
    }

    private var inputBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(alignment: .bottom, spacing: 10) {
                Button {
                    inputFocused = false
                } label: {
                    Image(systemName: inputFocused ? "chevron.right" : "plus")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.title3.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.primary)
                .accessibilityLabel(inputFocused ? "Show Attachments" : "Attachments")
                .glassEffectID("plus", in: ns)

                if !inputFocused {
                    // No opacity transitions: these grow out of and merge back into "plus".
                    quickButton("camera.fill", label: "Camera")
                        .glassEffectID("camera", in: ns)
                    quickButton("mic.fill", label: "Voice Message")
                        .glassEffectID("mic", in: ns)
                }

                HStack(alignment: .bottom) {
                    TextField("Message", text: $draft, axis: .vertical)
                        .lineLimit(1...5)
                        .focused($inputFocused)
                        .padding(.vertical, 4)
                    if !draft.isEmpty {
                        Button {
                            send()
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(.blue, in: .circle)   // a fill on the glass, not more glass
                        }
                        .accessibilityLabel("Send")
                        .transition(.scale.combined(with: .opacity))   // fine here: the fill isn't glass
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
                .glassEffectID("field", in: ns)
            }
        }
        .animation(reduceMotion ? .smooth : .bouncy, value: inputFocused)
        .animation(.snappy, value: draft.isEmpty)
    }

    private func quickButton(_ symbol: String, label: String) -> some View {
        Button { } label: {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(.primary)
        .accessibilityLabel(label)
    }

    private func send() {
        guard !draft.isEmpty else { return }
        let text = draft
        withAnimation {
            messages.append(.init(text: text, fromMe: true))
            draft = ""
        }
    }
}

private struct Message: Identifiable {
    let id = UUID()
    let text: String
    let fromMe: Bool
}

private extension Array where Element == Message {
    static var sample: [Message] {
        [
            .init(text: "Hey! Did you get the new album?", fromMe: false),
            .init(text: "Just downloaded it. The third track is wild.", fromMe: true),
            .init(text: "Right?? Let me know when you finish it.", fromMe: false),
            .init(text: "Will do — listening tonight.", fromMe: true),
        ]
    }
}

private struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack {
            if message.fromMe { Spacer(minLength: 60) }
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.fromMe ? AnyShapeStyle(Color.blue) : AnyShapeStyle(Color(.systemGray5))
                )
                .foregroundStyle(message.fromMe ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            if !message.fromMe { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    ChatScreen()
}
