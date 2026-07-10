import SwiftUI

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme (fab.bio-style cosmic-minimal system)
//
// The visual language: flat editorial ink (near-black), generous whitespace,
// hairline borders, one restrained champagne-gold accent, and a small lilac/
// teal reserved for chart data (planets, aspects). No heavy gradients — this is
// a serious astrology instrument, not a purple fortune-toy. Type is system-
// native: New York (serif) for editorial display moments, SF Pro for UI, so it
// scales with Dynamic Type and the TR locale with zero bundled assets. Damla's
// hand-drawn illustrations layer on top later; nothing here waits on them.

enum Theme {

    // MARK: Palette

    // Original pixel-era palette (restored — pixel art assets live on this)
    static let bg = Color(hex: "#0b0b2e")
    static let bgDeep = Color(hex: "#08081F")      // gradient stop for new screens
    static let bgRaised = Color(hex: "#131336")    // raised surface for new screens
    static let bgViolet = Color(hex: "#1A1145")
    static let bgPlum = Color(hex: "#2D1B54")

    static let accent = Color(hex: "#FFE566")
    static let accentDeep = Color(hex: "#E6C878")
    static let lilac = Color(hex: "#C9B6FF")
    static let rose = Color(hex: "#F5B8D0")
    static let aurora = Color(hex: "#8FE3D0")
    static let error = Color(hex: "#FF6B6B")

    static let text = Color(hex: "#F4F1FF")
    static let textMuted = Color(hex: "#B8B0D8")
    static let textFaint = Color(hex: "#7A749C")

    static let cardBg = Color(hex: "#12123a")
    static let cardBorder = Color(hex: "#2a2a5e")
    static let cardOuterBorder = Color(hex: "#1e1e4e")
    static let badgeBg = Color(hex: "#1a1a4a")
    static let badgeBorder = Color(hex: "#2a2a6e")
    static let hairline = Color.white.opacity(0.10)
    static let coinInner = Color(hex: "#D4A017")
    static let purpleAccent = Color(hex: "#A78BFA")
    static let green = Color(hex: "#34D399")

    // MARK: Gradients (used sparingly)

    /// Very subtle top-down deepening — almost flat, just avoids a dead-flat wall.
    static let skyGradient = LinearGradient(
        colors: [bgDeep, bg],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Champagne fill for the single primary CTA.
    static let goldGradient = LinearGradient(
        colors: [Color(hex: "#F0E4C4"), accent, accentDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Reserved lilac→rose for premium / love surfaces (synastry).
    static let auraGradient = LinearGradient(
        colors: [lilac, rose],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Fonts (Fraunces serif titles + Inter body — no pixel type)
    //
    // Readable, non-pixel typography per Damla's call: Fraunces SemiBold gives
    // titles editorial character, Inter carries body and buttons. All three
    // files are static instances generated from the Google Fonts variable
    // fonts (iOS can't resolve variable-font named instances by name), full
    // Turkish glyph coverage verified. Pixel fonts are gone from the bundle.
    static let titleFont = "Fraunces-SemiBold"
    static let bodyFont = "Inter-Regular"
    static let bodyBoldFont = "Inter-SemiBold"
    static let buttonFont = "Inter-SemiBold"

    /// Serif display — big editorial moments: chart headline, degrees, reveals.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Clean sans body — the default UI voice.
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Sans UI — buttons, tab labels, badges (tight, confident).
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // MARK: Layout tokens

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 26
        static let pill: CGFloat = 100
    }

    enum Space {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 28
        static let xl: CGFloat = 40
    }

    // MARK: Shared DateFormatters — NEVER create in body or computed properties

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMM"
        return f
    }()

    static let historyDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMM, HH:mm"
        return f
    }()

    static let posixDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
