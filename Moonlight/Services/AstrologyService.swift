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
            ("Yeni Ay", 0, "new_moon", "Yeni döngü başlıyor, niyet zamanı"),
            ("Dolunay", 14.77, "full_moon", "Hasat, netlik, bırakma zamanı"),
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
                "Mercury": "İletişim ve seyahat aksaklıkları olabilir",
                "Venus": "Aşk ve ilişkiler gözden geçiriliyor",
                "Mars": "Enerji ve motivasyon bloke hissedebilir",
                "Jupiter": "Büyüme ve genişleme yavaşlıyor",
                "Saturn": "Sorumlulukları ve yapıları gözden geçirme zamanı",
                "Uranus": "İçsel isyan, özgürlüğü yeniden düşünme",
                "Neptune": "Ruhani sis, illüzyonlar çözülüyor",
                "Pluto": "Yüzeyin altında derin dönüşüm",
            ]

            let planetNamesTR: [String: String] = [
                "Mercury": "Merkür", "Venus": "Venüs", "Mars": "Mars",
                "Jupiter": "Jüpiter", "Saturn": "Satürn", "Uranus": "Uranüs",
                "Neptune": "Neptün", "Pluto": "Plüton",
            ]

            return chart.planets
                .filter { $0.isRetro && retrogradeDescriptions.keys.contains($0.name) }
                .map { planet in
                    let trName = planetNamesTR[planet.name] ?? planet.name
                    return AstroEvent(
                        type: .retrograde,
                        title: "\(trName) Retrograd",
                        description: retrogradeDescriptions[planet.name] ?? "Gezegen geri hareket ediyor",
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
            // Güneş Tutulmaları 2025
            AstroEvent(type: .eclipse, title: "Kısmi Güneş Tutulması",
                       description: "Yeni başlangıçlar zamanı",
                       startDate: f.date(from: "2025-03-29"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Kısmi Güneş Tutulması",
                       description: "Taze bir sayfa açılıyor",
                       startDate: f.date(from: "2025-09-21"), endDate: nil),

            // Ay Tutulmaları 2025
            AstroEvent(type: .eclipse, title: "Tam Ay Tutulması",
                       description: "Duygusal arınma zamanı",
                       startDate: f.date(from: "2025-03-14"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Tam Ay Tutulması",
                       description: "İçsel dönüşüm başlıyor",
                       startDate: f.date(from: "2025-09-07"), endDate: nil),

            // Güneş Tutulmaları 2026
            AstroEvent(type: .eclipse, title: "Halkalı Güneş Tutulması",
                       description: "Ateş halkası, güçlü yeni döngü",
                       startDate: f.date(from: "2026-02-17"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Tam Güneş Tutulması",
                       description: "Büyük dönüşüm zamanı",
                       startDate: f.date(from: "2026-08-12"), endDate: nil),

            // Ay Tutulmaları 2026
            AstroEvent(type: .eclipse, title: "Tam Ay Tutulması",
                       description: "Derin duygusal değişimler",
                       startDate: f.date(from: "2026-03-03"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Kısmi Ay Tutulması",
                       description: "İnce içsel değişimler",
                       startDate: f.date(from: "2026-08-28"), endDate: nil),

            // Güneş Tutulmaları 2027
            AstroEvent(type: .eclipse, title: "Tam Güneş Tutulması",
                       description: "Hayatında büyük değişim",
                       startDate: f.date(from: "2027-02-06"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Halkalı Güneş Tutulması",
                       description: "Ateş halkası, yeni döngüler",
                       startDate: f.date(from: "2027-08-02"), endDate: nil),

            // Ay Tutulmaları 2027
            AstroEvent(type: .eclipse, title: "Yarıgölge Ay Tutulması",
                       description: "Duygusal manzarada ince değişimler",
                       startDate: f.date(from: "2027-02-20"), endDate: nil),
            AstroEvent(type: .eclipse, title: "Yarıgölge Ay Tutulması",
                       description: "İç gelgitler yavaşça dönüyor",
                       startDate: f.date(from: "2027-07-18"), endDate: nil),
        ]
    }
}
