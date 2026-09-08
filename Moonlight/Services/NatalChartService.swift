import Foundation

/// Builds the user's real natal (birth) chart from their birth data and the
/// astrology API — this is moonlight's core: not an LLM guess, actual ephemeris
/// positions. It also derives the real Sun / Moon / Rising and stores them back
/// on the profile so the rest of the app reads accurate placements.
final class NatalChartService {
    static let shared = NatalChartService()

    private let chartService = HoraryChartService()
    private let geocoder = GeocodingService()

    /// In-memory cache of the last computed natal chart (full data isn't Codable,
    /// so we keep it for the session; the big-three persist on the profile).
    @MainActor private(set) var cachedChart: HoraryChartData?

    enum NatalError: LocalizedError {
        case missingBirthDate
        var errorDescription: String? {
            L("Doğum tarihi eksik.", "Birth date is missing.")
        }
    }

    /// Resolves coordinates + timezone if needed, computes the chart, stores the
    /// derived Sun/Moon/Rising on the profile, and returns the full chart.
    @MainActor
    func computeAndStore(for profile: UserProfile) async throws -> HoraryChartData {
        guard let birthDate = profile.birthDate else { throw NatalError.missingBirthDate }

        // Resolve place → lat/lon/timezone once, then cache on the profile.
        let lat: Double
        let lon: Double
        let tzHours: Double

        if let plat = profile.birthLatitude,
           let plon = profile.birthLongitude,
           let ptz = profile.birthTimezoneHours {
            lat = plat; lon = plon; tzHours = ptz
        } else {
            let place = try await geocoder.geocode(profile.birthPlaceName)
            lat = place.latitude
            lon = place.longitude
            tzHours = place.timezoneHours(at: birthDate)
            profile.birthLatitude = lat
            profile.birthLongitude = lon
            profile.birthTimezoneHours = tzHours
            if profile.birthPlaceName.isEmpty { profile.birthPlaceName = place.name }
        }

        let tz = TimeZone(secondsFromGMT: Int(tzHours * 3600)) ?? .current
        let chart = try await chartService.fetchChart(
            date: birthDate,
            latitude: lat,
            longitude: lon,
            timezoneHours: tzHours,
            timezone: tz
        )

        applyBigThree(from: chart, to: profile)
        cachedChart = chart
        return chart
    }

    /// Pulls Sun, Moon and Ascendant signs out of the chart onto the profile.
    @MainActor
    private func applyBigThree(from chart: HoraryChartData, to profile: UserProfile) {
        func sign(for planet: String) -> ZodiacSign? {
            guard let p = chart.planets.first(where: { $0.name == planet }) else { return nil }
            return ZodiacSign(rawValue: p.sign.lowercased())
        }
        if let sun = sign(for: "Sun") { profile.sunSign = sun }
        if let moon = sign(for: "Moon") { profile.moonSign = moon }
        if let rising = sign(for: "Ascendant") { profile.risingSign = rising }
    }
}

// MARK: - Chart display helpers

extension ZodiacSign {
    /// Turkish display name for the sign.
    var displayNameTR: String {
        switch self {
        case .aries: return "Koç"
        case .taurus: return "Boğa"
        case .gemini: return "İkizler"
        case .cancer: return "Yengeç"
        case .leo: return "Aslan"
        case .virgo: return "Başak"
        case .libra: return "Terazi"
        case .scorpio: return "Akrep"
        case .sagittarius: return "Yay"
        case .capricorn: return "Oğlak"
        case .aquarius: return "Kova"
        case .pisces: return "Balık"
        }
    }

    /// Localized display name (TR when the app is Turkish).
    var localizedName: String {
        LocalizationManager.shared.language == .tr ? displayNameTR : displayName
    }
}
