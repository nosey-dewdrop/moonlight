import Foundation

struct HoraryChartData {
    let planets: [PlanetPosition]
    let houses: [HousePosition]
    let aspects: [ChartAspect]
    let queriedAt: Date

    var promptDescription: String {
        var desc = "Planets:\n"
        for p in planets {
            desc += "  \(p.name) in \(p.sign) at \(String(format: "%.1f", p.degree))°\(p.isRetro ? " (retrograde)" : "")\n"
        }
        desc += "\nHouses:\n"
        for h in houses {
            desc += "  House \(h.number): \(h.sign) at \(String(format: "%.1f", h.degree))°\n"
        }
        if !aspects.isEmpty {
            desc += "\nKey aspects:\n"
            for a in aspects.prefix(10) {
                desc += "  \(a.planet1) \(a.aspect) \(a.planet2)\n"
            }
        }
        return desc
    }
}

struct PlanetPosition {
    let name: String
    let sign: String
    let degree: Double
    let isRetro: Bool
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
}

class HoraryChartService {
    private var baseURL: String { "\(Secrets.backendURL)/api/astrology" }

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

        let body: [String: Any] = [
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
                "observation_point": "topocentric",
                "ayanamsha": "tropical",
                "house_system": "Regiomontanus",
                "language": "en"
            ]
        ]

        // Fetch all three in parallel
        async let planetsResult = postRequest(endpoint: "/planets", body: body)
        async let housesResult = postRequest(endpoint: "/houses", body: body)
        async let aspectsResult = postRequest(endpoint: "/aspects", body: body)

        let planetsData = try await planetsResult
        let housesData = try await housesResult
        let aspectsData = try await aspectsResult

        let planets = parsePlanets(planetsData)
        let houses = parseHouses(housesData)
        let aspects = parseAspects(aspectsData)

        return HoraryChartData(planets: planets, houses: houses, aspects: aspects, queriedAt: now)
    }

    // MARK: - Network

    private func postRequest(endpoint: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw ChartError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.appToken, forHTTPHeaderField: "x-app-token")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChartError.apiError
        }

        return data
    }

    // MARK: - Parsing

    private func parsePlanets(_ data: Data) -> [PlanetPosition] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [[String: Any]] else {
            return []
        }

        let wanted = Set(["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto", "Ascendant", "MC"])

        return output.compactMap { planet in
            guard let planetInfo = planet["planet"] as? [String: Any],
                  let name = planetInfo["en"] as? String,
                  wanted.contains(name),
                  let normDegree = planet["normDegree"] as? Double,
                  let zodiacSign = planet["zodiac_sign"] as? [String: Any],
                  let signName = zodiacSign["name"] as? [String: Any],
                  let sign = signName["en"] as? String else {
                return nil
            }

            let isRetro = (planet["isRetro"] as? String)?.lowercased() == "true"
            return PlanetPosition(name: name, sign: sign, degree: normDegree, isRetro: isRetro)
        }
    }

    private func parseHouses(_ data: Data) -> [HousePosition] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [String: Any],
              let houses = output["Houses"] as? [[String: Any]] else {
            return []
        }

        return houses.compactMap { house in
            guard let number = house["House"] as? Int,
                  let normDegree = house["normDegree"] as? Double,
                  let zodiacSign = house["zodiac_sign"] as? [String: Any],
                  let signName = zodiacSign["name"] as? [String: Any],
                  let sign = signName["en"] as? String else {
                return nil
            }

            return HousePosition(number: number, sign: sign, degree: normDegree)
        }
    }

    private func parseAspects(_ data: Data) -> [ChartAspect] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [[String: Any]] else {
            return []
        }

        return output.compactMap { aspect in
            guard let p1Info = aspect["planet_1"] as? [String: Any],
                  let p1 = p1Info["en"] as? String,
                  let p2Info = aspect["planet_2"] as? [String: Any],
                  let p2 = p2Info["en"] as? String,
                  let aspectInfo = aspect["aspect"] as? [String: Any],
                  let aspectName = aspectInfo["en"] as? String else {
                return nil
            }

            return ChartAspect(planet1: p1, aspect: aspectName, planet2: p2)
        }
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
