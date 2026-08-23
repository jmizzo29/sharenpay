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
    /// Quiet ink. The only accent.
    static let accent = Color(hex: 0x1B2A4A)
    static let accentDeep = Color(hex: 0x1B2A4A)
    static let youTint = Color(hex: 0x1B2A4A)

    static let background = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x0A0A0A))
    static let card = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x0A0A0A))
    static let fill = Color(light: Color(hex: 0xF6F6F6), dark: Color(hex: 0x1A1A1A))
    static let sandFill = fill
    static let text = Color(light: Color(hex: 0x111111), dark: Color(hex: 0xF5F5F5))
    static let textMuted = Color(light: Color(hex: 0x6A6A6A), dark: Color(hex: 0x9A9A9A))
    static let hairline = Color(light: Color(hex: 0xE6E6E6), dark: Color(hex: 0x2A2A2A))
    static let pending = textMuted
    static let positive = text

    static func money(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static let spring = Animation.spring(response: 0.34, dampingFraction: 0.88)
}
