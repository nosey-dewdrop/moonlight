import StoreKit
import UIKit
import UserNotifications

/// Post-reading engagement moments. The first successful reading is the app's
/// value peak, so that's when the rate prompt appears; notification permission
/// waits for the second reading so the two system dialogs never stack.
@MainActor
enum EngagementPrompts {
    private static let countKey = "engage.readingCount"

    static func readingCompleted() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)

        switch count {
        case 1:
            Task {
                // Let the reading land first — the prompt shouldn't cover it.
                try? await Task.sleep(for: .seconds(2))
                requestReview()
            }
        case 2:
            Task {
                try? await Task.sleep(for: .seconds(2))
                let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                if status == .notDetermined {
                    await NotificationManager.shared.requestAuthorization()
                }
            }
        default:
            break
        }
    }

    private static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        AppStore.requestReview(in: scene)
    }
}
