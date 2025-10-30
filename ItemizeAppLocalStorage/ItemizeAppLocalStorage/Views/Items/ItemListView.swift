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

    // MARK: - Sort & Group
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAZ
        case nameZA
        case newest
        case oldest
        case quantityHigh
        case quantityLow
        case favoriteFirst
        case favoriteLast
        var id: String { rawValue }
        var title: String {
            switch self {
            case .nameAZ:        return NSLocalizedString("sort_name_az", comment: "Sort by name ascending")
            case .nameZA:        return NSLocalizedString("sort_name_za", comment: "Sort by name descending")
            case .newest:        return NSLocalizedString("sort_newest", comment: "Newest first")
            case .oldest:        return NSLocalizedString("sort_oldest", comment: "Oldest first")
            case .quantityHigh:  return NSLocalizedString("sort_quantity_high", comment: "Quantity high to low")
            case .quantityLow:   return NSLocalizedString("sort_quantity_low", comment: "Quantity low to high")
            case .favoriteFirst: return NSLocalizedString("sort_favorite_first", comment: "Favorites first")
            case .favoriteLast:  return NSLocalizedString("sort_favorite_last", comment: "Favorites last")
            }
        }
    }

    enum GroupOption: String, CaseIterable, Identifiable {
        case none
        case category
        case date
        case tag
        var id: String { rawValue }
        var title: String {
            switch self {
            case .none:     return NSLocalizedString("group_none", comment: "No grouping")
            case .category: return NSLocalizedString("group_category", comment: "Group by category")
            case .date:     return NSLocalizedString("group_date", comment: "Group by date added")
            case .tag:      return NSLocalizedString("group_tag", comment: "Group by tag")
            }
        }
    }

    @AppStorage("item_sort") private var sortRaw: String = SortOption.nameAZ.rawValue
    @AppStorage("item_group") private var groupRaw: String = GroupOption.none.rawValue

    // Local UI selection state to avoid immutable-self errors in Picker bindings
    @State private var sortSelection: SortOption = .nameAZ
    @State private var groupSelection: GroupOption = .none
    
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
            let matchesText = search.isEmpty
                || item.name.localizedCaseInsensitiveContains(search)
                || item.fields.contains { $0.key.localizedCaseInsensitiveContains(search) || $0.value.localizedCaseInsensitiveContains(search) }
                || item.tags.contains { $0.name.localizedCaseInsensitiveContains(search) }
            let matchesCat = selectedCategory == nil || item.category?.id == selectedCategory?.id
            return matchesText && matchesCat
        }
    }

    // MARK: - Sorting & Grouping helpers
    private func applySort(_ items: [Item]) -> [Item] {
        switch sortSelection {
        case .nameAZ:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameZA:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .newest:
            return items.sorted { ($0.createdAt) > ($1.createdAt) }
        case .oldest:
            return items.sorted { ($0.createdAt) < ($1.createdAt) }
        case .quantityHigh:
            return items.sorted { $0.quantity > $1.quantity }
        case .quantityLow:
            return items.sorted { $0.quantity < $1.quantity }
        case .favoriteFirst:
            return items.sorted { (lhs, rhs) in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
                // tie-breakers: name, then createdAt desc
                let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
                return lhs.createdAt > rhs.createdAt
            }
        case .favoriteLast:
            return items.sorted { (lhs, rhs) in
                if lhs.isFavorite != rhs.isFavorite { return !lhs.isFavorite && rhs.isFavorite }
                let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
                return lhs.createdAt > rhs.createdAt
            }
        }
    }

    private func grouped(_ items: [Item]) -> [(header: String, rows: [Item])] {
        switch groupSelection {
        case .none:
            return [("", applySort(items))]
        case .category:
            let groups = Dictionary(grouping: items) { $0.category?.breadcrumb ?? NSLocalizedString("Zonder categorie", comment: "") }
            return groups.keys.sorted().map { key in (key, applySort(groups[key]!)) }
        case .date:
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            let groups = Dictionary(grouping: items) { fmt.string(from: $0.createdAt) }
            return groups.keys.sorted().map { key in (key, applySort(groups[key]!)) }
        case .tag:
            var groups: [String: [Item]] = [:]
            for it in items {
                if it.tags.isEmpty {
                    let noneKey = "(" + NSLocalizedString("Zonder tag", comment: "") + ")"
                    groups[noneKey, default: []].append(it)
                } else {
                    for t in it.tags {
                        groups[t.name, default: []].append(it)
                    }
                }
            }
            return groups.keys.sorted().map { key in (key, applySort(groups[key]!)) }
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
                for img in it.images { ImageStore.delete(named: img.filename) }
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
                    let sections = grouped(filtered)
                    ForEach(sections, id: \.header) { section in
                        if groupSelection != .none {
                            Section(section.header) {
                                ForEach(section.rows) { item in
                                    NavigationLink {
                                        ItemDetailView(item: item)
                                    } label: {
                                        ItemRow(item: item)
                                    }
                                }
                                .onDelete { idx in
                                    for i in idx {
                                        let item = section.rows[i]
                                        for img in item.images { ImageStore.delete(named: img.filename) }
                                        ctx.delete(item)
                                    }
                                    try? ctx.save()
                                }
                            }
                        } else {
                            ForEach(section.rows) { item in
                                NavigationLink {
                                    ItemDetailView(item: item)
                                } label: {
                                    ItemRow(item: item)
                                }
                            }
                            .onDelete { idx in
                                for i in idx {
                                    let item = section.rows[i]
                                    for img in item.images { ImageStore.delete(named: img.filename) }
                                    ctx.delete(item)
                                }
                                try? ctx.save()
                            }
                        }
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
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.tealGreen)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(NSLocalizedString("menu_sort", comment: "Sort"), selection: $sortSelection) {
                            ForEach(SortOption.allCases) { opt in
                                Text(opt.title).tag(opt)
                            }
                        }
                        Picker(NSLocalizedString("menu_group", comment: "Group"), selection: $groupSelection) {
                            ForEach(GroupOption.allCases) { opt in
                                Text(opt.title).tag(opt)
                            }
                        }
                        Divider()
                        Button {
                            withAnimation {
                                sortSelection = .nameAZ
                                groupSelection = .none
                                sortRaw = SortOption.nameAZ.rawValue
                                groupRaw = GroupOption.none.rawValue
                            }
                        } label: {
                            Label(NSLocalizedString("menu_reset_defaults", comment: "Reset to defaults"), systemImage: "arrow.uturn.backward")
                        }
                    } label: {
                        Label(NSLocalizedString("menu_sort_group", comment: "Sort & Group"), systemImage: "arrow.up.arrow.down.square")
                    }
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
            .onAppear {
                // load persisted options with migration from old localized raw values
                if let s = SortOption(rawValue: sortRaw) {
                    sortSelection = s
                } else {
                    switch sortRaw { // legacy labels -> keys
                    case "Naam A–Z": sortSelection = .nameAZ
                    case "Naam Z–A": sortSelection = .nameZA
                    case "Nieuwste eerst": sortSelection = .newest
                    case "Oudste eerst": sortSelection = .oldest
                    case "Hoeveelheid hoog → laag": sortSelection = .quantityHigh
                    case "Hoeveelheid laag → hoog": sortSelection = .quantityLow
                    case "Favorieten eerst": sortSelection = .favoriteFirst
                    case "Favorieten laatst": sortSelection = .favoriteLast
                    default: sortSelection = .nameAZ
                    }
                    sortRaw = sortSelection.rawValue // rewrite to new key
                }
                if let g = GroupOption(rawValue: groupRaw) {
                    groupSelection = g
                } else {
                    switch groupRaw {
                    case "Geen": groupSelection = .none
                    case "Categorie": groupSelection = .category
                    case "Datum toegevoegd": groupSelection = .date
                    case "Tag": groupSelection = .tag
                    default: groupSelection = .none
                    }
                    groupRaw = groupSelection.rawValue
                }
            }
            .onChange(of: sortSelection) {
                sortRaw = sortSelection.rawValue
            }
            .onChange(of: groupSelection) {
                groupRaw = groupSelection.rawValue
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
