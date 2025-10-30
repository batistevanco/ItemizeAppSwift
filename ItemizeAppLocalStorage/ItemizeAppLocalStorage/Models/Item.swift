// File: Models/Item.swift
import Foundation
import SwiftData

@Model
final class Item: Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var quantity: Int
    @Relationship var category: Category?
    @Relationship var fields: [DynamicField] = []
    @Relationship var images: [ImageAsset] = []

    /// Eerste/primary image obv `order` (val terug op insert-volgorde)
    var primaryImage: ImageAsset? {
        images.sorted { ($0.order ?? 0) < ($1.order ?? 0) }.first
    }

    // NIEUW
    @Relationship var tags: [Tag] = []
    @Attribute var isFavorite: Bool = false
    @Attribute var accessCount: Int = 0
    @Attribute var lastAccessedAt: Date?
    @Attribute var createdAt: Date = Date()

    @Attribute var isDemo: Bool = false

    init(name: String,
         quantity: Int = 1,
         category: Category? = nil,
         fields: [DynamicField] = [],
         images: [ImageAsset] = [],
         tags: [Tag] = [],
         isFavorite: Bool = false,
         isDemo: Bool = false)
    {
        self.id = UUID().uuidString
        self.name = name
        self.quantity = quantity
        self.category = category
        self.fields = fields
        self.images = images
        self.tags = tags
        self.isFavorite = isFavorite
        self.isDemo = isDemo
        self.createdAt = Date()
    }

    func bumpUsage() {
        accessCount += 1
        lastAccessedAt = Date()
    }
}
