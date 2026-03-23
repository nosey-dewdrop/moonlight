import Foundation

enum ZodiacSign: String, CaseIterable, Codable {
    case aries, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var displayName: String {
        switch self {
        case .aries: return "Aries"
        case .taurus: return "Taurus"
        case .gemini: return "Gemini"
        case .cancer: return "Cancer"
        case .leo: return "Leo"
        case .virgo: return "Virgo"
        case .libra: return "Libra"
        case .scorpio: return "Scorpio"
        case .sagittarius: return "Sagittarius"
        case .capricorn: return "Capricorn"
        case .aquarius: return "Aquarius"
        case .pisces: return "Pisces"
        }
    }

    var emoji: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
}

class UserProfile: ObservableObject {
    static let shared = UserProfile()

    @Published var sunSign: ZodiacSign? {
        didSet { save() }
    }
    @Published var risingSign: ZodiacSign? {
        didSet { save() }
    }
    @Published var moonSign: ZodiacSign? {
        didSet { save() }
    }
    @Published var birthTime: Date? {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    private init() {
        if let raw = defaults.string(forKey: "sunSign") {
            sunSign = ZodiacSign(rawValue: raw)
        }
        if let raw = defaults.string(forKey: "risingSign") {
            risingSign = ZodiacSign(rawValue: raw)
        }
        if let raw = defaults.string(forKey: "moonSign") {
            moonSign = ZodiacSign(rawValue: raw)
        }
        if let time = defaults.object(forKey: "birthTime") as? Date {
            birthTime = time
        }
    }

    private func save() {
        defaults.set(sunSign?.rawValue, forKey: "sunSign")
        defaults.set(risingSign?.rawValue, forKey: "risingSign")
        defaults.set(moonSign?.rawValue, forKey: "moonSign")
        defaults.set(birthTime, forKey: "birthTime")
    }

    var promptDescription: String {
        var parts: [String] = []
        if let sun = sunSign { parts.append("Sun sign: \(sun.displayName)") }
        if let rising = risingSign { parts.append("Rising sign: \(rising.displayName)") }
        if let moon = moonSign { parts.append("Moon sign: \(moon.displayName)") }
        if let time = birthTime {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            parts.append("Birth time: \(f.string(from: time))")
        }
        return parts.isEmpty ? "No birth chart info provided" : parts.joined(separator: ", ")
    }
}
