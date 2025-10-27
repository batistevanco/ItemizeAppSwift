//
//  ItemFormView.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//


// File: Views/Items/ItemFormView.swift
import SwiftUI
import SwiftData
import PhotosUI

struct ItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    
    @Query(sort: \Category.name) private var categories: [Category]
    
    // Edit of nieuw
    @State private var item: Item
    private let isNew: Bool
    
    // UI state
    @State private var showCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var newFieldKey = ""
    @State private var newFieldValue = ""
    @State private var newCategoryName = ""
    @FocusState private var focused: Field?
    enum Field: Hashable { case name, newCategory, dynKey, dynValue }
    
    init(item: Item? = nil) {
        if let existing = item {
            _item = State(initialValue: existing)
            isNew = false
        } else {
            _item = State(initialValue: Item(name: "", quantity: 1))
            isNew = true
        }
    }
    
    var body: some View {
        Form {
            Section("Basis") {
                TextField("Naam", text: $item.name).focused($focused, equals: .name)
                Stepper(value: $item.quantity, in: 1...999) {
                    HStack {
                        Text("Hoeveelheid")
                        Spacer()
                        Text("\(item.quantity)")
                            .foregroundStyle(.secondary)
                    }
                }
                Picker("Categorie", selection: Binding(
                    get: { item.category?.id ?? "none" },
                    set: { newId in
                        if newId == "none" {
                            item.category = nil
                        } else if let cat = categories.first(where: { $0.id == newId }) {
                            item.category = cat
                        }
                    })) {
                        Text("Geen").tag("none")
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                }
                .pickerStyle(.navigationLink)
                .buttonStyle(.borderless)
                HStack {
                    TextField("Nieuwe categorie", text: $newCategoryName)
                        .textInputAutocapitalization(.words)
                        .focused($focused, equals: .newCategory)
                    Button {
                        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        let cat = Category(name: name)
                        ctx.insert(cat)
                        try? ctx.save()
                        item.category = cat
                        newCategoryName = ""
                    } label: {
                        Label("Voeg toe", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Section("Dynamische velden") {
                ForEach(item.fields) { field in
                    HStack {
                        Text(field.key).font(.subheadline)
                        Spacer()
                        Text(field.value).foregroundStyle(.secondary)
                    }
                }
                .onDelete { idx in
                    for i in idx { item.fields.remove(at: i) }
                }
                
                HStack {
                    TextField("Naam (bv. Kleur)", text: $newFieldKey).focused($focused, equals: .dynKey)
                    TextField("Waarde (bv. Wit)", text: $newFieldValue).focused($focused, equals: .dynValue)
                    Button {
                        let k = newFieldKey.trimmingCharacters(in: .whitespaces)
                        let v = newFieldValue.trimmingCharacters(in: .whitespaces)
                        guard !k.isEmpty, !v.isEmpty else { return }
                        item.fields.append(DynamicField(key: k, value: v))
                        newFieldKey = ""; newFieldValue = ""
                    } label: { Image(systemName: "plus.circle.fill") }
                    .buttonStyle(.borderless)
                }
            }
            
            Section("Afbeelding") {
                if let filename = item.image?.filename, let ui = ImageStore.loadImage(named: filename) {
                    Image(uiImage: ui)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
                    Button(role: .destructive) {
                        ImageStore.delete(named: filename)
                        item.image = nil
                    } label: { Label("Verwijder afbeelding", systemImage: "trash") }
                } else {
                    Text("Geen afbeelding toegevoegd").foregroundStyle(.secondary)
                }
                
                HStack {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Kies foto", systemImage: "photo")
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                    Button {
                        showCamera = true
                    } label: {
                        Label("Neem foto", systemImage: "camera")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(isNew ? "Nieuw item" : "Bewerk item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isNew { Button("Annuleer", role: .cancel) { dismiss() } }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bewaar") { saveAndClose() }
                    .disabled(item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onChange(of: selectedPhoto) { _, newVal in
            guard let newVal else { return }
            Task {
                if let data = try? await newVal.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    handlePickedImage(ui)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { ui in
                if let fn = item.image?.filename { ImageStore.delete(named: fn) }
                if let saved = try? ImageStore.saveJPEG(ui) {
                    item.image = ImageAsset(filename: saved)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    private func handlePickedImage(_ image: UIImage?) {
        guard let image else { return }
        if let fn = item.image?.filename { ImageStore.delete(named: fn) }
        if let saved = try? ImageStore.saveJPEG(image) {
            item.image = ImageAsset(filename: saved)
        }
    }
    
    private func saveAndClose() {
        if isNew { ctx.insert(item) }
        try? ctx.save()
        dismiss()
    }
}
