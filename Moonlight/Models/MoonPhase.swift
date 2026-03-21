import Foundation

enum MoonPhase: String, CaseIterable, Identifiable {
    case newMoon = "new_moon"
    case waxingCrescent = "waxing_crescent"
    case firstQuarter = "first_quarter"
    case waxingGibbous = "waxing_gibbous"
    case fullMoon = "full_moon"
    case waningGibbous = "waning_gibbous"
    case lastQuarter = "last_quarter"
    case waningCrescent = "waning_crescent"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newMoon: return "New Moon"
        case .waxingCrescent: return "Waxing Crescent"
        case .firstQuarter: return "First Quarter"
        case .waxingGibbous: return "Waxing Gibbous"
        case .fullMoon: return "Full Moon"
        case .waningGibbous: return "Waning Gibbous"
        case .lastQuarter: return "Last Quarter"
        case .waningCrescent: return "Waning Crescent"
        }
    }

    var emoji: String {
        switch self {
        case .newMoon: return "🌑"
        case .waxingCrescent: return "🌒"
        case .firstQuarter: return "🌓"
        case .waxingGibbous: return "🌔"
        case .fullMoon: return "🌕"
        case .waningGibbous: return "🌖"
        case .lastQuarter: return "🌗"
        case .waningCrescent: return "🌘"
        }
    }

    /// Illumination range for each phase (approximate)
    var illuminationRange: ClosedRange<Double> {
        switch self {
        case .newMoon: return 0...0.02
        case .waxingCrescent: return 0.02...0.48
        case .firstQuarter: return 0.48...0.52
        case .waxingGibbous: return 0.52...0.98
        case .fullMoon: return 0.98...1.0
        case .waningGibbous: return 0.52...0.98
        case .lastQuarter: return 0.48...0.52
        case .waningCrescent: return 0.02...0.48
        }
    }

    /// Background gradient colors for the scene
    var sceneColors: [String] {
        switch self {
        case .newMoon:
            return ["#0a0a1a", "#141432", "#1a1a3e"]
        case .waxingCrescent, .waningCrescent:
            return ["#0d1025", "#1a1a4a", "#252560"]
        case .firstQuarter, .lastQuarter:
            return ["#101030", "#1e1e55", "#2a2a6e"]
        case .waxingGibbous, .waningGibbous:
            return ["#121240", "#222266", "#303080"]
        case .fullMoon:
            return ["#151550", "#282878", "#3a3a90"]
        }
    }

    /// Moon fill fraction (0 = new, 1 = full)
    var fillFraction: Double {
        switch self {
        case .newMoon: return 0.0
        case .waxingCrescent: return 0.25
        case .firstQuarter: return 0.5
        case .waxingGibbous: return 0.75
        case .fullMoon: return 1.0
        case .waningGibbous: return 0.75
        case .lastQuarter: return 0.5
        case .waningCrescent: return 0.25
        }
    }

    /// Whether the lit side is on the right (waxing) or left (waning)
    var isWaxing: Bool {
        switch self {
        case .newMoon, .waxingCrescent, .firstQuarter, .waxingGibbous, .fullMoon:
            return true
        case .waningGibbous, .lastQuarter, .waningCrescent:
            return false
        }
    }

    /// Map USNO API phase name to enum
    static func fromAPIName(_ name: String) -> MoonPhase? {
        let lower = name.lowercased()
        if lower.contains("new") { return .newMoon }
        if lower.contains("full") { return .fullMoon }
        if lower.contains("first") { return .firstQuarter }
        if lower.contains("last") || lower.contains("third") { return .lastQuarter }
        if lower.contains("waxing") && lower.contains("crescent") { return .waxingCrescent }
        if lower.contains("waxing") && lower.contains("gibbous") { return .waxingGibbous }
        if lower.contains("waning") && lower.contains("crescent") { return .waningCrescent }
        if lower.contains("waning") && lower.contains("gibbous") { return .waningGibbous }
        return nil
    }

    /// Determine moon phase from illumination percentage and whether waxing
    static func from(illumination: Double, isWaxing: Bool) -> MoonPhase {
        let pct = illumination / 100.0
        if pct < 0.02 { return .newMoon }
        if pct > 0.98 { return .fullMoon }
        if isWaxing {
            if pct < 0.48 { return .waxingCrescent }
            if pct < 0.52 { return .firstQuarter }
            return .waxingGibbous
        } else {
            if pct < 0.48 { return .waningCrescent }
            if pct < 0.52 { return .lastQuarter }
            return .waningGibbous
        }
    }
}
