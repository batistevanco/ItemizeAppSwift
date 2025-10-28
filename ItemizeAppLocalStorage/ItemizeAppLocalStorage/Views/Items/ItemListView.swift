//
//  ItemListView.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//


// File: Views/Items/ItemListView.swift
import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @Query(sort: \Category.name) private var allCategories: [Category]
    
    @State private var search = ""
    @FocusState private var searchFocused: Bool
    @State private var showSearchBar = false
    @State private var selectedCategory: Category?
    @State private var showNewItem = false
    
    @AppStorage("demoActive") private var demoActive = false
    @State private var showPurgeAlert = false

    // MARK: - Summary
    private var totalItemsCount: Int { filtered.count }
    private var categoriesCount: Int {
        Set(filtered.compactMap { $0.category?.id }).count
    }

    private struct SummaryCard: View {
        let valueText: String
        let labelText: String
        let systemImage: String

        var body: some View {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(valueText)
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(labelText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
            )
        }
    }
    
    private struct HeaderArea: View {
        let totalItems: Int
        let categoriesCount: Int
        let categories: [Category]
        @Binding var selectedCategory: Category?
        let colorForCategory: (Category) -> Color

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Button {
                            selectedCategory = nil
                        } label: {
                            Text("Alle")
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(selectedCategory == nil ? Color.accentColor.opacity(0.2) : Color(.systemFill))
                                .clipShape(Capsule())
                        }
                        ForEach(categories) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat.name)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedCategory?.id == cat.id ? colorForCategory(cat).opacity(0.3) : Color(.systemFill)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 3)
                }

                // Summary cards
                HStack(spacing: 12) {
                    SummaryCard(
                        valueText: String(totalItems),
                        labelText: NSLocalizedString("items_in_inventory", comment: "Label for total items in inventory"),
                        systemImage: "shippingbox"
                    )
                    SummaryCard(
                        valueText: String(categoriesCount),
                        labelText: NSLocalizedString("categories_label", comment: "Label for categories count"),
                        systemImage: "square.grid.2x2"
                    )
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.12), Color.accentColor.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
            // Removed shadow effect for header area
        }
    }
    
    private struct FloatingSearchBar: View {
        @Binding var text: String
        @Binding var isPresented: Bool
        @FocusState private var focused: Bool

        var body: some View {
            Group {
                if isPresented {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                        TextField("Zoek naam of veld…", text: $text)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .focused($focused)
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                text = ""
                                focused = false
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
                    )
                    .shadow(radius: 8)
                    .padding(.horizontal)
                    .task { focused = true }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isPresented = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle().fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    Circle().stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                                )
                                .shadow(radius: 6, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    var filtered: [Item] {
        items.filter { item in
            let matchesText = search.isEmpty || item.name.localizedCaseInsensitiveContains(search)
                || item.fields.contains { $0.key.localizedCaseInsensitiveContains(search) || $0.value.localizedCaseInsensitiveContains(search) }
            let matchesCat = selectedCategory == nil || item.category?.id == selectedCategory?.id
            return matchesText && matchesCat
        }
    }

    private func categoryColor(for category: Category) -> Color {
        switch category.name.lowercased() {
        case "elektronica": return .orange
        case "gereedschap": return .green
        case "kantoor": return .blue
        case "snacks": return .pink
        case "kabels": return .purple
        default: return .teal
        }
    }
    
    private func purgeDemo() {
        // 1) Verwijder demo-items
        let demoItems = items.filter { $0.isDemo }
        withAnimation {
            for it in demoItems {
                if let fn = it.image?.filename { ImageStore.delete(named: fn) }
                ctx.delete(it)
            }
        }
        try? ctx.save()

        // 2) Herfetch items om categorie-opruim te baseren op actuele data
        let currentItems = (try? ctx.fetch(FetchDescriptor<Item>())) ?? []

        // 3) Verwijder demo-categorieën zonder niet-demo items
        for cat in allCategories where cat.isDemo {
            let hasNonDemo = currentItems.contains { $0.category?.id == cat.id && !$0.isDemo }
            if !hasNonDemo { ctx.delete(cat) }
        }
        try? ctx.save()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HeaderArea(
                    totalItems: totalItemsCount,
                    categoriesCount: categoriesCount,
                    categories: allCategories,
                    selectedCategory: $selectedCategory,
                    colorForCategory: { cat in categoryColor(for: cat) }
                )
                .padding(.horizontal)
                .padding(.top, 4)
                
                List {
                    ForEach(filtered) { item in
                        NavigationLink {
                            ItemDetailView(item: item) // <-- eerst overzicht
                        } label: {
                            ItemRow(item: item)
                        }
                    }
                    .onDelete { idx in
                        for i in idx {
                            let item = filtered[i]
                            if let fn = item.image?.filename {
                                ImageStore.delete(named: fn)
                            }
                            ctx.delete(item)
                        }
                        try? ctx.save()
                    }
                }
                .listStyle(.insetGrouped)
                .scrollDismissesKeyboard(.immediately)
            }
            .scrollDismissesKeyboard(.immediately)
            .overlay(alignment: .bottom) {
                FloatingSearchBar(text: $search, isPresented: $showSearchBar)
                    .padding(.bottom, 18)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Itemize")
                        .font(.title2.bold())
                        .foregroundColor(Color.tealGreen)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if demoActive {
                            showPurgeAlert = true
                        } else {
                            showNewItem = true
                        }
                    } label: {
                        ZStack {
                            Circle().fill(Color.tealGreen)
                            Image(systemName: "plus").font(.headline).foregroundStyle(.white)
                        }
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNewItem) {
                NavigationStack { ItemFormView() }
            }
            .alert("Voorbeelddata verwijderen?", isPresented: $showPurgeAlert) {
                Button("Verwijder voorbeelddata", role: .destructive) {
                    purgeDemo()
                    demoActive = false
                    showNewItem = true   // meteen door naar nieuw item
                }
                Button("Annuleer", role: .cancel) { }
            } message: {
                Text("Wanneer je begint met je eigen items, verwijderen we de voorbeelddata uit de app.")
            }
        }
    }
}
