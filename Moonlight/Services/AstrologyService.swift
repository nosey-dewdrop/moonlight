import Foundation

class AstrologyService {
    private let chartService = HoraryChartService()

    /// Fetches current retrogrades from API + hardcoded eclipse dates (NASA verified, predictable)
    func fetchEvents() async throws -> [AstroEvent] {
        let now = Date()
        var events: [AstroEvent] = []

        // 1. Live retrogrades from FreeAstrologyAPI
        let liveRetrogrades = await fetchLiveRetrogrades()
        events.append(contentsOf: liveRetrogrades)

        // 2. Eclipse dates (NASA data — these are fixed astronomical predictions, not guesses)
        let eclipses = Self.verifiedEclipses()
        let calendar = Calendar.current
        guard let sixMonthsLater = calendar.date(byAdding: .day, value: 180, to: now) else { return events }

        let relevantEclipses = eclipses.filter { event in
            if event.isActiveOn(date: now) { return true }
            if let start = event.startDate, start > now && start <= sixMonthsLater { return true }
            return false
        }
        events.append(contentsOf: relevantEclipses)

        // Sort: active first, then by date
        return events.sorted { a, b in
            if a.isActiveOn(date: now) != b.isActiveOn(date: now) {
                return a.isActiveOn(date: now)
            }
            return (a.startDate ?? .distantFuture) < (b.startDate ?? .distantFuture)
        }
    }

    // MARK: - Live Retrogrades from API

    private func fetchLiveRetrogrades() async -> [AstroEvent] {
        do {
            // Fetch planetary positions for right now
            let chart = try await chartService.fetchChart(latitude: 41.01, longitude: 28.98)

            let retrogradeDescriptions: [String: String] = [
                "Mercury": "Communication and travel may be disrupted",
                "Venus": "Love and relationships under review",
                "Mars": "Energy and motivation may feel blocked",
                "Jupiter": "Growth and expansion slow down for reflection",
                "Saturn": "Time to revisit structures and responsibilities",
                "Uranus": "Inner rebellion, rethinking freedom",
                "Neptune": "Spiritual fog, illusions dissolving",
                "Pluto": "Deep transformation beneath the surface",
            ]

            return chart.planets
                .filter { $0.isRetro && retrogradeDescriptions.keys.contains($0.name) }
                .map { planet in
                    AstroEvent(
                        type: .retrograde,
                        title: "\(planet.name) Retrograde",
                        description: retrogradeDescriptions[planet.name] ?? "Planet in retrograde motion",
                        startDate: Date(),
                        endDate: nil
                    )
                }
        } catch {
            print("Failed to fetch live retrogrades: \(error)")
            return []
        }
    }

    // MARK: - Verified Eclipse Dates (NASA/USNO data — fixed predictions)

    private static func verifiedEclipses() -> [AstroEvent] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"

        return [
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

            // Solar Eclipses 2027
            AstroEvent(type: .eclipse, title: "Total Solar Eclipse",
                       description: "Total solar eclipse, major life shift",
                       startDate: f.date(from: "2027-02-06"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Annular Solar Eclipse",
                       description: "Ring of fire, new cycles begin",
                       startDate: f.date(from: "2027-08-02"), endDate: nil),

            // Lunar Eclipses 2027
            AstroEvent(type: .eclipse, title: "Penumbral Lunar Eclipse",
                       description: "Subtle shifts in emotional landscape",
                       startDate: f.date(from: "2027-02-20"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Penumbral Lunar Eclipse",
                       description: "Inner tides gently turning",
                       startDate: f.date(from: "2027-07-18"), endDate: nil),
        ]
    }
}
