import SwiftUI

extension Color {
    static let deepGreen   = Color(hex: "#294D48")
    static let tealGreen   = Color(hex: "#1A6E63")
    static let softGreen   = Color(hex: "#B2C9AB")
    static let sandBeige   = Color(hex: "#E8DDB5")
    static let paleCream   = Color(hex: "#FCF0C5")
    
    /// Gebruik deze initializer om hex-kleuren te ondersteunen
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: .whitespacesAndNewlines))
        var hexNumber: UInt64 = 0
        
        // Verwijder eventueel het #-teken
        if hex.hasPrefix("#") {
            _ = scanner.scanString("#")
        }
        
        scanner.scanHexInt64(&hexNumber)
        
        let r = Double((hexNumber & 0xFF0000) >> 16) / 255
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255
        let b = Double(hexNumber & 0x0000FF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}
