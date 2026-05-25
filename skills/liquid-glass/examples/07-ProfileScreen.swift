// ProfileScreen.swift
// iOS 26 Liquid Glass example — hero header with cover photo, glass avatar ring,
// glass tab switcher that morphs between Posts / Media / Likes.

import SwiftUI

struct ProfileScreen: View {
    @State private var tab: ProfileTab = .posts
    @Namespace private var ns

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header

                    // Glass tab switcher
                    GlassEffectContainer(spacing: 4) {
                        HStack(spacing: 4) {
                            ForEach(ProfileTab.allCases) { t in
                                Button {
                                    withAnimation(.bouncy) { tab = t }
                                } label: {
                                    Text(t.title)
                                        .font(.callout.weight(.medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(t == tab ? .glassProminent : .glass)
                                .tint(t == tab ? .accentColor : .clear)
                                .foregroundStyle(t == tab ? .white : .primary)
                                .glassEffectID("tab-\(t.rawValue)", in: ns)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Content per tab
                    Group {
                        switch tab {
                        case .posts:  posts
                        case .media:  media
                        case .likes:  likes
                        }
                    }
                    .padding(.top, 16)
                    .transition(.opacity)
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share", systemImage: "square.and.arrow.up") { }
                }
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            // Cover
            LinearGradient(
                colors: [.purple, .pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 240)
            .overlay {
                ForEach(0..<6, id: \.self) { i in
                    Circle().fill(.white.opacity(0.15)).blur(radius: 40)
                        .frame(width: 200, height: 200)
                        .offset(x: CGFloat(i * 60) - 200, y: CGFloat(i * 30) - 100)
                }
            }

            // Identity row
            HStack(alignment: .bottom, spacing: 16) {
                avatar
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lyra Calder")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("@lyracalder")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Button("Follow") { }
                    .buttonStyle(.glassProminent)
                    .tint(.white.opacity(0.25))
                    .foregroundStyle(.white)
                    .controlSize(.regular)
            }
            .padding()
        }
    }

    private var avatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 40))
            .foregroundStyle(.white)
            .frame(width: 88, height: 88)
            .background(.indigo, in: Circle())
            .padding(4)
            .glassEffect(.regular, in: .circle)
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
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
        VStack {
            ContentUnavailableView("No likes yet", systemImage: "heart")
                .padding(.top, 40)
        }
    }
}

private enum ProfileTab: String, CaseIterable, Identifiable {
    case posts, media, likes
    var id: Self { self }
    var title: String { rawValue.capitalized }
}

#Preview {
    ProfileScreen()
}
