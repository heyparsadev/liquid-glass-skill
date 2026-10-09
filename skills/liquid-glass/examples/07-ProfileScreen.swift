// ProfileScreen.swift
// Liquid Glass example: a profile with a cover image under the glass
// navigation bar, a Follow button over the cover, a content switcher, and a
// settings sheet that zooms out of its toolbar button.
//
// Functional layer (glass): the navigation bar and its items (system), the
// prominent Follow button floating over the cover image (the one primary
// action), and the sheet (system).
// Content layer (no glass): the cover, the avatar (ringed with a standard
// material), the posts, and the media grid.
//
// The Posts/Media/Likes switcher is a system Picker. It uses .segmented on
// iOS 26 and .tabs on iOS 27, which looks the same on iOS but makes VoiceOver
// announce the options as tabs.
//
// Requires: Xcode 27 to build (PickerStyle.tabs is gated with #available).
// Runs on iOS 26 or later.

import SwiftUI

struct ProfileScreen: View {
    @State private var tab: ProfileTab = .posts
    @State private var showSettings = false
    @Namespace private var ns

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header

                    Picker("Section", selection: $tab) {
                        ForEach(ProfileTab.allCases) { t in
                            Text(t.title).tag(t)
                        }
                    }
                    .contentTabsPickerStyle()
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Group {
                        switch tab {
                        case .posts:  posts
                        case .media:  media
                        case .likes:  likes
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
            .animation(.smooth, value: tab)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
                .matchedTransitionSource(id: "settings", in: ns)   // ToolbarContent version (iOS 26)

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share", systemImage: "square.and.arrow.up") { }
                }
            }
            .sheet(isPresented: $showSettings) {
                ProfileSettingsSheet()
                    .presentationDetents([.medium, .large])
                    .navigationTransition(.zoom(sourceID: "settings", in: ns))
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            // Cover: content that scrolls under the glass navigation bar
            LinearGradient(
                colors: [.purple, .pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 260)
            .overlay {
                ForEach(0..<6, id: \.self) { i in
                    Circle().fill(.white.opacity(0.15)).blur(radius: 40)
                        .frame(width: 200, height: 200)
                        .offset(x: CGFloat(i * 60) - 200, y: CGFloat(i * 30) - 100)
                }
            }
            .accessibilityHidden(true)

            // Identity row
            HStack(alignment: .bottom, spacing: 16) {
                avatar
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lyra Calder")
                        .font(.title2.bold())
                    Text("@lyracalder")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .foregroundStyle(.white)
                Spacer()
                Button("Follow") { }
                    .buttonStyle(.glassProminent)     // the one primary action; accent-colored background
            }
            .padding()
        }
    }

    private var avatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 40))
            .foregroundStyle(.white)
            .frame(width: 88, height: 88)
            .background(.indigo, in: .circle)
            .padding(4)
            .background(.ultraThinMaterial, in: .circle)   // content: a material ring, not glass
            .accessibilityLabel("Profile photo")
    }

    private var posts: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                postCard
            }
        }
        .padding(.horizontal)
    }

    private var postCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Just dropped a new mix. Spent the morning chasing the right snare snap and I think we got it.")
                .font(.callout)
            HStack(spacing: 16) {
                Label("128", systemImage: "heart")
                Label("24", systemImage: "bubble.right")
                Spacer()
                Label("3h", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: .rect(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var media: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
            ForEach(0..<12, id: \.self) { i in
                LinearGradient(
                    colors: [
                        Color(hue: Double(i) / 12.0, saturation: 0.7, brightness: 0.9),
                        Color(hue: Double(i) / 12.0, saturation: 0.5, brightness: 0.6)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .aspectRatio(1, contentMode: .fill)
            }
        }
    }

    private var likes: some View {
        ContentUnavailableView("No likes yet", systemImage: "heart")
            .padding(.top, 40)
    }
}

private struct ProfileSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var privateAccount = false
    @State private var showActivity = true

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Private Account", isOn: $privateAccount)
                Toggle("Show Activity Status", isOn: $showActivity)
            }
            .navigationTitle("Profile Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }    // the standard ✕ (iOS 26)
                }
            }
        }
    }
}

private enum ProfileTab: String, CaseIterable, Identifiable {
    case posts, media, likes
    var id: Self { self }
    var title: String { rawValue.capitalized }
}

private extension View {
    /// `.tabs` on iOS 27 (VoiceOver announces "tab"), `.segmented` earlier.
    @ViewBuilder
    func contentTabsPickerStyle() -> some View {
        if #available(iOS 27.0, *) {
            pickerStyle(.tabs)
        } else {
            pickerStyle(.segmented)
        }
    }
}

#Preview {
    ProfileScreen()
}
