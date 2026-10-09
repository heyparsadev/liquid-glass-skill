// HealthTodayScreen.swift
// Liquid Glass example: a full app shell for a health app.
//
// Functional layer (glass):
//  • The tab bar, with a search tab, minimizing on scroll (system)
//  • The bottom accessory: a hydration strip, with plain controls inside because
//    the accessory is already glass
//  • The navigation bar with Profile, Inbox (badge) and Share (system). On
//    iOS 27 it minimizes on scroll together with the tab bar (gated with #available).
//  • The floating action button, which expands into a menu. Everything morphs
//    inside one GlassEffectContainer.
//  • One play button per workout card: a control floating over the card's media.
// Content layer (no glass): the backdrop, the greeting, the period picker
// (system), the activity, metric and plan cards (standard material), and the
// chips and badges (tinted fills).
//
// Requires: Xcode 27 to build (the iOS 27 API is gated with #available).
// Runs on iOS 26 or later.

import SwiftUI

// MARK: - App shell with the glass tab bar

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
        .tint(.green)                      // the app's accent: selected tab, prominent action
        .preferredColorScheme(.dark)       // the screen is designed on a dark backdrop
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let metrics: [Metric] = [
        .init(title: "Steps",   value: "8,432",  unit: "today", symbol: "figure.walk",        tint: .green),
        .init(title: "Heart",   value: "62",     unit: "BPM",   symbol: "heart.fill",         tint: .red),
        .init(title: "Sleep",   value: "7h 12m", unit: "last",  symbol: "moon.fill",          tint: .indigo),
        .init(title: "Mindful", value: "12",     unit: "min",   symbol: "brain.head.profile", tint: .teal),
        .init(title: "Water",   value: "1.2",    unit: "L",     symbol: "drop.fill",          tint: .blue),
        .init(title: "Energy",  value: "1,840",  unit: "kcal",  symbol: "flame.fill",         tint: .orange),
    ]

    private let workouts: [Workout] = [
        .init(title: "Morning HIIT",     duration: "22 min", participants: "14k",  tint: .pink),
        .init(title: "Calm Yoga Flow",   duration: "30 min", participants: "9.2k", tint: .teal),
        .init(title: "Endurance Run",    duration: "45 min", participants: "6.7k", tint: .orange),
        .init(title: "Strength Builder", duration: "35 min", participants: "11k",  tint: .purple),
    ]

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    activityCard
                    metricsRow
                    workoutsSection
                    planCard
                }
                .padding(.vertical)
                .padding(.bottom, 88)               // room for the floating action button
            }
            .scrollIndicators(.hidden)
            .minimizingNavigationBarOnScroll()      // iOS 27; no-op on 26
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Profile", systemImage: "person.crop.circle.fill") { }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Inbox", systemImage: "bell.fill") { }
                        .badge(3)                   // the badge carries the status; no red tint
                    Button("Share", systemImage: "square.and.arrow.up") { }
                }
            }

            floatingActionMenu
        }
    }

    // MARK: Header (content: greeting + system picker)

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Alex")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            }

            // Value selection in the content: a system segmented picker, not custom glass
            Picker("Period", selection: $period) {
                ForEach(Period.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }

    // MARK: Activity card (content: standard material)

    private var activityCard: some View {
        HStack(spacing: 20) {
            ActivityRings()
                .frame(width: 120, height: 120)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                statChip("Move",     value: "540 / 600", tint: .red)
                statChip("Exercise", value: "32 / 30",   tint: .green)
                statChip("Stand",    value: "10 / 12",   tint: .cyan)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(.regularMaterial, in: .rect(cornerRadius: 28, style: .continuous))
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
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.18), in: .capsule)       // a fill, not glass
        .accessibilityElement(children: .combine)
    }

    // MARK: Metrics (content cards, each a button)

    private var metricsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Metrics")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button("See all") { }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
            }
            .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(metrics) { m in
                        Button { } label: {
                            MetricCard(metric: m)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
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
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
            }
            .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(workouts) { w in
                        WorkoutCard(workout: w)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: Plan card (content: standard material)

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Today's plan")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("3 / 5")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.yellow.opacity(0.25), in: .capsule)   // a fill, not glass
                    .foregroundStyle(.white)
                    .accessibilityLabel("3 of 5 done")
            }

            VStack(spacing: 8) {
                planRow(done: true,  title: "Morning stretch",     time: "07:00")
                planRow(done: true,  title: "Hydrate (250 ml)",    time: "09:00")
                planRow(done: true,  title: "20-min walk",         time: "10:30")
                planRow(done: false, title: "Strength session",    time: "17:00")
                planRow(done: false, title: "Wind-down breathing", time: "22:00")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 24, style: .continuous))
        .padding(.horizontal)
    }

    private func planRow(done: Bool, title: String, time: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? .green : .white.opacity(0.5))
            Text(title)
                .font(.callout)
                .strikethrough(done)
                .foregroundStyle(done ? .white.opacity(0.65) : .white)
            Spacer()
            Text(time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.65))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(done ? .isSelected : [])
    }

    // MARK: Floating action menu (functional layer: one container, everything morphs)

    private var floatingActionMenu: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                GlassEffectContainer(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 16) {
                        if fabExpanded {
                            // No opacity transitions: these grow out of the toggle (matchedGeometry).
                            fabAction("Log Water", systemImage: "drop.fill")
                                .glassEffectID("fab-water", in: ns)
                            fabAction("Add Meal", systemImage: "fork.knife")
                                .glassEffectID("fab-meal", in: ns)
                            fabAction("Log Mood", systemImage: "face.smiling")
                                .glassEffectID("fab-mood", in: ns)
                            fabAction("Start Workout", systemImage: "figure.run")
                                .glassEffectID("fab-workout", in: ns)
                        }

                        Button {
                            withAnimation(reduceMotion ? .smooth : .bouncy) { fabExpanded.toggle() }
                        } label: {
                            Image(systemName: fabExpanded ? "xmark" : "plus")
                                .contentTransition(.symbolEffect(.replace))
                                .font(.title.weight(.semibold))
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.glassProminent)       // the primary action, in the app's accent color
                        .buttonBorderShape(.circle)
                        .accessibilityLabel(fabExpanded ? "Close" : "Add")
                        .glassEffectID("fab-toggle", in: ns)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func fabAction(_ title: String, systemImage: String) -> some View {
        Button { } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.callout.weight(.medium))
                Image(systemName: systemImage)
                    .frame(width: 24, height: 24)
            }
            .padding(.leading, 6)
            .padding(.vertical, 4)
        }
        .buttonStyle(.glass)
        .tint(.primary)                             // neutral; only the toggle is prominent
    }

    // MARK: Backdrop (content)

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

            // Color orbs give the glass varied content to refract
            Circle().fill(.green).frame(width: 320, height: 320).blur(radius: 90)
                .offset(x: -130, y: -260)
            Circle().fill(.teal).frame(width: 360, height: 360).blur(radius: 110)
                .offset(x: 150, y: -50)
            Circle().fill(.mint.opacity(0.7)).frame(width: 280, height: 280).blur(radius: 80)
                .offset(x: -100, y: 240)
            Circle().fill(.cyan.opacity(0.6)).frame(width: 240, height: 240).blur(radius: 70)
                .offset(x: 170, y: 360)
        }
        .accessibilityHidden(true)
    }
}

private extension View {
    /// iOS 27: minimize the navigation bar on scroll, like the tab bar.
    /// (`toolbarMinimizeBehavior` from the WWDC26 video does not exist.)
    @ViewBuilder
    func minimizingNavigationBarOnScroll() -> some View {
        if #available(iOS 27.0, *) {
            toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
        } else {
            self
        }
    }
}

// MARK: - Metric card

private struct Metric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let symbol: String
    let tint: Color
}

private struct MetricCard: View {
    let metric: Metric

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: metric.symbol)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(metric.tint)       // color identifies the metric; the card stays neutral
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Text(metric.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(metric.value)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(metric.unit)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(14)
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(.regularMaterial, in: .rect(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
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

            // Duration: a content chip, so a material, not glass
            VStack {
                HStack {
                    Spacer()
                    Text(workout.duration)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: .capsule)
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(12)

            VStack(alignment: .leading, spacing: 8) {
                Text(workout.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Label(workout.participants, systemImage: "person.2.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.black.opacity(0.25), in: .capsule)
                        .foregroundStyle(.white)

                    Spacer()

                    // The card's one glass element: a control over the card's media
                    Button { } label: {
                        Image(systemName: "play.fill")
                            .font(.callout.weight(.bold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .tint(.primary)
                    .accessibilityLabel("Start \(workout.title)")
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

// MARK: - Hydration strip (bottom accessory: already glass, so plain controls inside)

private struct HydrationStrip: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement   // Optional

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .padding(8)
                .background(.blue.opacity(0.2), in: .circle)
                .accessibilityHidden(true)

            if placement == .expanded {             // above the tab bar: room for detail
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time to hydrate")
                        .font(.callout.weight(.semibold))
                    Text("1.2 L of 2.5 L today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {                                // .inline (in line with the tab bar) or nil
                Text("Hydrate")
                    .font(.callout.weight(.semibold))
            }

            Spacer()

            Button("Add 250 ml", systemImage: "plus.circle.fill") { }
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(.blue)             // a plain control: the accessory is already glass
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
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
        .preferredColorScheme(.dark)
}
