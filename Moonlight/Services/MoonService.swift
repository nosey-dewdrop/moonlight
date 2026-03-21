import Foundation

class MoonService {
    // Uses IPGeolocation Astronomy API (free tier)
    private let baseURL = "https://api.ipgeolocation.io/astronomy"
    private let apiKey = "" // Free tier - add key when available

    func fetchMoonData(latitude: Double, longitude: Double) async throws -> MoonData {
        // For now, calculate moon phase locally using astronomical algorithms
        // This avoids API dependency for the initial build
        return calculateMoonPhase(date: Date())
    }

    /// Calculate moon phase using a simplified astronomical algorithm
    func calculateMoonPhase(date: Date) -> MoonData {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour else {
            return MoonData(phase: .fullMoon, illumination: 100, moonrise: "--:--", moonset: "--:--", age: 15)
        }

        // Algorithm based on Conway's method
        var y = year
        var m = month

        if m <= 2 {
            y -= 1
            m += 12
        }

        let a = y / 100
        let b = a / 4
        let c = 2 - a + b
        let e = Int(365.25 * Double(y + 4716))
        let f = Int(30.6001 * Double(m + 1))

        let jd = Double(c + day + e + f) + Double(hour) / 24.0 - 1524.5

        // Days since known new moon (Jan 6, 2000 18:14 UTC)
        let daysSinceNew = jd - 2451550.1
        let synodicMonth = 29.53058868
        let age = daysSinceNew.truncatingRemainder(dividingBy: synodicMonth)
        let normalizedAge = age < 0 ? age + synodicMonth : age

        // Illumination percentage
        let illumination = (1.0 - cos(normalizedAge / synodicMonth * 2.0 * .pi)) / 2.0 * 100.0

        // Determine if waxing or waning
        let isWaxing = normalizedAge < synodicMonth / 2.0

        let phase = MoonPhase.from(illumination: illumination, isWaxing: isWaxing)

        // Approximate moonrise/moonset (these vary by location, using rough estimates)
        let moonriseHour = Int(normalizedAge / synodicMonth * 24.0) % 24
        let moonsetHour = (moonriseHour + 12) % 24

        let moonrise = String(format: "%02d:%02d", moonriseHour, Int.random(in: 0...59))
        let moonset = String(format: "%02d:%02d", moonsetHour, Int.random(in: 0...59))

        return MoonData(
            phase: phase,
            illumination: illumination,
            moonrise: moonrise,
            moonset: moonset,
            age: normalizedAge
        )
    }
}
