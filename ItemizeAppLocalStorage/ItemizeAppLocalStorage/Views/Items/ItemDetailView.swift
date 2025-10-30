//
//  ItemDetailView.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//


//
//  ItemDetailView.swift
//  ItemizeAppLocalStorage
//
//  Created by ChatGPT on 27/10/2025.
//

import SwiftUI
import SwiftData

// File: Views/Items/ItemDetailView.swift
struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    let item: Item
    @State private var showEdit = false
    @State private var selectedIndex = 0

    // Precompute sorted images to keep the view body simpler for the type-checker
    private var sortedImages: [ImageAsset] {
        item.images.sorted { (a: ImageAsset, b: ImageAsset) -> Bool in
            (a.order ?? 0) < (b.order ?? 0)
        }
    }

    private struct ItemGalleryView: View {
        let images: [ImageAsset]
        @Binding var selectedIndex: Int

        var body: some View {
            Section {
                TabView(selection: $selectedIndex) {
                    ForEach(0..<images.count, id: \.self) { idx in
                        let img = images[idx]
                        if let ui = ImageStore.loadImage(named: img.filename) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.quaternary))
                                .padding(.vertical, 4)
                                .tag(idx)
                        }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 300)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<images.count, id: \.self) { idx in
                            let img = images[idx]
                            if let ui = ImageStore.loadImage(named: img.filename) {
                                Button {
                                    withAnimation(.easeInOut) { selectedIndex = idx }
                                } label: {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(
                                                    (idx == selectedIndex ? Color.accentColor : Color.secondary).opacity(idx == selectedIndex ? 1 : 0.4),
                                                    lineWidth: idx == selectedIndex ? 2 : 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            }
        }
    }

    var body: some View {
        List {
            // Gallery preview (multiple images)
            if !item.images.isEmpty {
                ItemGalleryView(images: sortedImages, selectedIndex: $selectedIndex)
            }

            Section("Details") {
                LabeledContent("Naam") { Text(item.name) }
                LabeledContent("Hoeveelheid") { Text("\(item.quantity)") }
                LabeledContent("Categorie") { Text(item.category?.name ?? "—") }
                LabeledContent("Aangemaakt") {
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
            }

            if !item.tags.isEmpty {
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(item.tags) { tag in
                                Text(tag.name)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.tealGreen.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !item.fields.isEmpty {
                Section("Eigenschappen") {
                    ForEach(item.fields) { f in
                        LabeledContent(f.key) { Text(f.value) }
                    }
                }
            }

            Section {
                Button {
                    showEdit = true
                } label: {
                    Label("Bewerk", systemImage: "pencil")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    item.isFavorite.toggle()
                    try? ctx.save()
                } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Overzicht")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            NavigationStack { ItemFormView(item: item) }
        }
        .onAppear {
            item.bumpUsage()
            try? ctx.save()
        }
    }
}
