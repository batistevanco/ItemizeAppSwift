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
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var selectedTags: [Tag] = []
    @State private var tagInput: String = ""
    
    // Edit of nieuw
    @State private var item: Item
    private let isNew: Bool
    
    // UI state
    @State private var showCamera = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var workingImages: [ImageAsset] = []
    @State private var newFieldKey = ""
    @State private var newFieldValue = ""
    @State private var newCategoryName = ""
    @FocusState private var focused: Field?
    enum Field: Hashable { case name, newCategory, dynKey, dynValue }
    
    init(item: Item? = nil) {
        if let existing = item {
            _item = State(initialValue: existing)
            _selectedTags = State(initialValue: existing.tags)
            _workingImages = State(initialValue: existing.images)
            isNew = false
        } else {
            let fresh = Item(name: "", quantity: 1)
            _item = State(initialValue: fresh)
            _selectedTags = State(initialValue: [])
            _workingImages = State(initialValue: [])
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
                Picker("Categorie", selection: $item.category) {
                    Text("—").tag(Category?.none)
                    ForEach(categories) { cat in
                        Text(cat.breadcrumb).tag(Category?.some(cat))
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
            
            Section("Tags") {
                // Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags) { tag in
                            HStack(spacing: 6) {
                                Text(tag.name)
                                Button(role: .destructive) {
                                    selectedTags.removeAll { $0.id == tag.id }
                                } label: { Image(systemName: "xmark.circle.fill") }
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.thinMaterial).clipShape(Capsule())
                        }
                    }.padding(.vertical, 4)
                }

                HStack {
                    TextField("Voeg tag(s) toe (bv. USB-C, Thunderbolt)", text: $tagInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    Button("Toevoegen") {
                        let names = tagInput
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        for n in names {
                            if let existing = allTags.first(where: { $0.name.caseInsensitiveCompare(n) == .orderedSame }) {
                                if !selectedTags.contains(where: { $0.id == existing.id }) {
                                    selectedTags.append(existing)
                                }
                            } else {
                                let t = Tag(name: n)
                                ctx.insert(t)
                                selectedTags.append(t)
                            }
                        }
                        tagInput = ""
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
            
            Section("Foto’s") {
                // Gallery grid
                if workingImages.isEmpty {
                    Text("Geen foto’s toegevoegd").foregroundStyle(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                        ForEach(workingImages, id: \.id) { asset in
                            if let ui = ImageStore.loadImage(named: asset.filename) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Button(role: .destructive) {
                                        if let idx = workingImages.firstIndex(where: { $0.id == asset.id }) {
                                            // Remove only this asset from state first
                                            let filename = workingImages[idx].filename
                                            withAnimation { _ = workingImages.remove(at: idx) }
                                            // Delete the file only if no other asset still points to the same file
                                            let stillReferenced = workingImages.contains { $0.filename == filename }
                                            if !stillReferenced {
                                                ImageStore.delete(named: filename)
                                            }
                                        }
                                    } label: { Image(systemName: "xmark.circle.fill") }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Pickers row
                HStack {
                    PhotosPicker("Kies foto’s", selection: $selectedPhotos, maxSelectionCount: 0, matching: .images)
                        .buttonStyle(.borderless)
                    Spacer()
                    Button {
                        showCamera = true
                    } label: { Label("Neem foto", systemImage: "camera") }
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
        .onChange(of: selectedPhotos) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                var nextOrder = (workingImages.compactMap { $0.order }.max() ?? -1) + 1
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data),
                       let saved = try? ImageStore.saveJPEG(ui) {
                        let asset = ImageAsset(filename: saved, order: nextOrder)
                        workingImages.append(asset)
                        nextOrder += 1
                    }
                }
                selectedPhotos.removeAll()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { ui in
                if let saved = try? ImageStore.saveJPEG(ui) {
                    let nextOrder = (workingImages.compactMap { $0.order }.max() ?? -1) + 1
                    workingImages.append(ImageAsset(filename: saved, order: nextOrder))
                }
            }
            .ignoresSafeArea()
        }
    }
    
    private func handlePickedImage(_ image: UIImage?) {
        guard let image else { return }
        if let saved = try? ImageStore.saveJPEG(image) {
            let nextOrder = (workingImages.compactMap { $0.order }.max() ?? -1) + 1
            workingImages.append(ImageAsset(filename: saved, order: nextOrder))
        }
    }
    
    private func saveAndClose() {
        item.tags = selectedTags
        item.images = workingImages
        if isNew { ctx.insert(item) }
        try? ctx.save()
        dismiss()
    }
}
