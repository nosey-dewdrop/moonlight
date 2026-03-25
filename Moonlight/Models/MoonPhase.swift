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
        case .newMoon: return "Yeni Ay"
        case .waxingCrescent: return "İlk Hilal"
        case .firstQuarter: return "İlk Dördün"
        case .waxingGibbous: return "Şişkin Ay"
        case .fullMoon: return "Dolunay"
        case .waningGibbous: return "Küçülen Ay"
        case .lastQuarter: return "Son Dördün"
        case .waningCrescent: return "Son Hilal"
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
