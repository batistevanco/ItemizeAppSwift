//
//  DynamicField.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//


// File: Models/DynamicField.swift
import SwiftData
import Foundation

@Model
final class DynamicField: Identifiable {
    var id: String
    var key: String
    var value: String
    
    init(key: String, value: String) {
        self.id = UUID().uuidString
        self.key = key
        self.value = value
    }
}
