import Foundation

struct AstroEvent: Identifiable {
    let id = UUID()
    let type: AstroEventType
    let title: String
    let description: String
    let startDate: Date?
    let endDate: Date?

    /// Whether this event is currently active
    var isActive: Bool {
        isActiveOn(date: Date())
    }

    /// Check if active on a specific date
    func isActiveOn(date: Date) -> Bool {
        guard let start = startDate else { return false }

        if let end = endDate {
            // Range event (retrograde, transit)
            return date >= start && date <= end
        } else {
            // Single-day event (eclipse) - active within 3 days
            let calendar = Calendar.current
            guard let daysBefore = calendar.date(byAdding: .day, value: -1, to: start),
                  let daysAfter = calendar.date(byAdding: .day, value: 1, to: start) else { return false }
            return date >= daysBefore && date <= daysAfter
        }
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMM"
        return f
    }()

    var dateRangeText: String {
        if let start = startDate, let end = endDate {
            return "\(Self.shortDateFormatter.string(from: start)) - \(Self.shortDateFormatter.string(from: end))"
        } else if let start = startDate {
            return Self.shortDateFormatter.string(from: start)
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
}

struct MoonData {
    let phase: MoonPhase
    let illumination: Double
    let moonrise: String
    let moonset: String
    let age: Double // days since new moon
}
