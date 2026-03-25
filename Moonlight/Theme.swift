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

// MARK: - Theme Constants

enum Theme {
    // Colors - cached static, no repeated hex parsing
    static let bg = Color(hex: "#0b0b2e")
    static let accent = Color(hex: "#FFE566")
    static let error = Color(hex: "#FF6B6B")
    static let cardBg = Color(hex: "#12123a")
    static let cardBorder = Color(hex: "#2a2a5e")
    static let cardOuterBorder = Color(hex: "#1e1e4e")
    static let badgeBg = Color(hex: "#1a1a4a")
    static let badgeBorder = Color(hex: "#2a2a6e")
    static let coinInner = Color(hex: "#D4A017")
    static let purpleAccent = Color(hex: "#A78BFA")
    static let green = Color(hex: "#34D399")

    // Fonts
    static let titleFont = "PressStart2P-Regular"
    static let bodyFont = "PixelifySans-Regular"
    static let bodyBoldFont = "PixelifySans-SemiBold"
    static let buttonFont = "Silkscreen-Bold"

    // Shared DateFormatters - NEVER create in body or computed properties
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
