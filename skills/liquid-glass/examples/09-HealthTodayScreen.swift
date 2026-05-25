// HealthTodayScreen.swift
// iOS 26 Liquid Glass example — showcase screen for a health app.
//
// Everything visibly glass:
//  • Bottom glass TabView (the "menu bar" the user wanted to see)
//  • Glass nav bar with avatar + notifications badge
//  • Glass period switcher (Day / Week / Month / Year) that morphs
//  • Hero activity-ring panel with glass stat chips
//  • Horizontal metric chips (steps, heart, sleep, mindful) in a container
//  • Glass workout cards with floating join/duration chips
//  • Glass floating "+" FAB that expands into a morphing radial action menu
//  • Glass bottom accessory ("hydration" reminder strip) above the tab bar
//
// Requires: Xcode 26+, iOS 26+.

import SwiftUI

// MARK: - App shell with glass tab bar

struct HealthAppShell: View {
    @State private var query = ""

    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max.fill") {
                NavigationStack { HealthTodayScreen() }
            }
            Tab("Activity", systemImage: "figure.run") {
                NavigationStack { ActivityPlaceholder() }
            }
            Tab("Sleep", systemImage: "moon.zzz.fill") {
                NavigationStack { SleepPlaceholder() }
            }
            Tab("Browse", systemImage: "magnifyingglass", role: .search) {
                NavigationStack { BrowsePlaceholder() }
            }
        }
        .searchable(text: $query, prompt: "Search workouts, meals, articles")
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            HydrationStrip()
        }
        .tint(.green)
    }
}

// MARK: - Today screen

struct HealthTodayScreen: View {
    enum Period: String, CaseIterable, Identifiable {
        case day = "Day", week = "Week", month = "Month", year = "Year"
        var id: Self { self }
    }

    @State private var period: Period = .day
    @State private var fabExpanded = false
    @Namespace private var ns

    private let metrics: [Metric] = [
        .init(title: "Steps",   value: "8,432",  unit: "today",    symbol: "figure.walk",            tint: .green),
        .init(title: "Heart",   value: "62",     unit: "BPM",      symbol: "heart.fill",             tint: .red),
        .init(title: "Sleep",   value: "7h 12m", unit: "last",     symbol: "moon.fill",              tint: .indigo),
        .init(title: "Mindful", value: "12",     unit: "min",      symbol: "brain.head.profile",     tint: .teal),
        .init(title: "Water",   value: "1.2",    unit: "L",        symbol: "drop.fill",              tint: .blue),
        .init(title: "Energy",  value: "1,840",  unit: "kcal",     symbol: "flame.fill",             tint: .orange),
    ]

    private let workouts: [Workout] = [
        .init(title: "Morning HIIT",       duration: "22 min", participants: "14k", tint: .pink),
        .init(title: "Calm Yoga Flow",     duration: "30 min", participants: "9.2k", tint: .teal),
        .init(title: "Endurance Run",      duration: "45 min", participants: "6.7k", tint: .orange),
        .init(title: "Strength Builder",   duration: "35 min", participants: "11k",  tint: .purple),
    ]

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Greeting + period switcher
                    header

                    // Hero activity-ring panel
                    activityHero

                    // Metric chips row
                    metricsRow

                    // Workouts section
                    workoutsSection

                    // Today's plan card
                    planCard

                    Color.clear.frame(height: 100) // breathing room
                }
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Profile", systemImage: "person.crop.circle.fill") { }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Inbox", systemImage: "bell.fill") { }
                        .badge(3)
                        .tint(.red)
                }
                ToolbarSpacer(.fixed, spacing: 8)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share", systemImage: "square.and.arrow.up") { }
                }
            }

            // Floating glass FAB + radial action menu
            floatingActionMenu
        }
    }

    // MARK: Header (greeting + period segments)

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.75))
                Text("Parsa")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            }

            // Period switcher — glass segmented control with morphing selection
            GlassEffectContainer(spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(Period.allCases) { p in
                        Button {
                            withAnimation(.bouncy) { period = p }
                        } label: {
                            Text(p.rawValue)
                                .font(.footnote.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(p == period ? .glassProminent : .glass)
                        .tint(p == period ? .white.opacity(0.3) : .clear)
                        .foregroundStyle(.white)
                        .glassEffectID("period-\(p.rawValue)", in: ns)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: Hero activity rings panel

    private var activityHero: some View {
        ZStack {
            // The glass panel
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                )

            HStack(spacing: 20) {
                ActivityRings()
                    .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 10) {
                    statChip("Move",     value: "540 / 600",  tint: .red)
                    statChip("Exercise", value: "32 / 30",    tint: .green)
                    statChip("Stand",    value: "10 / 12",    tint: .cyan)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .padding(.horizontal)
    }

    private func statChip(_ title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(tint).frame(width: 8, height: 8)
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular.tint(tint.opacity(0.18)), in: .capsule)
    }

    // MARK: Metric chips row

    private var metricsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Metrics")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button("See all") { }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(metrics) { m in
                            MetricChip(metric: m)
                                .glassEffectID("metric-\(m.title)", in: ns)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: Workouts

    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured workouts")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button("Filter", systemImage: "line.3.horizontal.decrease") { }
                    .buttonStyle(.glass)
                    .tint(.white)
                    .foregroundStyle(.white)
                    .controlSize(.small)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(workouts) { w in
                        WorkoutCard(workout: w)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: Plan card

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                Text("Today's plan")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("3 / 5")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .glassEffect(.regular.tint(.yellow.opacity(0.25)), in: .capsule)
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                planRow(done: true,  title: "Morning stretch",    time: "07:00")
                planRow(done: true,  title: "Hydrate (250 ml)",   time: "09:00")
                planRow(done: true,  title: "20-min walk",        time: "10:30")
                planRow(done: false, title: "Strength session",   time: "17:00")
                planRow(done: false, title: "Wind-down breathing", time: "22:00")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.06))
        )
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .padding(.horizontal)
    }

    private func planRow(done: Bool, title: String, time: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? .green : .white.opacity(0.5))
            Text(title)
                .font(.callout)
                .strikethrough(done)
                .foregroundStyle(done ? .white.opacity(0.6) : .white)
            Spacer()
            Text(time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: Floating action menu

    private var floatingActionMenu: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                GlassEffectContainer(spacing: 16) {
                    VStack(spacing: 16) {
                        if fabExpanded {
                            fabAction("Log water",    systemImage: "drop.fill",         tint: .blue)
                                .glassEffectID("fab-water", in: ns)
                                .transition(.scale.combined(with: .opacity))
                            fabAction("Add meal",     systemImage: "fork.knife",        tint: .orange)
                                .glassEffectID("fab-meal", in: ns)
                                .transition(.scale.combined(with: .opacity))
                            fabAction("Log mood",     systemImage: "face.smiling",     tint: .yellow)
                                .glassEffectID("fab-mood", in: ns)
                                .transition(.scale.combined(with: .opacity))
                            fabAction("Workout",      systemImage: "figure.run",       tint: .pink)
                                .glassEffectID("fab-workout", in: ns)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Button {
                            withAnimation(.bouncy) { fabExpanded.toggle() }
                        } label: {
                            Image(systemName: fabExpanded ? "xmark" : "plus")
                                .font(.title.weight(.semibold))
                                .frame(width: 60, height: 60)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                        .tint(.green)
                        .foregroundStyle(.white)
                        .glassEffectID("fab-toggle", in: ns)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func fabAction(_ title: String, systemImage: String, tint: Color) -> some View {
        Button { } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.callout.weight(.medium))
                Image(systemName: systemImage)
                    .frame(width: 24, height: 24)
            }
            .padding(.leading, 14)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
        }
        .buttonStyle(.glass)
        .tint(tint)
    }

    // MARK: Backdrop

    private var backdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.18, blue: 0.20),
                    Color(red: 0.10, green: 0.32, blue: 0.30),
                    Color(red: 0.18, green: 0.48, blue: 0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Color orbs — give glass texture to lens
            Circle().fill(.green).frame(width: 320, height: 320).blur(radius: 90)
                .offset(x: -130, y: -260)
            Circle().fill(.teal).frame(width: 360, height: 360).blur(radius: 110)
                .offset(x: 150, y: -50)
            Circle().fill(.mint.opacity(0.7)).frame(width: 280, height: 280).blur(radius: 80)
                .offset(x: -100, y: 240)
            Circle().fill(.cyan.opacity(0.6)).frame(width: 240, height: 240).blur(radius: 70)
                .offset(x: 170, y: 360)
        }
    }
}

// MARK: - Metric chip

private struct Metric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let symbol: String
    let tint: Color
}

private struct MetricChip: View {
    let metric: Metric

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: metric.symbol)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(metric.tint)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text(metric.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(metric.value)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(metric.unit)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(14)
        .frame(width: 140, height: 120, alignment: .topLeading)
        .glassEffect(.regular.tint(metric.tint.opacity(0.18)), in: .rect(cornerRadius: 20))
    }
}

// MARK: - Workout card

private struct Workout: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let participants: String
    let tint: Color
}

private struct WorkoutCard: View {
    let workout: Workout

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [workout.tint, workout.tint.opacity(0.4), .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 220, height: 280)

            // Top-right glass duration chip
            VStack {
                HStack {
                    Spacer()
                    Text(workout.duration)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .glassEffect(.regular.tint(.white.opacity(0.2)), in: .capsule)
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(12)

            // Bottom info
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Label(workout.participants, systemImage: "person.2.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .glassEffect(.regular.tint(.white.opacity(0.15)), in: .capsule)
                        .foregroundStyle(.white)

                    Spacer()

                    Button {} label: {
                        Image(systemName: "play.fill")
                            .font(.callout.weight(.bold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .tint(.white.opacity(0.3))
                    .foregroundStyle(.white)
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Activity rings (visual stand-in)

private struct ActivityRings: View {
    var body: some View {
        ZStack {
            ring(progress: 0.90, color: .red,   width: 12, inset: 0)
            ring(progress: 1.07, color: .green, width: 12, inset: 18)
            ring(progress: 0.83, color: .cyan,  width: 12, inset: 36)
        }
    }

    private func ring(progress: Double, color: Color, width: CGFloat, inset: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.25), lineWidth: width)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.6), radius: 6)
        }
        .padding(inset)
    }
}

// MARK: - Hydration strip (bottom accessory above tab bar)

private struct HydrationStrip: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .padding(8)
                .background(.blue.opacity(0.2), in: .circle)

            if placement == .expanded {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time to hydrate")
                        .font(.callout.weight(.semibold))
                    Text("1.2 L of 2.5 L today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Hydrate")
                    .font(.callout.weight(.semibold))
            }

            Spacer()

            Button {} label: {
                Text("+250 ml")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent)
            .tint(.blue)
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - Placeholder tabs

private struct ActivityPlaceholder: View {
    var body: some View {
        ContentUnavailableView("Activity", systemImage: "figure.run",
                               description: Text("Your runs, rides, and walks appear here."))
            .navigationTitle("Activity")
    }
}

private struct SleepPlaceholder: View {
    var body: some View {
        ContentUnavailableView("Sleep", systemImage: "moon.zzz.fill",
                               description: Text("Track your sleep stages and recovery."))
            .navigationTitle("Sleep")
    }
}

private struct BrowsePlaceholder: View {
    var body: some View {
        ContentUnavailableView("Browse", systemImage: "magnifyingglass",
                               description: Text("Find workouts, meditations, and articles."))
            .navigationTitle("Browse")
    }
}

// MARK: - Preview

#Preview("Full app shell") {
    HealthAppShell()
}

#Preview("Today screen only") {
    NavigationStack { HealthTodayScreen() }
}
