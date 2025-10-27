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
    @State private var selectedCategory: Category?
    @State private var showNewItem = false
    @FocusState private var searchFocused: Bool
    
    @AppStorage("demoActive") private var demoActive = false
    @State private var showPurgeAlert = false
    
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
                // Filter row
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
                        ForEach(allCategories) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat.name)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedCategory?.id == cat.id ? categoryColor(for: cat).opacity(0.3) : Color(.systemFill)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 3)
                }
                
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
            .toolbar {
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Itemize")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.tealGreen)
                }
            }
            .searchable(text: $search, prompt: "Zoek naam of veld…")
            .searchFocused($searchFocused)
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
