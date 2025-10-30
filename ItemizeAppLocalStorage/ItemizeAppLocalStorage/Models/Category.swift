// File: Models/Category.swift
import Foundation
import SwiftData

@Model
final class Category: Identifiable {
    @Attribute(.unique) var id: String
    @Attribute(.unique) var name: String

    // Hiërarchie
    @Relationship(deleteRule: .nullify) var parent: Category?
    @Relationship(deleteRule: .cascade, inverse: \Category.parent) var children: [Category] = []

    // Optioneel voor demodata
    @Attribute var isDemo: Bool = false

    init(name: String, parent: Category? = nil, isDemo: Bool = false) {
        self.id = UUID().uuidString
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.parent = parent
        self.isDemo = isDemo
    }

    var breadcrumb: String {
        // "Kabels > Netwerk" bv.
        var chain: [String] = [self.name]
        var p = parent
        while let x = p {
            chain.append(x.name)
            p = x.parent
        }
        return chain.reversed().joined(separator: " > ")
    }
}
