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

    var body: some View {
        List {
            // Image preview
            if let filename = item.image?.filename, let ui = ImageStore.loadImage(named: filename) {
                Section {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.quaternary))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            Section("Details") {
                LabeledContent("Naam") { Text(item.name) }
                LabeledContent("Hoeveelheid") { Text("\(item.quantity)") }
                LabeledContent("Categorie") { Text(item.category?.name ?? "—") }
                LabeledContent("Aangemaakt") {
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
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
        .navigationTitle("Overzicht")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            NavigationStack { ItemFormView(item: item) }
        }
    }
}

