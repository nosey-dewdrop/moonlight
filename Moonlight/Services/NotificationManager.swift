import Foundation
import UserNotifications

/// Handles all local notifications: moon phase changes, daily reminder,
/// special astro events, and the daily free-credit refresh.
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let d = UserDefaults.standard
    private let astrologyService = AstrologyService()

    // MARK: - Persisted toggles

    @Published var masterEnabled: Bool { didSet { persistAndReschedule("notif.master", masterEnabled) } }
    @Published var phaseChanges: Bool { didSet { persistAndReschedule("notif.phase", phaseChanges) } }
    @Published var dailyReminder: Bool { didSet { persistAndReschedule("notif.daily", dailyReminder) } }
    @Published var astroEvents: Bool { didSet { persistAndReschedule("notif.events", astroEvents) } }
    @Published var creditsRefresh: Bool { didSet { persistAndReschedule("notif.credits", creditsRefresh) } }
    @Published var dailyReminderHour: Int { didSet { persistAndReschedule("notif.dailyHour", dailyReminderHour) } }

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private var rescheduleTask: Task<Void, Never>?

    private init() {
        masterEnabled = d.object(forKey: "notif.master") as? Bool ?? false
        phaseChanges = d.object(forKey: "notif.phase") as? Bool ?? true
        dailyReminder = d.object(forKey: "notif.daily") as? Bool ?? true
        astroEvents = d.object(forKey: "notif.events") as? Bool ?? true
        creditsRefresh = d.object(forKey: "notif.credits") as? Bool ?? true
        dailyReminderHour = d.object(forKey: "notif.dailyHour") as? Int ?? 9
    }

    // MARK: - Authorization

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Asks the user for permission. Returns true if granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if granted {
                masterEnabled = true
                await rescheduleAll()
            }
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    private func persistAndReschedule(_ key: String, _ value: Any) {
        d.set(value, forKey: key)
        rescheduleTask?.cancel()
        rescheduleTask = Task { await rescheduleAll() }
    }

    /// Clears everything and re-schedules based on the current toggles.
    func rescheduleAll() async {
        center.removeAllPendingNotificationRequests()

        await refreshAuthorizationStatus()
        guard masterEnabled, authorizationStatus == .authorized else { return }

        if dailyReminder { scheduleDailyReminder() }
        if creditsRefresh { scheduleCreditsRefresh() }
        if phaseChanges { schedulePhaseChanges() }
        if astroEvents { await scheduleAstroEvents() }
    }

    private func add(id: String, title: String, body: String, trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // Daily reminder, repeats every day at the chosen hour.
    private func scheduleDailyReminder() {
        var c = DateComponents()
        c.hour = dailyReminderHour
        c.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
        add(
            id: "daily_reminder",
            title: L("Moonlight 🌙", "Moonlight 🌙"),
            body: L("Bugünün ayı ve enerjisi seni bekliyor.", "Today's moon and energy are waiting for you."),
            trigger: trigger
        )
    }

    // Daily free credits refresh at local midnight.
    private func scheduleCreditsRefresh() {
        var c = DateComponents()
        c.hour = 0
        c.minute = 1
        let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
        add(
            id: "credits_refresh",
            title: L("Kredilerin yenilendi ✨", "Your credits are back ✨"),
            body: L("Günlük ücretsiz kredilerin hazır. Bir okuma yapmaya ne dersin?",
                    "Your daily free credits are ready. How about a reading?"),
            trigger: trigger
        )
    }

    // New & Full moon for the next ~60 days (one-shot each).
    private func schedulePhaseChanges() {
        let calendar = Calendar.current
        for phase in Self.upcomingMajorPhases(within: 60) {
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: phase.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let name = phase.isFull ? L("Dolunay", "Full Moon") : L("Yeni Ay", "New Moon")
            let body = phase.isFull
                ? L("Bu gece dolunay. Netlik, hasat ve bırakma zamanı.", "Tonight is the full moon. A time for clarity, harvest and release.")
                : L("Bugün yeni ay. Yeni bir döngü, niyet zamanı.", "Today is the new moon. A fresh cycle, a time to set intentions.")
            add(id: "phase_\(Int(phase.date.timeIntervalSince1970))", title: "\(name) 🌙", body: body, trigger: trigger)
        }
    }

    // Eclipses / retrogrades coming up.
    private func scheduleAstroEvents() async {
        guard let events = try? await astrologyService.fetchEvents() else { return }
        let now = Date()
        let calendar = Calendar.current
        for event in events {
            guard let start = event.startDate, start > now else { continue }
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            add(id: "event_\(event.id.uuidString)", title: "\(event.title) ✨", body: event.description, trigger: trigger)
        }
    }

    // MARK: - Moon phase math (New & Full)

    private struct MajorPhase { let date: Date; let isFull: Bool }

    private static func upcomingMajorPhases(within days: Int) -> [MajorPhase] {
        let synodicMonth = 29.53058868
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
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

        var result: [MajorPhase] = []
        // New = age 0, Full = age 14.77, repeating each synodic month.
        for cycle in 0...3 {
            for (targetAge, isFull) in [(0.0, false), (14.77, true)] {
                let daysUntil = targetAge - currentAge + Double(cycle) * synodicMonth
                if daysUntil <= 0 { continue }
                if daysUntil > Double(days) { continue }
                if let date = calendar.date(byAdding: .hour, value: Int(daysUntil * 24), to: now) {
                    // Fire at 20:00 local that day rather than the exact astronomical minute.
                    var dc = calendar.dateComponents([.year, .month, .day], from: date)
                    dc.hour = 20
                    dc.minute = 0
                    if let fireDate = calendar.date(from: dc), fireDate > now {
                        result.append(MajorPhase(date: fireDate, isFull: isFull))
                    }
                }
            }
        }
        return result.sorted { $0.date < $1.date }
    }
}
