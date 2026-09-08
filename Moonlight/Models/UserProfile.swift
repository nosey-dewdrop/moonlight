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

    private static let birthTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

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

    // Birth data — the input to the real astrology engine.
    @Published var name: String { didSet { save() } }
    /// Full birth moment. If the exact time is unknown, this holds local noon and
    /// `hasBirthTime` is false (rising/houses become approximate).
    @Published var birthDate: Date? { didSet { save() } }
    @Published var hasBirthTime: Bool { didSet { save() } }
    @Published var birthPlaceName: String { didSet { save() } }
    @Published var birthLatitude: Double? { didSet { save() } }
    @Published var birthLongitude: Double? { didSet { save() } }
    /// UTC offset in hours that applied at the birth place/time.
    @Published var birthTimezoneHours: Double? { didSet { save() } }

    private let defaults = UserDefaults.standard

    /// True once the user has given enough to compute a chart.
    var isOnboarded: Bool { birthDate != nil }
    var hasCoordinates: Bool { birthLatitude != nil && birthLongitude != nil }

    private init() {
        // Load without triggering didSet/save
        let savedSun = defaults.string(forKey: "sunSign").flatMap { ZodiacSign(rawValue: $0) }
        let savedRising = defaults.string(forKey: "risingSign").flatMap { ZodiacSign(rawValue: $0) }
        let savedMoon = defaults.string(forKey: "moonSign").flatMap { ZodiacSign(rawValue: $0) }
        let savedTime = defaults.object(forKey: "birthTime") as? Date

        _sunSign = Published(initialValue: savedSun)
        _risingSign = Published(initialValue: savedRising)
        _moonSign = Published(initialValue: savedMoon)
        _birthTime = Published(initialValue: savedTime)

        _name = Published(initialValue: defaults.string(forKey: "profile.name") ?? "")
        _birthDate = Published(initialValue: defaults.object(forKey: "profile.birthDate") as? Date)
        _hasBirthTime = Published(initialValue: defaults.bool(forKey: "profile.hasBirthTime"))
        _birthPlaceName = Published(initialValue: defaults.string(forKey: "profile.birthPlaceName") ?? "")
        _birthLatitude = Published(initialValue: defaults.object(forKey: "profile.birthLatitude") as? Double)
        _birthLongitude = Published(initialValue: defaults.object(forKey: "profile.birthLongitude") as? Double)
        _birthTimezoneHours = Published(initialValue: defaults.object(forKey: "profile.birthTimezoneHours") as? Double)
    }

    private func save() {
        defaults.set(sunSign?.rawValue, forKey: "sunSign")
        defaults.set(risingSign?.rawValue, forKey: "risingSign")
        defaults.set(moonSign?.rawValue, forKey: "moonSign")
        defaults.set(birthTime, forKey: "birthTime")

        defaults.set(name, forKey: "profile.name")
        defaults.set(birthDate, forKey: "profile.birthDate")
        defaults.set(hasBirthTime, forKey: "profile.hasBirthTime")
        defaults.set(birthPlaceName, forKey: "profile.birthPlaceName")
        setOptionalDouble(birthLatitude, "profile.birthLatitude")
        setOptionalDouble(birthLongitude, "profile.birthLongitude")
        setOptionalDouble(birthTimezoneHours, "profile.birthTimezoneHours")
    }

    private func setOptionalDouble(_ value: Double?, _ key: String) {
        if let value { defaults.set(value, forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }

    /// Wipes all birth/profile data — backs the "delete my data" KVKK right.
    func reset() {
        name = ""; birthDate = nil; hasBirthTime = false; birthPlaceName = ""
        birthLatitude = nil; birthLongitude = nil; birthTimezoneHours = nil
        sunSign = nil; moonSign = nil; risingSign = nil; birthTime = nil
    }

    var promptDescription: String {
        var parts: [String] = []
        if !name.isEmpty { parts.append("Name: \(name)") }
        if let sun = sunSign { parts.append("Sun sign: \(sun.displayName)") }
        if let rising = risingSign { parts.append("Rising sign: \(rising.displayName)") }
        if let moon = moonSign { parts.append("Moon sign: \(moon.displayName)") }
        if let time = birthTime {
            parts.append("Birth time: \(Self.birthTimeFormatter.string(from: time))")
        }
        if !birthPlaceName.isEmpty { parts.append("Birth place: \(birthPlaceName)") }
        return parts.isEmpty ? "No birth chart info provided" : parts.joined(separator: ", ")
    }
}
