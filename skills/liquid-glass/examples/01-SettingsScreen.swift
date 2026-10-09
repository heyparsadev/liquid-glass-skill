// SettingsScreen.swift
// Liquid Glass example: a Settings-style list.
//
// Functional layer (glass, all system-provided): the navigation bar, the
// toolbar button, and the search field, which minimizes into the toolbar.
// Content layer (no glass): the grouped list. Sign Out is a standard
// destructive row, not a prominent primary (HIG Buttons). Its confirmation
// dialog is attached to the button so it morphs out of it.
//
// Requires: Xcode 26 or later, iOS 26 or later.

import SwiftUI

struct SettingsScreen: View {
    @State private var query = ""
    @State private var notificationsEnabled = true
    @State private var appearance: Appearance = .system
    @State private var showSignOut = false

    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Apple Account", value: "appleseed@example.com")
                    NavigationLink("Subscriptions") { Text("Subscriptions") }
                    NavigationLink("Payment & Shipping") { Text("Payment") }
                }

                Section("Preferences") {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    NavigationLink("Language") { Text("Language") }
                }

                Section("About") {
                    LabeledContent("Version", value: "3.2.1")
                    NavigationLink("Privacy Policy") { Text("Privacy") }
                    NavigationLink("Terms of Service") { Text("Terms") }
                }

                Section {
                    Button(role: .destructive) {
                        showSignOut = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    // Attached to the button, so the dialog morphs out of it.
                    .confirmationDialog("Sign out of this account?", isPresented: $showSignOut, titleVisibility: .visible) {
                        Button("Sign Out", role: .destructive) { }
                        Button("Cancel", role: .cancel) { }
                    }
                }
            }
            .navigationTitle("Settings")
            .searchable(text: $query, prompt: "Search settings")
            .searchToolbarBehavior(.minimize)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Profile", systemImage: "person.crop.circle") { }
                }
            }
        }
    }
}

#Preview {
    SettingsScreen()
}
