import Foundation

class AstrologyService {
    /// Returns current/upcoming astrological events
    /// For now uses hardcoded data - will integrate Prokerala API later
    func fetchEvents() async throws -> [AstroEvent] {
        // Hardcoded current events for demo
        // These will be replaced with Prokerala API data
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return [
            AstroEvent(
                type: .retrograde,
                title: "Mercury Retrograde",
                description: "Communication and travel may be disrupted",
                startDate: formatter.date(from: "2026-03-02"),
                endDate: formatter.date(from: "2026-03-25"),
                isActive: true
            ),
            AstroEvent(
                type: .transit,
                title: "Venus in Aries",
                description: "Bold and passionate energy in love",
                startDate: formatter.date(from: "2026-03-10"),
                endDate: formatter.date(from: "2026-04-05"),
                isActive: true
            ),
            AstroEvent(
                type: .transit,
                title: "Jupiter in Gemini",
                description: "Expansion in communication and learning",
                startDate: formatter.date(from: "2025-05-25"),
                endDate: formatter.date(from: "2026-06-09"),
                isActive: true
            ),
            AstroEvent(
                type: .eclipse,
                title: "Lunar Eclipse",
                description: "Full moon eclipse in Virgo",
                startDate: formatter.date(from: "2026-03-28"),
                endDate: nil,
                isActive: false
            ),
            AstroEvent(
                type: .retrograde,
                title: "Saturn Retrograde",
                description: "Time to revisit structures and responsibilities",
                startDate: formatter.date(from: "2026-04-15"),
                endDate: formatter.date(from: "2026-09-01"),
                isActive: false
            )
        ]
    }
}
