//
//  Tag.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 30/10/2025.
//


// File: Models/Tag.swift
import Foundation
import SwiftData

@Model
final class Tag: Identifiable {
    @Attribute(.unique) var id: String
    @Attribute(.unique) var name: String
    @Relationship(inverse: \Item.tags) var items: [Item] = []

    init(name: String) {
        self.id = UUID().uuidString
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}