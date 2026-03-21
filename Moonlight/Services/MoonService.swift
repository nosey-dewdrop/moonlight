import Foundation

class MoonService {
    // US Naval Observatory API - free, no key needed
    private let baseURL = "https://aa.usno.navy.mil/api/rstt/oneday"

    /// Fetch real moon data from USNO API
    func fetchMoonData(latitude: Double, longitude: Double) async throws -> MoonData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())

        let coordStr = String(format: "%.2f,%.2f", latitude, longitude)
        guard let url = URL(string: "\(baseURL)?date=\(dateStr)&coords=\(coordStr)") else {
            return calculateMoonPhase(date: Date())
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(USNOResponse.self, from: data)

        // Parse moon phase
        let phaseName = response.properties.data.closestPhase?.phase ?? ""
        let fracIllum = response.properties.data.fracillum ?? ""
        let illumination = Double(fracIllum.replacingOccurrences(of: "%", with: "")) ?? 0

        // Parse moonrise/moonset
        var moonrise = "--:--"
        var moonset = "--:--"

        if let moonPhenomena = response.properties.data.moondata {
            for item in moonPhenomena {
                if item.phen == "Rise" || item.phen == "R" {
                    moonrise = item.time ?? "--:--"
                } else if item.phen == "Set" || item.phen == "S" {
                    moonset = item.time ?? "--:--"
                }
            }
        }

        // Determine phase from API or calculate
        let localData = calculateMoonPhase(date: Date())
        let phase: MoonPhase
        if !phaseName.isEmpty {
            phase = MoonPhase.fromAPIName(phaseName) ?? localData.phase
        } else {
            phase = localData.phase
        }

        return MoonData(
            phase: phase,
            illumination: illumination,
            moonrise: moonrise,
            moonset: moonset,
            age: localData.age
        )
    }

    /// Local fallback calculation
    func calculateMoonPhase(date: Date) -> MoonData {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour else {
            return MoonData(phase: .fullMoon, illumination: 100, moonrise: "--:--", moonset: "--:--", age: 15)
        }

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

        let daysSinceNew = jd - 2451550.1
        let synodicMonth = 29.53058868
        let age = daysSinceNew.truncatingRemainder(dividingBy: synodicMonth)
        let normalizedAge = age < 0 ? age + synodicMonth : age

        let illumination = (1.0 - cos(normalizedAge / synodicMonth * 2.0 * .pi)) / 2.0 * 100.0
        let isWaxing = normalizedAge < synodicMonth / 2.0
        let phase = MoonPhase.from(illumination: illumination, isWaxing: isWaxing)

        // Deterministic moonrise/moonset approximation
        let moonriseHour = Int(normalizedAge / synodicMonth * 24.0) % 24
        let moonsetHour = (moonriseHour + 12) % 24
        let moonriseMin = Int(normalizedAge * 13.7) % 60
        let moonsetMin = Int(normalizedAge * 17.3) % 60

        let moonrise = String(format: "%02d:%02d", moonriseHour, moonriseMin)
        let moonset = String(format: "%02d:%02d", moonsetHour, moonsetMin)

        return MoonData(
            phase: phase,
            illumination: illumination,
            moonrise: moonrise,
            moonset: moonset,
            age: normalizedAge
        )
    }
}

// MARK: - USNO API Response Models

struct USNOResponse: Decodable {
    let properties: USNOProperties
}

struct USNOProperties: Decodable {
    let data: USNOData
}

struct USNOData: Decodable {
    let closestPhase: USNOPhase?
    let fracillum: String?
    let moondata: [USNOPhenomenon]?

    enum CodingKeys: String, CodingKey {
        case closestPhase = "closestphase"
        case fracillum
        case moondata
    }
}

struct USNOPhase: Decodable {
    let phase: String?
    let date: String?
}

struct USNOPhenomenon: Decodable {
    let phen: String?
    let time: String?
}
