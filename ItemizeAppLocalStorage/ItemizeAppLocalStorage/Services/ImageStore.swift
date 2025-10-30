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
    
    /// Clone an existing image file to a new unique filename and return the new filename
    @discardableResult
    static func clone(filename: String) throws -> String {
        guard !filename.isEmpty, !filename.contains("/") else {
            throw NSError(domain: "ImageStore", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid filename"])
        }
        let srcURL = imagesFolderURL.appendingPathComponent(filename, isDirectory: false)
        let ext = (filename as NSString).pathExtension
        let newName = "IMG-" + UUID().uuidString + (ext.isEmpty ? ".jpg" : "." + ext)
        let dstURL = imagesFolderURL.appendingPathComponent(newName, isDirectory: false)
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
        return newName
    }
    
    static func loadImage(named filename: String) -> UIImage? {
        let url = imagesFolderURL.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }
    
    static func delete(named filename: String) {
        // Only accept plain filenames (no path traversal)
        guard !filename.isEmpty, !filename.contains("/") else { return }
        let url = imagesFolderURL.appendingPathComponent(filename, isDirectory: false)
        let fm = FileManager.default
        // Remove only if it exists and is a regular file
        guard fm.fileExists(atPath: url.path) else { return }
        do {
            let attrs = try fm.attributesOfItem(atPath: url.path)
            if (attrs[.type] as? FileAttributeType) == .typeRegular {
                try fm.removeItem(at: url)
            }
        } catch {
            // Ignore I/O errors; UI state already updated
        }
    }
    
    /// Ensure each ImageAsset in the list points to a unique file on disk.
    /// If multiple assets share the same filename, later ones are cloned to a new file
    /// and their `filename` is updated in-place.
    static func deduplicateFilenames(for assets: [ImageAsset]) {
        var seen = Set<String>()
        for asset in assets {
            let fname = asset.filename
            if seen.contains(fname) {
                if let cloned = try? clone(filename: fname) {
                    asset.filename = cloned
                    seen.insert(cloned)
                }
            } else {
                seen.insert(fname)
            }
        }
    }
}
