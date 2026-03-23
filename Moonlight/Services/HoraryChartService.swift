import Foundation
import CoreLocation

struct HoraryChartData {
    let planets: [PlanetPosition]
    let houses: [HousePosition]
    let aspects: [ChartAspect]
    let queriedAt: Date

    var promptDescription: String {
        var desc = "Planets:\n"
        for p in planets {
            desc += "  \(p.name) in \(p.sign) at \(String(format: "%.1f", p.degree))° (House \(p.house))\n"
        }
        desc += "\nHouses:\n"
        for h in houses {
            desc += "  House \(h.number): \(h.sign) at \(String(format: "%.1f", h.degree))°\n"
        }
        if !aspects.isEmpty {
            desc += "\nKey aspects:\n"
            for a in aspects.prefix(10) {
                desc += "  \(a.planet1) \(a.aspect) \(a.planet2) (orb: \(String(format: "%.1f", a.orb))°)\n"
            }
        }
        return desc
    }
}

struct PlanetPosition {
    let name: String
    let sign: String
    let degree: Double
    let house: Int
}

struct HousePosition {
    let number: Int
    let sign: String
    let degree: Double
}

struct ChartAspect {
    let planet1: String
    let aspect: String
    let planet2: String
    let orb: Double
}

class HoraryChartService {
    private let baseURL = "https://json.freeastrologyapi.com/horoscope-chart-info"

    func fetchChart(latitude: Double, longitude: Double) async throws -> HoraryChartData {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone.current, from: now)

        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute else {
            throw ChartError.invalidDate
        }

        let tz = Double(TimeZone.current.secondsFromGMT()) / 3600.0

        let requestBody: [String: Any] = [
            "year": year,
            "month": month,
            "date": day,
            "hours": hour,
            "minutes": minute,
            "seconds": 0,
            "latitude": latitude,
            "longitude": longitude,
            "timezone": tz,
            "config": [
                "observation_point": "geocentric",
                "ayanamsha": "tropical",
                "house_system": "Regiomontanus"
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw ChartError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChartError.apiError
        }

        return try parseResponse(data, queriedAt: now)
    }

    private func parseResponse(_ data: Data, queriedAt: Date) throws -> HoraryChartData {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [String: Any] else {
            throw ChartError.parseError
        }

        let signNames = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                         "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]

        // Parse planets
        var planets: [PlanetPosition] = []
        let planetKeys = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]

        for key in planetKeys {
            if let planetData = output[key] as? [String: Any] {
                let fullDegree = planetData["fullDegree"] as? Double ?? 0
                let signIndex = Int(fullDegree / 30.0)
                let degreeInSign = fullDegree.truncatingRemainder(dividingBy: 30.0)
                let sign = signIndex < signNames.count ? signNames[signIndex] : "Unknown"
                let house = planetData["house"] as? Int ?? 0

                planets.append(PlanetPosition(name: key, sign: sign, degree: degreeInSign, house: house))
            }
        }

        // Parse houses
        var houses: [HousePosition] = []
        if let houseData = output["houses"] as? [[String: Any]] {
            for (i, h) in houseData.enumerated() {
                let fullDegree = h["degree"] as? Double ?? 0
                let signIndex = Int(fullDegree / 30.0)
                let degreeInSign = fullDegree.truncatingRemainder(dividingBy: 30.0)
                let sign = signIndex < signNames.count ? signNames[signIndex] : "Unknown"
                houses.append(HousePosition(number: i + 1, sign: sign, degree: degreeInSign))
            }
        }

        // Parse aspects
        var aspects: [ChartAspect] = []
        if let aspectData = output["aspects"] as? [[String: Any]] {
            let aspectNames = ["conjunction": "conjunct", "opposition": "opposite",
                             "trine": "trine", "square": "square", "sextile": "sextile"]
            for a in aspectData {
                let p1 = a["aspecting_planet"] as? String ?? ""
                let p2 = a["aspected_planet"] as? String ?? ""
                let type = a["type"] as? String ?? ""
                let orb = a["orb"] as? Double ?? 0
                let aspectName = aspectNames[type.lowercased()] ?? type

                aspects.append(ChartAspect(planet1: p1, aspect: aspectName, planet2: p2, orb: orb))
            }
        }

        return HoraryChartData(planets: planets, houses: houses, aspects: aspects, queriedAt: queriedAt)
    }
}

enum ChartError: LocalizedError {
    case invalidDate
    case invalidURL
    case apiError
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidDate: return "Invalid date"
        case .invalidURL: return "Invalid URL"
        case .apiError: return "Chart API error"
        case .parseError: return "Failed to parse chart"
        }
    }
}
