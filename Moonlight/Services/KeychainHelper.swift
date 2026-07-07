import Foundation
import Security

/// Tiny wrapper for storing the session token securely in the Keychain.
enum KeychainHelper {
    private static let service = "com.damla.moonlight.auth"

    static func save(_ value: String, key: String, accessible: CFString = kSecAttrAccessibleAfterFirstUnlock) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = accessible
        SecItemAdd(attributes as CFDictionary, nil)
    }

    /// Persist an integer balance bound to this device only (never synced to
    /// iCloud), so purchased credits survive delete/reinstall on the device.
    static func saveInt(_ value: Int, key: String) {
        save(String(value), key: key, accessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
    }

    static func loadInt(key: String) -> Int? {
        guard let stored = load(key: key) else { return nil }
        return Int(stored)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
