import Foundation

/// "Today's sky" — one short free reading per day. Cached per (day, language)
/// in UserDefaults so each user costs at most one small model call a day, and
/// reopening the app is instant. No credits involved: this is the daily hook
/// that answers the 11:00 notification.
@MainActor
final class DailyReadingService: ObservableObject {
    static let shared = DailyReadingService()

    @Published var reading: String?
    @Published var isLoading = false
    @Published var failed = false

    private let claudeService = ClaudeService()
    private let moonService = MoonService()
    private let astrologyService = AstrologyService()

    private var cacheKey: String {
        let day = Theme.posixDateFormatter.string(from: Date())
        return "dailyReading.\(day).\(LocalizationManager.shared.language.rawValue)"
    }

    func load() async {
        if let cached = UserDefaults.standard.string(forKey: cacheKey) {
            reading = cached
            return
        }
        guard !isLoading else { return }
        isLoading = true
        failed = false
        defer { isLoading = false }

        let moon = moonService.calculateMoonPhase(date: Date())
        let events = (try? await astrologyService.fetchEvents()) ?? []
        let retros = events.filter { $0.isActive && $0.type == .retrograde }.map { $0.title }

        do {
            let text = try await claudeService.dailySkyReading(moonPhase: moon.phase,
                                                               illumination: moon.illumination,
                                                               activeRetrogrades: retros)
            reading = text
            UserDefaults.standard.set(text, forKey: cacheKey)
        } catch {
            failed = true
        }
    }
}
