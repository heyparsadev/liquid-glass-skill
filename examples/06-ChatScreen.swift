// ChatScreen.swift
// iOS 26 Liquid Glass example — message thread with a floating glass input bar
// that morphs to reveal media/quick-reply buttons when focused.

import SwiftUI

struct ChatScreen: View {
    @State private var draft = ""
    @FocusState private var inputFocused: Bool
    @Namespace private var ns

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Call", systemImage: "phone.fill") { }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
            HStack(spacing: 10) {
                Button {
                    inputFocused = false
                } label: {
                    Image(systemName: inputFocused ? "chevron.right" : "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 40, height: 40)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.primary)
                .glassEffectID("plus", in: ns)

                if !inputFocused {
                    quickButton("camera.fill")
                        .glassEffectID("camera", in: ns)
                        .transition(.scale.combined(with: .opacity))
                    quickButton("mic.fill")
                        .glassEffectID("mic", in: ns)
                        .transition(.scale.combined(with: .opacity))
                }

                HStack {
                    TextField("Message", text: $draft, axis: .vertical)
                        .lineLimit(1...5)
                        .focused($inputFocused)
                    if !draft.isEmpty {
                        Button {
                            send()
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(.blue, in: .circle)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .capsule)
                .glassEffectID("field", in: ns)
            }
        }
        .animation(.bouncy, value: inputFocused)
        .animation(.snappy, value: draft.isEmpty)
    }

    private func quickButton(_ symbol: String) -> some View {
        Button { } label: {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(.primary)
    }

    private func send() {
        guard !draft.isEmpty else { return }
        let text = draft
        withAnimation(.bouncy) {
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
