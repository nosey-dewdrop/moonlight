import Foundation
import StoreKit

@MainActor
class CreditManager: ObservableObject {
    static let shared = CreditManager()

    @Published var purchasedCredits: Int {
        didSet {
            // Purchased balance lives in the Keychain so it survives reinstall.
            KeychainHelper.saveInt(purchasedCredits, key: purchasedCreditsKeychainKey)
        }
    }
    @Published var dailyCreditsUsed: Int {
        didSet {
            UserDefaults.standard.set(dailyCreditsUsed, forKey: dailyUsedKey)
        }
    }
    @Published var products: [Product] = []
    @Published var purchaseInProgress = false
    @Published var purchaseError: String?

    private let purchasedKey = "com.damla.moonlight.purchasedCredits"
    private let purchasedCreditsKeychainKey = "com.damla.moonlight.purchasedCredits"
    private let dailyUsedKey = "com.damla.moonlight.dailyCreditsUsed"
    private let lastResetKey = "com.damla.moonlight.lastDailyReset"
    private let welcomeKey = "com.damla.moonlight.welcomeBonusGiven"
    private let dailyFreeAmount = 3
    private let welcomeBonusAmount = 10

    private let productIds = [
        "com.damla.moonlight.credits5",
        "com.damla.moonlight.credits10",
        "com.damla.moonlight.credits15",
    ]

    private var transactionTask: Task<Void, Never>?

    /// True if this is the user's first launch (welcome bonus just given)
    @Published var isFirstLaunch: Bool = false

    private init() {
        if let stored = KeychainHelper.loadInt(key: purchasedCreditsKeychainKey) {
            self.purchasedCredits = stored
        } else {
            // One-time migration: move the existing UserDefaults balance into the
            // Keychain so current users keep every purchased credit.
            let legacy = UserDefaults.standard.integer(forKey: purchasedKey)
            KeychainHelper.saveInt(legacy, key: purchasedCreditsKeychainKey)
            self.purchasedCredits = legacy
        }
        self.dailyCreditsUsed = UserDefaults.standard.integer(forKey: dailyUsedKey)
        resetDailyIfNeeded()
        listenForTransactions()
        giveWelcomeBonus()

        #if DEBUG
        if !UserDefaults.standard.bool(forKey: "debugCredits500") {
            purchasedCredits = 500
            UserDefaults.standard.set(true, forKey: "debugCredits500")
        }
        #endif
    }

    private func giveWelcomeBonus() {
        if !UserDefaults.standard.bool(forKey: welcomeKey) {
            // Check if user already existed (has used credits before)
            let isExistingUser = UserDefaults.standard.object(forKey: lastResetKey) != nil
            UserDefaults.standard.set(true, forKey: welcomeKey)
            if !isExistingUser {
                purchasedCredits += welcomeBonusAmount
                isFirstLaunch = true
            }
        }
    }

    deinit {
        transactionTask?.cancel()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() {
        transactionTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? await self?.checkVerified(result) {
                    await self?.addCredits(for: transaction.productID)
                    await transaction.finish()
                }
            }
        }
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
        max(0, dailyFreeAmount - dailyCreditsUsed)
    }

    var totalCredits: Int {
        dailyCreditsRemaining + purchasedCredits
    }

    var hasCredits: Bool {
        totalCredits > 0
    }

    /// Returns number of daily credits used in this call (for refund tracking)
    func useCredit() -> Bool {
        resetDailyIfNeeded()
        guard totalCredits > 0 else { return false }

        if dailyCreditsRemaining > 0 {
            dailyCreditsUsed += 1
        } else {
            purchasedCredits -= 1
        }
        return true
    }

    func useCredits(_ amount: Int) -> Bool {
        resetDailyIfNeeded()
        guard totalCredits >= amount else { return false }

        // Calculate how many come from daily vs purchased to avoid partial consumption
        let fromDaily = min(dailyCreditsRemaining, amount)
        let fromPurchased = amount - fromDaily

        dailyCreditsUsed += fromDaily
        purchasedCredits -= fromPurchased
        return true
    }

    /// Refund credits correctly — tries daily first, then purchased
    func refundCredit() {
        if dailyCreditsUsed > 0 {
            dailyCreditsUsed -= 1
        } else {
            purchasedCredits += 1
        }
    }

    func refundCredits(_ amount: Int) {
        for _ in 0..<amount {
            refundCredit()
        }
    }

    // MARK: - StoreKit 2

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }
        } catch {
            // StoreKit product load failed — products array stays empty, UI shows fallback
        }
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        purchaseError = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                addCredits(for: product.id)
                await transaction.finish()

            case .userCancelled:
                break

            case .pending:
                purchaseError = L("Satın alma beklemede. Apple ID ödeme ayarlarını kontrol et.",
                                  "Purchase pending. Check your Apple ID payment settings.")

            @unknown default:
                break
            }
        } catch {
            purchaseError = L("Satın alma başarısız. Tekrar dene.", "Purchase failed. Please try again.")
        }
    }

    func restorePurchases() async {
        var processedIds = Set<UInt64>()
        let finishedKey = "com.damla.moonlight.finishedTransactions"
        let alreadyFinished = Set(UserDefaults.standard.array(forKey: finishedKey) as? [UInt64] ?? [])

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if !alreadyFinished.contains(transaction.id) && !processedIds.contains(transaction.id) {
                    addCredits(for: transaction.productID)
                    processedIds.insert(transaction.id)
                }
                await transaction.finish()
            }
        }

        // Save processed transaction IDs
        let allFinished = alreadyFinished.union(processedIds)
        UserDefaults.standard.set(Array(allFinished), forKey: finishedKey)
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
        let amount = Self.creditsForProduct(productId)
        if amount > 0 {
            purchasedCredits += amount
        }
    }

    static func creditsForProduct(_ productId: String) -> Int {
        switch productId {
        case "com.damla.moonlight.credits5": return 5
        case "com.damla.moonlight.credits10": return 10
        case "com.damla.moonlight.credits15": return 15
        default: return 0
        }
    }
}

enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        L("Satın alma doğrulaması başarısız", "Purchase verification failed")
    }
}
