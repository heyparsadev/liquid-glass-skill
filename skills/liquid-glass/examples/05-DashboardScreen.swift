// DashboardScreen.swift
// Liquid Glass example: a health dashboard.
//
// Functional layer (glass, all system-provided): the navigation bar and a
// bottom toolbar that holds the quick-log actions and the minimized search
// button. DefaultToolbarItem sits directly in the toolbar builder.
// Content layer (no glass): the greeting, the widget cards (solid surfaces),
// and the workout cards (gradients with standard-material chips).
//
// Requires: Xcode 26 or later, iOS 26 or later.

import SwiftUI

struct DashboardScreen: View {
    @State private var query = ""

    private let widgets: [Widget] = [
        .init(title: "Steps", value: "8,432", caption: "Today", symbol: "figure.walk", tint: .green),
        .init(title: "Sleep", value: "7h 12m", caption: "Last night", symbol: "moon.fill", tint: .indigo),
        .init(title: "Heart", value: "62 BPM", caption: "Resting", symbol: "heart.fill", tint: .red),
        .init(title: "Mindful", value: "12m", caption: "Today", symbol: "brain.head.profile", tint: .teal)
    ]

    private let workouts = ["20 min cardio", "Yoga flow", "HIIT", "Strength", "Recovery"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Good morning")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Alex")
                            .font(.largeTitle.bold())
                    }
                    .padding(.horizontal)

                    // Widget grid: content cards on solid surfaces
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
                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(workouts.indices, id: \.self) { i in
                                    workoutCard(i: i)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .scrollIndicators(.hidden)
                    }
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

                // Quick actions live in the system bottom toolbar, not a custom glass bar.
                // They're untinted, because tint is for meaning, not decoration.
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Log Water", systemImage: "drop.fill") { }
                    Button("Add Meal", systemImage: "fork.knife") { }
                    Button("Log Mood", systemImage: "face.smiling") { }
                }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            }
        }
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

            VStack(alignment: .leading, spacing: 6) {
                Text(workouts[i])
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("12k joined")                     // a content chip: material, not glass
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: .capsule)
                    .environment(\.colorScheme, .dark)
            }
            .padding(14)
        }
        .accessibilityElement(children: .combine)
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
                    .foregroundStyle(widget.tint)        // color identifies the metric in the content layer
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
        .background(.background, in: .rect(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DashboardScreen()
}
