import Foundation

class AstrologyService {
    /// Returns current and upcoming astrological events based on real astronomical data
    func fetchEvents() async throws -> [AstroEvent] {
        let now = Date()
        let allEvents = Self.astronomicalEvents2025_2026()

        // Show active events + upcoming events within 60 days
        let calendar = Calendar.current
        let sixtyDaysLater = calendar.date(byAdding: .day, value: 180, to: now)!

        return allEvents.filter { event in
            // Active now
            if event.isActiveOn(date: now) { return true }
            // Starting within 60 days
            if let start = event.startDate, start > now && start <= sixtyDaysLater { return true }
            return false
        }
        .sorted { a, b in
            // Active first, then by start date
            if a.isActiveOn(date: now) != b.isActiveOn(date: now) {
                return a.isActiveOn(date: now)
            }
            return (a.startDate ?? .distantFuture) < (b.startDate ?? .distantFuture)
        }
    }

    // MARK: - Real Astronomical Data 2025-2026

    private static func astronomicalEvents2025_2026() -> [AstroEvent] {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"

        return [
            // Mercury Retrogrades 2025
            AstroEvent(type: .retrograde, title: "Mercury Retrograde",
                       description: "Communication and travel may be disrupted",
                       startDate: f.date(from: "2025-03-15"), endDate: f.date(from: "2025-04-07")),
            AstroEvent(type: .retrograde, title: "Mercury Retrograde",
                       description: "Communication and travel may be disrupted",
                       startDate: f.date(from: "2025-07-18"), endDate: f.date(from: "2025-08-11")),
            AstroEvent(type: .retrograde, title: "Mercury Retrograde",
                       description: "Communication and travel may be disrupted",
                       startDate: f.date(from: "2025-11-09"), endDate: f.date(from: "2025-11-29")),

            // Mercury Retrogrades 2026
            AstroEvent(type: .retrograde, title: "Mercury Retrograde",
                       description: "Communication and travel may be disrupted",
                       startDate: f.date(from: "2026-02-26"), endDate: f.date(from: "2026-03-20")),
            AstroEvent(type: .retrograde, title: "Mercury Retrograde",
                       description: "Communication and travel may be disrupted",
                       startDate: f.date(from: "2026-06-29"), endDate: f.date(from: "2026-07-23")),
            AstroEvent(type: .retrograde, title: "Mercury Retrograde",
                       description: "Communication and travel may be disrupted",
                       startDate: f.date(from: "2026-10-24"), endDate: f.date(from: "2026-11-13")),

            // Venus Retrograde
            AstroEvent(type: .retrograde, title: "Venus Retrograde",
                       description: "Love and relationships under review",
                       startDate: f.date(from: "2025-03-01"), endDate: f.date(from: "2025-04-12")),
            AstroEvent(type: .retrograde, title: "Venus Retrograde",
                       description: "Love and relationships under review",
                       startDate: f.date(from: "2026-10-03"), endDate: f.date(from: "2026-11-14")),

            // Jupiter Retrograde
            AstroEvent(type: .retrograde, title: "Jupiter Retrograde",
                       description: "Growth and expansion slow down for reflection",
                       startDate: f.date(from: "2025-11-11"), endDate: f.date(from: "2026-03-10")),
            AstroEvent(type: .retrograde, title: "Jupiter Retrograde",
                       description: "Growth and expansion slow down for reflection",
                       startDate: f.date(from: "2026-12-12"), endDate: f.date(from: "2027-04-12")),

            // Saturn Retrograde
            AstroEvent(type: .retrograde, title: "Saturn Retrograde",
                       description: "Time to revisit structures and responsibilities",
                       startDate: f.date(from: "2025-07-12"), endDate: f.date(from: "2025-11-27")),
            AstroEvent(type: .retrograde, title: "Saturn Retrograde",
                       description: "Time to revisit structures and responsibilities",
                       startDate: f.date(from: "2026-07-26"), endDate: f.date(from: "2026-12-10")),

            // Solar Eclipses 2025
            AstroEvent(type: .eclipse, title: "Partial Solar Eclipse",
                       description: "Solar eclipse, new beginnings",
                       startDate: f.date(from: "2025-03-29"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Partial Solar Eclipse",
                       description: "Solar eclipse, fresh starts",
                       startDate: f.date(from: "2025-09-21"), endDate: nil),

            // Lunar Eclipses 2025
            AstroEvent(type: .eclipse, title: "Total Lunar Eclipse",
                       description: "Full moon eclipse, emotional release",
                       startDate: f.date(from: "2025-03-14"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Total Lunar Eclipse",
                       description: "Full moon eclipse, inner transformation",
                       startDate: f.date(from: "2025-09-07"), endDate: nil),

            // Solar Eclipses 2026
            AstroEvent(type: .eclipse, title: "Annular Solar Eclipse",
                       description: "Ring of fire eclipse, powerful new cycle",
                       startDate: f.date(from: "2026-02-17"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Total Solar Eclipse",
                       description: "Total solar eclipse, major transformation",
                       startDate: f.date(from: "2026-08-12"), endDate: nil),

            // Lunar Eclipses 2026
            AstroEvent(type: .eclipse, title: "Total Lunar Eclipse",
                       description: "Full moon eclipse, deep emotional shifts",
                       startDate: f.date(from: "2026-03-03"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Partial Lunar Eclipse",
                       description: "Partial eclipse, subtle inner changes",
                       startDate: f.date(from: "2026-08-28"), endDate: nil),
        ]
    }
}
