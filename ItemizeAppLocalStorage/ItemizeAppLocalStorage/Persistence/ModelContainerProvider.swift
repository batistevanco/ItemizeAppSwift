//
//  ModelContainerProvider.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//

// File: Persistence/ModelContainerProvider.swift
import SwiftData

final class ModelContainerProvider {
    static let shared = ModelContainerProvider()
    let container: ModelContainer
    init() {
        do {
            container = try ModelContainer(for:
            Item.self, Category.self, DynamicField.self, ImageAsset.self
            )
        } catch {
            fatalError("Kon ModelContainer niet maken: \(error)")
        }
    }
}
