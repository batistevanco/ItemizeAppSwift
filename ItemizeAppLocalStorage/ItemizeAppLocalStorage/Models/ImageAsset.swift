//
//  ImageAsset.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//

// File: Models/ImageAsset.swift
import SwiftData
import Foundation

@Model
final class ImageAsset: Identifiable {
    var id: String
    /// Bestandsnaam in de app's Documents/Images map
    var filename: String
    /// Optionele volgorde (gebruikt voor sortering)
    var order: Int?
    /// Aanmaakdatum, handig voor sortering
    var createdAt: Date
    
    init(filename: String, order: Int? = nil) {
        self.id = UUID().uuidString
        self.filename = filename
        self.order = order
        self.createdAt = Date()
    }
}
