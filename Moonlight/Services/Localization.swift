import SwiftUI
import Combine

// MARK: - App Language

enum AppLanguage: String, CaseIterable {
    case tr
    case en

    var displayName: String {
        switch self {
        case .tr: return "Türkçe"
        case .en: return "English"
        }
    }

    var flag: String {
        switch self {
        case .tr: return "🇹🇷"
        case .en: return "🇬🇧"
        }
    }

    /// Full language name used in AI prompts so the model writes in this language.
    var promptName: String {
        switch self {
        case .tr: return "Turkish"
        case .en: return "English"
        }
    }
}

// MARK: - Localization Manager

/// Single source of truth for the app language. Views that read localized
/// strings observe this object so they re-render instantly when the language
/// changes — no app restart needed.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private let key = "appLanguage"
    private let defaults = UserDefaults.standard

    @Published var language: AppLanguage {
        didSet {
            guard oldValue != language else { return }
            defaults.set(language.rawValue, forKey: key)
        }
    }

    private init() {
        if let saved = defaults.string(forKey: key).flatMap(AppLanguage.init) {
            language = saved
        } else {
            // First launch: follow the device language, fall back to English.
            let code = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
            language = (code == "tr") ? .tr : .en
        }
    }
}

// MARK: - Lookup helper

/// Returns the string for the current language.
/// Usage: `L("Ayarlar", "Settings")` — Turkish first, English second.
@inline(__always)
func L(_ tr: String, _ en: String) -> String {
    switch LocalizationManager.shared.language {
    case .tr: return tr
    case .en: return en
    }
}
