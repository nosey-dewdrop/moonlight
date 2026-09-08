import Foundation
import CoreLocation

/// Turns a birth-place name ("İstanbul, Türkiye") into coordinates + the time
/// zone that applied there. Uses Apple's built-in geocoder — free, no API key,
/// works offline-ish via Apple's service. This is what makes the natal chart
/// *accurate*: the astrology API needs real lat/lon + UTC offset at birth.
struct GeocodedPlace {
    let name: String
    let latitude: Double
    let longitude: Double
    let timeZone: TimeZone

    /// UTC offset in hours for a specific moment (handles historical DST).
    func timezoneHours(at date: Date) -> Double {
        Double(timeZone.secondsFromGMT(for: date)) / 3600.0
    }
}

enum GeocodingError: LocalizedError {
    case notFound
    var errorDescription: String? {
        L("Bu yeri bulamadık. Şehri farklı yazmayı dene.",
          "We couldn't find that place. Try writing the city differently.")
    }
}

final class GeocodingService {
    private let geocoder = CLGeocoder()

    func geocode(_ query: String) async throws -> GeocodedPlace {
        let placemarks = try await geocoder.geocodeAddressString(query)
        guard let mark = placemarks.first,
              let loc = mark.location else {
            throw GeocodingError.notFound
        }

        // Prefer a clean "City, Country" label for display.
        let city = mark.locality ?? mark.administrativeArea ?? mark.name ?? query
        let country = mark.country
        let label = [city, country].compactMap { $0 }.joined(separator: ", ")

        return GeocodedPlace(
            name: label.isEmpty ? query : label,
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            timeZone: mark.timeZone ?? .current
        )
    }

    /// Lightweight autocomplete-ish suggestions for the birth-place field.
    func suggestions(_ query: String) async -> [GeocodedPlace] {
        guard query.count >= 2 else { return [] }
        guard let placemarks = try? await geocoder.geocodeAddressString(query) else { return [] }
        return placemarks.prefix(5).compactMap { mark in
            guard let loc = mark.location else { return nil }
            let city = mark.locality ?? mark.administrativeArea ?? mark.name ?? query
            let country = mark.country
            let label = [city, country].compactMap { $0 }.joined(separator: ", ")
            return GeocodedPlace(
                name: label.isEmpty ? query : label,
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                timeZone: mark.timeZone ?? .current
            )
        }
    }
}
