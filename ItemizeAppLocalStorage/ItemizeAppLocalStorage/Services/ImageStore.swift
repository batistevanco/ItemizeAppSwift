//
//  ImageStore.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//


// File: Services/ImageStore.swift
import UIKit

enum ImageStore {
    static let imagesFolderName = "Images"
    
    static var imagesFolderURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent(imagesFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }
    
    static func saveJPEG(_ image: UIImage, quality: CGFloat = 0.9) throws -> String {
        let name = UUID().uuidString + ".jpg"
        let url = imagesFolderURL.appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw NSError(domain: "ImageStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kon JPEG niet genereren"])
        }
        try data.write(to: url, options: [.atomic])
        return name
    }
    
    static func loadImage(named filename: String) -> UIImage? {
        let url = imagesFolderURL.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }
    
    static func delete(named filename: String) {
        let url = imagesFolderURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}