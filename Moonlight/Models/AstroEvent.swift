import Foundation

struct AstroEvent: Identifiable {
    let id = UUID()
    let type: AstroEventType
    let title: String
    let description: String
    let startDate: Date?
    let endDate: Date?
    let isActive: Bool

    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"

        if let start = startDate, let end = endDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let start = startDate {
            return formatter.string(from: start)
        }
        return ""
    }
}

enum AstroEventType: String {
    case retrograde
    case transit
    case eclipse
    case conjunction
    case opposition

    var icon: String {
        switch self {
        case .retrograde: return "arrow.uturn.backward.circle"
        case .transit: return "arrow.right.circle"
        case .eclipse: return "circle.lefthalf.filled"
        case .conjunction: return "circle.grid.2x1"
        case .opposition: return "arrow.left.arrow.right.circle"
        }
    }

    var color: String {
        switch self {
        case .retrograde: return "#FF6B6B"
        case .transit: return "#A78BFA"
        case .eclipse: return "#FBBF24"
        case .conjunction: return "#34D399"
        case .opposition: return "#F472B6"
        }
    }
}

struct MoonData {
    let phase: MoonPhase
    let illumination: Double
    let moonrise: String
    let moonset: String
    let age: Double // days since new moon
}
