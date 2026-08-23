import SwiftUI
import UIKit

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    init(light: Color, dark: Color) {
        self.init(
            uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
            }
        )
    }
}

enum SNP {
    static let coral = Color(hex: 0xE85D4C)
    static let coralDeep = Color(hex: 0xC44738)
    static let amber = Color(hex: 0xF4A259)
    static let gold = Color(hex: 0xC9892B)
    static let sage = Color(hex: 0x3D8B6E)
    static let cream = Color(hex: 0xFFF6EE)
    static let sand = Color(hex: 0xF3E4D4)
    static let espresso = Color(hex: 0x2C1810)
    static let espressoSoft = Color(hex: 0x4A2E22)
    static let inkDark = Color(hex: 0x1A100C)
    static let cardDark = Color(hex: 0x2A1C16)

    static let background = Color(light: cream, dark: inkDark)
    static let card = Color(light: .white, dark: cardDark)
    static let sandFill = Color(light: sand, dark: Color(hex: 0x3A281F))
    static let text = Color(light: espresso, dark: cream)
    static let textMuted = Color(light: espressoSoft, dark: Color(hex: 0xE4CDB8))
    static let hairline = Color(light: Color(hex: 0xE8D3C0), dark: Color(hex: 0x4A342A))
    static let youTint = Color(hex: 0x2F6F8F)
}
