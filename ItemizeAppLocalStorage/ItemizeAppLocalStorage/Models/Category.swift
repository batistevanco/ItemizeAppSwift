//
//  Category.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//


// File: Models/Category.swift
import SwiftData
import Foundation

@Model
final class Category: Identifiable {
    @Attribute(.unique) var id: String
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .cascade) var items: [Item] = []
    
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @Attribute var isDemo: Bool = false

        init(name: String, isDemo: Bool = false) {
            self.id = UUID().uuidString
            self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.isDemo = isDemo
        }
}
