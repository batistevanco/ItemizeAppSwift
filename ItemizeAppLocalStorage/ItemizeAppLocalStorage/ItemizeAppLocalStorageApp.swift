// File: ItemizeAppLocalStorageApp.swift
import SwiftUI
import SwiftData

@main
struct ItemizeAppLocalStorageApp: App {
    @AppStorage("seededDemo_v1") private var seededDemo = false
    @AppStorage("demoActive") private var demoActive = false
    @AppStorage("appTheme") private var appTheme: Theme = .auto

    // Gebruik één gedeelde SwiftData-container
    private let container = ModelContainerProvider.shared.container

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(appTheme.colorScheme)
                // Injecteer de container in de view-hiërarchie
                .modelContainer(container)
                .task {
                    // Eénmalig seeden bij eerste start
                    if !seededDemo {
                        let ctx = ModelContext(container)
                        await seedDemo(into: ctx)
                        seededDemo = true
                        demoActive = true
                    }
                }
        }
    }

    @MainActor
    private func seedDemo(into ctx: ModelContext) async {
        // Idempotency: als er al minstens 1 item bestaat, doe niets
        var fd = FetchDescriptor<Item>()
        fd.fetchLimit = 1
        if let existing = try? ctx.fetch(fd), !existing.isEmpty {
            return
        }

        // MARK: - Categorieën
        let catCables = Category(name: "Cables", isDemo: true)
        let catSnacks = Category(name: "Snacks", isDemo: true)
        let catOffice = Category(name: "Office", isDemo: true)
        let catTools = Category(name: "Tools", isDemo: true)
        let catElectronics = Category(name: "Electronics", isDemo: true)

        ctx.insert(catCables)
        ctx.insert(catSnacks)
        ctx.insert(catOffice)
        ctx.insert(catTools)
        ctx.insert(catElectronics)

        // MARK: - Items
        let demoItems: [Item] = [
            Item(
                name: "Ethernet Cable 3 m",
                quantity: 2,
                category: catCables,
                fields: [
                    DynamicField(key: "Color", value: "White"),
                    DynamicField(key: "Length", value: "3 m"),
                    DynamicField(key: "Type", value: "Cat6")
                ],
                isDemo: true
            ),
            Item(
                name: "HDMI Cable 2 m",
                quantity: 1,
                category: catCables,
                fields: [
                    DynamicField(key: "Version", value: "2.1"),
                    DynamicField(key: "Length", value: "2 m")
                ],
                isDemo: true
            ),
            Item(
                name: "Extension Cable 5 m",
                quantity: 3,
                category: catCables,
                fields: [
                    DynamicField(key: "Color", value: "Black"),
                    DynamicField(key: "Outlets", value: "3 sockets")
                ],
                isDemo: true
            ),
            Item(
                name: "Paprika Chips",
                quantity: 2,
                category: catSnacks,
                fields: [
                    DynamicField(key: "Brand", value: "Lay’s"),
                    DynamicField(key: "Contents", value: "200 g")
                ],
                isDemo: true
            ),
            Item(
                name: "Chocolate Bar",
                quantity: 4,
                category: catSnacks,
                fields: [
                    DynamicField(key: "Brand", value: "Côte d’Or"),
                    DynamicField(key: "Type", value: "Milk")
                ],
                isDemo: true
            ),
            Item(
                name: "A5 Notebook",
                quantity: 5,
                category: catOffice,
                fields: [
                    DynamicField(key: "Pages", value: "80"),
                    DynamicField(key: "Color", value: "Blue")
                ],
                isDemo: true
            ),
            Item(
                name: "Blue Ballpoint Pen",
                quantity: 10,
                category: catOffice,
                fields: [
                    DynamicField(key: "Brand", value: "Bic"),
                    DynamicField(key: "Type", value: "Crystal Medium")
                ],
                isDemo: true
            ),
            Item(
                name: "Screwdriver Set",
                quantity: 1,
                category: catTools,
                fields: [
                    DynamicField(key: "Pieces", value: "6-piece"),
                    DynamicField(key: "Type", value: "Phillips & Flat")
                ],
                isDemo: true
            ),
            Item(
                name: "Drill",
                quantity: 1,
                category: catTools,
                fields: [
                    DynamicField(key: "Brand", value: "Bosch"),
                    DynamicField(key: "Power", value: "750 W")
                ],
                isDemo: true
            ),
            Item(
                name: "Power Bank 10,000 mAh",
                quantity: 2,
                category: catElectronics,
                fields: [
                    DynamicField(key: "Brand", value: "Anker"),
                    DynamicField(key: "Color", value: "Black")
                ],
                isDemo: true
            ),
            Item(
                name: "Bluetooth Speaker",
                quantity: 1,
                category: catElectronics,
                fields: [
                    DynamicField(key: "Brand", value: "JBL"),
                    DynamicField(key: "Waterproof", value: "Yes")
                ],
                isDemo: true
            )
        ]

        for item in demoItems { ctx.insert(item) }

        do {
            try ctx.save()
        } catch {
            print("Seed save failed: \(error)")
        }
    }
}

// Handhaaf je Theme enum hier
enum Theme: String, CaseIterable, Codable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
