import SwiftUI

enum Theme {
    enum Palette {
        static let ink     = Color(hex: 0x1F1D1A)
        static let ink2    = Color(hex: 0x3A3733)
        static let paper   = Color(hex: 0xF6F1E6)
        static let paper2  = Color(hex: 0xEFE8D6)
        static let muted   = Color(hex: 0x7C766C)

        static let accentRed    = Color(hex: 0xFF6B6B)
        static let accentYellow = Color(hex: 0xFFD23F)
        static let accentTeal   = Color(hex: 0x4EC3A8)
        static let accentBlue   = Color(hex: 0x5BA8E0)
        static let accentPurple = Color(hex: 0xC89BF2)
        static let accentPeach  = Color(hex: 0xF7A072)

        static let crayonPalette: [Color] = [
            accentRed, accentYellow, accentTeal, accentBlue,
            accentPurple, accentPeach, ink, .white
        ]
    }

    enum Fonts {
        // Bundle Caveat & PatrickHand .ttfs into Resources and register in Info.plist.
        static func caveat(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            Font.custom("Caveat", size: size).weight(weight)
        }
        static func hand(_ size: CGFloat) -> Font {
            Font.custom("PatrickHand-Regular", size: size)
        }
    }

    /// Hard offset shadow used everywhere (4pt right, 4pt down, ink, no blur).
    static let hardShadow = ShadowSpec(color: Palette.ink, x: 4, y: 4)
}

struct ShadowSpec {
    let color: Color
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func hardShadow(_ spec: ShadowSpec = Theme.hardShadow) -> some View {
        shadow(color: spec.color, radius: 0, x: spec.x, y: spec.y)
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
