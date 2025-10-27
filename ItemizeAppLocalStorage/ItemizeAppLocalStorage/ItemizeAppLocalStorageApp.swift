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
        let catCables = Category(name: "Kabels", isDemo: true)
        let catSnacks = Category(name: "Snacks", isDemo: true)
        let catOffice = Category(name: "Kantoor", isDemo: true)
        let catTools = Category(name: "Gereedschap", isDemo: true)
        let catElectronics = Category(name: "Elektronica", isDemo: true)

        ctx.insert(catCables)
        ctx.insert(catSnacks)
        ctx.insert(catOffice)
        ctx.insert(catTools)
        ctx.insert(catElectronics)

        // MARK: - Items
        let demoItems: [Item] = [
            Item(
                name: "Ethernetkabel 3m",
                quantity: 2,
                category: catCables,
                fields: [
                    DynamicField(key: "Kleur", value: "Wit"),
                    DynamicField(key: "Lengte", value: "3 m"),
                    DynamicField(key: "Type", value: "Cat6")
                ],
                isDemo: true
            ),
            Item(
                name: "HDMI-kabel 2m",
                quantity: 1,
                category: catCables,
                fields: [
                    DynamicField(key: "Versie", value: "2.1"),
                    DynamicField(key: "Lengte", value: "2 m")
                ],
                isDemo: true
            ),
            Item(
                name: "Verlengkabel 5m",
                quantity: 3,
                category: catCables,
                fields: [
                    DynamicField(key: "Kleur", value: "Zwart"),
                    DynamicField(key: "Aansluitingen", value: "3x stopcontact")
                ],
                isDemo: true
            ),
            Item(
                name: "Chips Paprika",
                quantity: 2,
                category: catSnacks,
                fields: [
                    DynamicField(key: "Merk", value: "Lay’s"),
                    DynamicField(key: "Inhoud", value: "200 g")
                ],
                isDemo: true
            ),
            Item(
                name: "Chocoladereep",
                quantity: 4,
                category: catSnacks,
                fields: [
                    DynamicField(key: "Merk", value: "Côte d’Or"),
                    DynamicField(key: "Type", value: "Melk")
                ],
                isDemo: true
            ),
            Item(
                name: "Notitieboek A5",
                quantity: 5,
                category: catOffice,
                fields: [
                    DynamicField(key: "Pagina’s", value: "80"),
                    DynamicField(key: "Kleur", value: "Blauw")
                ],
                isDemo: true
            ),
            Item(
                name: "Balpen blauw",
                quantity: 10,
                category: catOffice,
                fields: [
                    DynamicField(key: "Merk", value: "Bic"),
                    DynamicField(key: "Type", value: "Crystal Medium")
                ],
                isDemo: true
            ),
            Item(
                name: "Schroevendraaierset",
                quantity: 1,
                category: catTools,
                fields: [
                    DynamicField(key: "Aantal", value: "6-delig"),
                    DynamicField(key: "Type", value: "Kruiskop & Plat")
                ],
                isDemo: true
            ),
            Item(
                name: "Boormachine",
                quantity: 1,
                category: catTools,
                fields: [
                    DynamicField(key: "Merk", value: "Bosch"),
                    DynamicField(key: "Vermogen", value: "750 W")
                ],
                isDemo: true
            ),
            Item(
                name: "Powerbank 10.000 mAh",
                quantity: 2,
                category: catElectronics,
                fields: [
                    DynamicField(key: "Merk", value: "Anker"),
                    DynamicField(key: "Kleur", value: "Zwart")
                ],
                isDemo: true
            ),
            Item(
                name: "Bluetooth Speaker",
                quantity: 1,
                category: catElectronics,
                fields: [
                    DynamicField(key: "Merk", value: "JBL"),
                    DynamicField(key: "Waterdicht", value: "Ja")
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
