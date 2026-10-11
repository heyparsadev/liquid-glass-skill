// StoreScreen.swift
// Liquid Glass example: a store app shell built with the iOS 27 chrome APIs.
//
// iOS 27.0 APIs shown:
//  • TabRole.prominent: the Bag tab sits apart, in the trailing position
//  • toolbarMinimizationBehavior(_:for:): the navigation bar minimizes on scroll
//    (not `toolbarMinimizeBehavior`, which appears only in the WWDC26 video)
//  • ToolbarItemPlacement.topBarPinnedTrailing: Favorites never moves to overflow
//  • visibilityPriority(_:): Filters is the last item to overflow
//  • toolbarOverflowMenu(content:): secondary actions always in the system overflow menu
//  • NavigationTransition.crossFade: the Filters sheet fades in instead of sliding up
// iOS 26 APIs alongside: searchable + .minimize, tabBarMinimizeBehavior,
// safeAreaBar for the checkout bar, and Button(role: .close).
//
// Functional layer (glass, system-provided): the tab bar, the navigation bar
// and its items, the sheet, and the checkout bar's prominent button (the one
// primary action).
// Content layer (no glass): the product rows.
//
// Requires: Xcode 27 and iOS 27. Everything is marked @available(iOS 27.0, *).
// On a 26.0 deployment target, gate these APIs as in
// references/08-system-chrome.md § 9 instead.

import SwiftUI

// MARK: - App shell

@available(iOS 27.0, *)
struct StoreAppShell: View {
    var body: some View {
        TabView {
            Tab("Discover", systemImage: "sparkles") {
                NavigationStack { DiscoverScreen() }
            }
            Tab("Orders", systemImage: "shippingbox") {
                NavigationStack {
                    ContentUnavailableView("No Orders Yet", systemImage: "shippingbox",
                                           description: Text("Orders you place appear here."))
                        .navigationTitle("Orders")
                }
            }
            Tab("Bag", systemImage: "bag", role: .prominent) {    // separate, trailing tab
                NavigationStack { BagScreen() }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)                     // iPhone only
    }
}

// MARK: - Discover

@available(iOS 27.0, *)
private struct DiscoverScreen: View {
    @State private var query = ""
    @State private var favoritesOnly = false
    @State private var showFilters = false

    private var products: [Product] {
        Product.samples.filter { product in
            (query.isEmpty || product.name.localizedStandardContains(query))
                && (!favoritesOnly || product.isFavorite)
        }
    }

    var body: some View {
        List(products) { product in
            ProductRow(product: product)
        }
        .navigationTitle("Discover")
        .searchable(text: $query, prompt: "Search products")
        .searchToolbarBehavior(.minimize)
        .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarPinnedTrailing) {
                Button("Favorites", systemImage: favoritesOnly ? "heart.fill" : "heart") {
                    favoritesOnly.toggle()
                }
                .accessibilityAddTraits(favoritesOnly ? .isSelected : [])
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Filters", systemImage: "line.3.horizontal.decrease") {
                    showFilters = true
                }
            }
            .visibilityPriority(.high)          // a ToolbarContent modifier: on the item, not the button
        }
        .toolbarOverflowMenu {
            Button("Sort by Price", systemImage: "arrow.up.arrow.down") { }
            Button("Sort by Newest", systemImage: "clock") { }
            Button("Select Items", systemImage: "checkmark.circle") { }
        }
        .sheet(isPresented: $showFilters) {
            FiltersSheet()
                .presentationDetents([.medium, .large])
                .navigationTransition(.crossFade)
        }
    }
}

@available(iOS 27.0, *)
private struct FiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inStockOnly = true
    @State private var maxPrice = 200.0

    var body: some View {
        NavigationStack {
            Form {
                Toggle("In Stock Only", isOn: $inStockOnly)
                LabeledContent("Maximum Price") {
                    Text(maxPrice, format: .currency(code: "USD"))
                }
                Slider(value: $maxPrice, in: 20...500, step: 10) {
                    Text("Maximum Price")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // A task sheet: Cancel leading, Done (prominent) trailing (HIG Sheets)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .buttonStyle(.glassProminent)
                }
            }
        }
    }
}

// MARK: - Bag

@available(iOS 27.0, *)
private struct BagScreen: View {
    private let items = Array(Product.samples.prefix(3))

    private var total: Double { items.reduce(0) { $0 + $1.price } }

    var body: some View {
        List(items) { product in
            ProductRow(product: product)
        }
        .navigationTitle("Bag")
        .safeAreaBar(edge: .bottom) {                 // a custom bar that joins the scroll edge effect
            Button {
                // check out
            } label: {
                HStack {
                    Text("Check Out")
                    Spacer()
                    Text(total, format: .currency(code: "USD"))
                }
                .font(.body.weight(.semibold))
                .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)             // the one primary action
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Content (no glass)

private struct Product: Identifiable {
    let id: Int
    let name: String
    let price: Double
    let symbol: String
    let tint: Color
    let isFavorite: Bool

    static let samples: [Product] = {
        let catalog: [(String, Double, String, Color)] = [
            ("Trail Runner", 129, "shoe.fill", .orange),
            ("Canvas Tote", 39, "bag.fill", .brown),
            ("Everyday Tee", 25, "tshirt.fill", .blue),
            ("Day Pack", 89, "backpack.fill", .green),
            ("Reading Glasses", 59, "eyeglasses", .indigo),
            ("Studio Headphones", 199, "headphones", .gray),
            ("Travel Camera", 449, "camera.fill", .teal),
            ("Pocket Umbrella", 29, "umbrella.fill", .purple),
            ("Gift Card", 50, "gift.fill", .pink),
            ("Pour-Over Set", 45, "cup.and.saucer.fill", .brown),
            ("Field Notebook", 15, "book.fill", .red),
            ("Game Controller", 69, "gamecontroller.fill", .mint),
        ]
        // Twenty-four rows: enough to scroll and watch the bars minimize.
        return (0..<24).map { i in
            let item = catalog[i % catalog.count]
            return Product(id: i, name: item.0, price: item.1, symbol: item.2,
                           tint: item.3, isFavorite: i % 3 == 0)
        }
    }()
}

private struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: product.symbol)
                .font(.title2)
                .foregroundStyle(product.tint)
                .frame(width: 52, height: 52)
                .background(product.tint.opacity(0.15), in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.headline)
                Text(product.price, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if product.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                    .accessibilityLabel("Favorite")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 27.0, *) {
        StoreAppShell()
    } else {
        Text("Requires iOS 27")
    }
}
