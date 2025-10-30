// File: Persistence/ModelContainerProvider.swift
import SwiftData

@MainActor
final class ModelContainerProvider {
    static let shared = ModelContainerProvider()
    let container: ModelContainer

    init() {
        let schema = Schema([
            Item.self,
            Category.self,
            DynamicField.self,
            ImageAsset.self,
            Tag.self
        ])

        do {
            // Gewoon lokaal opslaan — geen iCloud of CloudKit
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
