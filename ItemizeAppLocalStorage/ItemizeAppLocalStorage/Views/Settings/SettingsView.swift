//
//  SettingsView.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//

// File: Views/Settings/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Category.name) private var categories: [Category]
    @Query private var items: [Item]
    
    @AppStorage("appTheme") private var appTheme: Theme = .auto
    @State private var newCategory = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @FocusState private var focusedField: Bool
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thema") {
                    Picker("Weergave", selection: $appTheme) {
                        ForEach(Theme.allCases, id: \.self) { t in
                            Text(t.title).tag(t)
                        }
                    }
                }
                Section("Categorieën") {
                    ForEach(categories) { cat in
                        HStack {
                            Text(cat.name)
                            Spacer()
                            let inUse = isCategoryInUse(cat)
                            Button(role: .destructive) {
                                if inUse {
                                    alertTitle = "Kan niet verwijderen"
                                    alertMessage = "Er bestaan nog items in deze categorie."
                                    showAlert = true
                                } else {
                                    ctx.delete(cat)
                                    try? ctx.save()
                                }
                            } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                            .disabled(inUse)
                            .help(inUse ? "Categorie in gebruik" : "Verwijder categorie")
                        }
                    }
                    HStack {
                        TextField("Nieuwe categorie", text: $newCategory)
                            .focused($focusedField)
                        Button {
                            let name = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            ctx.insert(Category(name: name))
                            try? ctx.save()
                            newCategory = ""
                        } label: { Label("Voeg toe", systemImage: "plus.circle.fill") }
                        .buttonStyle(.borderless)
                    }
                }
                Section("Support") {
                    Button {
                        if let url = URL(string: "mailto:support@vancoilliestudio.be?subject=Itemize%20Support") {
                            openURL(url)
                        }
                    } label: {
                        Label("Contacteer support", systemImage: "envelope")
                    }
                    .buttonStyle(.borderless)
                }
                Section("Over") {
                    LabeledContent("App") {
                        Text(appName)
                    }
                    LabeledContent("Maker") {
                        Text("Vancoillie Studio")
                    }
                    LabeledContent("Versie") {
                        Text(appVersion)
                    }
                    LabeledContent("Build") {
                        Text(appBuild)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .contentShape(Rectangle())
            .onTapGesture { focusedField = false }
            .gesture(DragGesture().onChanged { _ in focusedField = false })
            .navigationTitle("Instellingen")
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var appName: String {
        if let display = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !display.isEmpty {
            return display
        }
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String, !name.isEmpty {
            return name
        }
        return "Itemize"
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
    
    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
    
    private func isCategoryInUse(_ cat: Category) -> Bool {
        items.contains { $0.category?.id == cat.id }
    }
}
