// SettingsScreen.swift
// iOS 26 Liquid Glass example — a Settings-style list with grouped sections,
// a glass primary CTA at the bottom, and a search field that minimizes.
//
// Requires: Xcode 26+, iOS 26+.

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
                    LabeledContent("Apple ID", value: "kzn.parsa@icloud.com")
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
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .tint(.red)
                    .listRowBackground(Color.clear)
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
            .confirmationDialog("Sign out of this account?", isPresented: $showSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}

#Preview {
    SettingsScreen()
}
