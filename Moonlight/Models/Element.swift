import SwiftUI

enum Element: String, CaseIterable, Codable {
    case fire
    case earth
    case air
    case water

    var color: Color {
        switch self {
        case .fire: return Color(hex: "#FF6B6B")
        case .earth: return Color(hex: "#34D399")
        case .air: return Color(hex: "#A78BFA")
        case .water: return Color(hex: "#60A5FA")
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var zodiacSigns: [String] {
        switch self {
        case .fire: return ["Aries", "Leo", "Sagittarius"]
        case .earth: return ["Taurus", "Virgo", "Capricorn"]
        case .air: return ["Gemini", "Libra", "Aquarius"]
        case .water: return ["Cancer", "Scorpio", "Pisces"]
        }
    }

    var tarotSuit: Suit {
        switch self {
        case .fire: return .wands
        case .earth: return .pentacles
        case .air: return .swords
        case .water: return .cups
        }
    }

    /// Base energy level for this element given the current moon phase
    static func energyLevels(for moonPhase: MoonPhase) -> [Element: Double] {
        switch moonPhase {
        case .newMoon:
            return [.fire: 0.3, .earth: 0.9, .air: 0.4, .water: 0.5]
        case .waxingCrescent:
            return [.fire: 0.5, .earth: 0.7, .air: 0.5, .water: 0.6]
        case .firstQuarter:
            return [.fire: 0.7, .earth: 0.5, .air: 0.7, .water: 0.5]
        case .waxingGibbous:
            return [.fire: 0.8, .earth: 0.4, .air: 0.8, .water: 0.7]
        case .fullMoon:
            return [.fire: 0.6, .earth: 0.3, .air: 0.6, .water: 1.0]
        case .waningGibbous:
            return [.fire: 0.5, .earth: 0.5, .air: 0.7, .water: 0.8]
        case .lastQuarter:
            return [.fire: 0.4, .earth: 0.6, .air: 0.6, .water: 0.6]
        case .waningCrescent:
            return [.fire: 0.3, .earth: 0.8, .air: 0.4, .water: 0.7]
        }
    }

    /// Adjust element energies based on active retrogrades
    static func adjustedEnergies(for moonPhase: MoonPhase, activeRetrogrades: [String]) -> [Element: Double] {
        var levels = energyLevels(for: moonPhase)

        for retro in activeRetrogrades {
            let lower = retro.lowercased()
            if lower.contains("mercury") {
                // Mercury retrograde weakens air, boosts water (introspection)
                levels[.air, default: 0.5] -= 0.15
                levels[.water, default: 0.5] += 0.1
            } else if lower.contains("venus") {
                // Venus retrograde weakens earth (material), boosts water (emotions)
                levels[.earth, default: 0.5] -= 0.1
                levels[.water, default: 0.5] += 0.15
            } else if lower.contains("jupiter") {
                // Jupiter retrograde weakens fire (expansion), boosts earth (grounding)
                levels[.fire, default: 0.5] -= 0.15
                levels[.earth, default: 0.5] += 0.1
            } else if lower.contains("saturn") {
                // Saturn retrograde weakens earth (structure), boosts air (questioning)
                levels[.earth, default: 0.5] -= 0.1
                levels[.air, default: 0.5] += 0.15
            }
        }

        // Clamp values
        for element in Element.allCases {
            levels[element] = min(1.0, max(0.1, levels[element, default: 0.5]))
        }

        return levels
    }
}
