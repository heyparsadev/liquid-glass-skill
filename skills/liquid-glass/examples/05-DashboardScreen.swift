// DashboardScreen.swift
// iOS 26 Liquid Glass example — grid of solid widget cards with glass chips,
// a glass quick-action bar pinned via safeAreaInset, and a sticky glass header.

import SwiftUI

struct DashboardScreen: View {
    @State private var query = ""

    private let widgets: [Widget] = [
        .init(title: "Steps", value: "8,432", caption: "Today", symbol: "figure.walk", tint: .green),
        .init(title: "Sleep", value: "7h 12m", caption: "Last night", symbol: "moon.fill", tint: .indigo),
        .init(title: "Heart", value: "62 BPM", caption: "Resting", symbol: "heart.fill", tint: .red),
        .init(title: "Mindful", value: "12m", caption: "Today", symbol: "brain.head.profile", tint: .teal)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Greeting hero
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Good morning")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Parsa")
                            .font(.largeTitle.bold())
                    }
                    .padding(.horizontal)

                    // Widget grid
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 16
                    ) {
                        ForEach(widgets) { widget in
                            WidgetCard(widget: widget)
                        }
                    }
                    .padding(.horizontal)

                    // Featured workouts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured workouts")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<5, id: \.self) { i in
                                    workoutCard(i: i)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Color.clear.frame(height: 80) // breathing room for floating bar
                }
                .padding(.vertical)
            }
            .navigationTitle("Health")
            .searchable(text: $query, prompt: "Search records")
            .searchToolbarBehavior(.minimize)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Profile", systemImage: "person.crop.circle") { }
                }
            }
            .safeAreaInset(edge: .bottom) {
                quickActionBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }

    // Pinned floating glass bar — quick log actions
    private var quickActionBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                quickAction("Log water", systemImage: "drop.fill", tint: .blue)
                quickAction("Add meal", systemImage: "fork.knife", tint: .orange)
                quickAction("Log mood", systemImage: "face.smiling", tint: .yellow)
            }
        }
    }

    private func quickAction(_ title: String, systemImage: String, tint: Color) -> some View {
        Button { } label: {
            Label(title, systemImage: systemImage)
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.glass)
        .tint(tint)
    }

    private func workoutCard(i: Int) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hue: Double(i) / 5.0, saturation: 0.6, brightness: 0.9), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 220, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(["20 min cardio", "Yoga flow", "HIIT", "Strength", "Recovery"][i])
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("12k joined")
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .glassEffect(.regular.tint(.white.opacity(0.2)), in: .capsule)
                    .foregroundStyle(.white)
            }
            .padding(14)
        }
    }
}

private struct Widget: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let caption: String
    let symbol: String
    let tint: Color
}

private struct WidgetCard: View {
    let widget: Widget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: widget.symbol)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(widget.tint)
                Text(widget.title)
                    .font(.callout.weight(.medium))
                Spacer()
            }

            Text(widget.value)
                .font(.title.bold())
                .contentTransition(.numericText())

            Text(widget.caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

#Preview {
    DashboardScreen()
}
