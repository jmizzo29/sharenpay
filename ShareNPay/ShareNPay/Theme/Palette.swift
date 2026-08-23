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
    static let accent = Color(hex: 0x2563EB)
    static let accentDeep = Color(hex: 0x1D4ED8)
    static let positive = Color(hex: 0x0F766E)
    static let pending = Color(hex: 0x475569)
    static let youTint = Color(hex: 0x1D4ED8)

    static let background = Color(light: Color(hex: 0xF4F6F8), dark: Color(hex: 0x0B1220))
    static let card = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1E293B))
    static let sandFill = Color(light: Color(hex: 0xE8EDF2), dark: Color(hex: 0x334155))
    static let text = Color(light: Color(hex: 0x0F172A), dark: Color(hex: 0xF8FAFC))
    static let textMuted = Color(light: Color(hex: 0x64748B), dark: Color(hex: 0x94A3B8))
    static let hairline = Color(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x334155))
}
