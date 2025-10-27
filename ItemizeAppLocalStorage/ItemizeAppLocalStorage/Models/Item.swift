//
//  Item.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//


// File: Models/Item.swift
import SwiftData
import Foundation

@Model
final class Item: Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var quantity: Int
    @Relationship(deleteRule: .nullify, inverse: \Category.items) var category: Category?
    @Relationship(deleteRule: .cascade) var fields: [DynamicField]
    @Relationship(deleteRule: .cascade) var image: ImageAsset?
    var createdAt: Date
    
    init(name: String, quantity: Int = 1, category: Category? = nil, fields: [DynamicField] = [], image: ImageAsset? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.quantity = quantity
        self.category = category
        self.fields = fields
        self.image = image
        self.createdAt = .now
    }
    
        @Attribute var isDemo: Bool = false

        init(name: String, quantity: Int = 1, category: Category? = nil, fields: [DynamicField] = [], image: ImageAsset? = nil, isDemo: Bool = false) {
            self.id = UUID().uuidString
            self.name = name
            self.quantity = quantity
            self.category = category
            self.fields = fields
            self.image = image
            self.isDemo = isDemo
            self.createdAt = Date()
        }
    
}


