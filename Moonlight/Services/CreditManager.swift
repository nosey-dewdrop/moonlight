import Foundation
import StoreKit

@MainActor
class CreditManager: ObservableObject {
    static let shared = CreditManager()

    @Published var purchasedCredits: Int {
        didSet {
            UserDefaults.standard.set(purchasedCredits, forKey: purchasedKey)
        }
    }
    @Published var dailyCreditsUsed: Int {
        didSet {
            UserDefaults.standard.set(dailyCreditsUsed, forKey: dailyUsedKey)
        }
    }
    @Published var products: [Product] = []
    @Published var purchaseInProgress = false

    private let purchasedKey = "com.damla.moonlight.purchasedCredits"
    private let dailyUsedKey = "com.damla.moonlight.dailyCreditsUsed"
    private let lastResetKey = "com.damla.moonlight.lastDailyReset"
    private let dailyFreeAmount = 3

    private let productIds = [
        "com.damla.moonlight.credits5",
        "com.damla.moonlight.credits15",
        "com.damla.moonlight.credits30",
    ]

    private init() {
        self.purchasedCredits = UserDefaults.standard.integer(forKey: purchasedKey)
        self.dailyCreditsUsed = UserDefaults.standard.integer(forKey: dailyUsedKey)
        resetDailyIfNeeded()
    }

    // MARK: - Daily Reset

    private func resetDailyIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date ?? .distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            dailyCreditsUsed = 0
            UserDefaults.standard.set(Date(), forKey: lastResetKey)
        }
    }

    // MARK: - Credit Balance

    var dailyCreditsRemaining: Int {
        resetDailyIfNeeded()
        return max(0, dailyFreeAmount - dailyCreditsUsed)
    }

    var totalCredits: Int {
        dailyCreditsRemaining + purchasedCredits
    }

    var hasCredits: Bool {
        totalCredits > 0
    }

    func useCredit() -> Bool {
        resetDailyIfNeeded()
        guard totalCredits > 0 else { return false }

        // Use daily free credits first
        if dailyCreditsRemaining > 0 {
            dailyCreditsUsed += 1
        } else {
            purchasedCredits -= 1
        }
        return true
    }

    func useCredits(_ amount: Int) -> Bool {
        guard totalCredits >= amount else { return false }
        for _ in 0..<amount {
            if !useCredit() { return false }
        }
        return true
    }

    // MARK: - StoreKit 2

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            addCredits(for: product.id)
            await transaction.finish()

        case .userCancelled:
            break

        case .pending:
            break

        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                addCredits(for: transaction.productID)
                await transaction.finish()
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func addCredits(for productId: String) {
        switch productId {
        case "com.damla.moonlight.credits5":
            purchasedCredits += 5
        case "com.damla.moonlight.credits15":
            purchasedCredits += 15
        case "com.damla.moonlight.credits30":
            purchasedCredits += 30
        default:
            break
        }
    }

    static func creditsForProduct(_ productId: String) -> Int {
        switch productId {
        case "com.damla.moonlight.credits5": return 5
        case "com.damla.moonlight.credits15": return 15
        case "com.damla.moonlight.credits30": return 30
        default: return 0
        }
    }
}

enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        "Purchase verification failed"
    }
}
