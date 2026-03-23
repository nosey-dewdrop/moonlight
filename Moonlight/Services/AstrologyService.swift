import Foundation

class AstrologyService {
    private let chartService = HoraryChartService()

    /// Fetches upcoming cosmic events within 2 weeks
    func fetchEvents() async throws -> [AstroEvent] {
        let now = Date()
        let calendar = Calendar.current
        guard let twoWeeksLater = calendar.date(byAdding: .day, value: 14, to: now) else { return [] }

        var events: [AstroEvent] = []

        // 1. Live retrogrades from FreeAstrologyAPI
        let liveRetrogrades = await fetchLiveRetrogrades()
        events.append(contentsOf: liveRetrogrades)

        // 2. Upcoming moon phases (local calculation)
        let moonPhaseEvents = Self.upcomingMoonPhases(from: now, within: 14)
        events.append(contentsOf: moonPhaseEvents)

        // 3. Eclipses within 2 weeks (NASA verified)
        let eclipses = Self.verifiedEclipses().filter { event in
            guard let start = event.startDate else { return false }
            return start > now && start <= twoWeeksLater
        }
        events.append(contentsOf: eclipses)

        // Sort by date
        return events.sorted { a, b in
            return (a.startDate ?? .distantFuture) < (b.startDate ?? .distantFuture)
        }
    }

    // MARK: - Upcoming Moon Phases

    private static func upcomingMoonPhases(from date: Date, within days: Int) -> [AstroEvent] {
        let synodicMonth = 29.53058868
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)

        guard let year = components.year, let month = components.month,
              let day = components.day, let hour = components.hour else { return [] }

        var y = year, m = month
        if m <= 2 { y -= 1; m += 12 }
        let a = y / 100
        let b = a / 4
        let c = 2 - a + b
        let e = Int(365.25 * Double(y + 4716))
        let f = Int(30.6001 * Double(m + 1))
        let jd = Double(c + day + e + f) + Double(hour) / 24.0 - 1524.5

        let daysSinceNew = jd - 2451550.1
        let age = daysSinceNew.truncatingRemainder(dividingBy: synodicMonth)
        let currentAge = age < 0 ? age + synodicMonth : age

        // Major phases at these ages: New=0, First Quarter=7.38, Full=14.77, Last Quarter=22.15
        let phases: [(name: String, age: Double, icon: String, desc: String)] = [
            ("New Moon", 0, "new_moon", "New cycle begins, set intentions"),
            ("Full Moon", 14.77, "full_moon", "Harvest, clarity, release"),
        ]

        var events: [AstroEvent] = []
        for phase in phases {
            var daysUntil = phase.age - currentAge
            if daysUntil < 0 { daysUntil += synodicMonth }
            if daysUntil > 0 && daysUntil <= Double(days) {
                if let phaseDate = calendar.date(byAdding: .day, value: Int(daysUntil), to: date) {
                    events.append(AstroEvent(
                        type: .transit,
                        title: phase.name,
                        description: phase.desc,
                        startDate: phaseDate,
                        endDate: nil
                    ))
                }
            }
        }

        return events
    }

    // MARK: - Live Retrogrades from API

    private func fetchLiveRetrogrades() async -> [AstroEvent] {
        do {
            // Fetch planetary positions for right now using user's location
            let lat = await LocationManager.shared.latitude
            let lon = await LocationManager.shared.longitude
            let chart = try await chartService.fetchChart(latitude: lat, longitude: lon)

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
