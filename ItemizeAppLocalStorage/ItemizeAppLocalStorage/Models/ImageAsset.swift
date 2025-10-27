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
    
    init(filename: String) {
        self.id = UUID().uuidString
        self.filename = filename
    }
}
