import Foundation
import StoreKit

@MainActor
class CreditManager: ObservableObject {
    static let shared = CreditManager()

    @Published var credits: Int {
        didSet {
            UserDefaults.standard.set(credits, forKey: creditsKey)
        }
    }
    @Published var products: [Product] = []
    @Published var purchaseInProgress = false

    private let creditsKey = "com.damla.moonlight.credits"
    private let productIds = [
        "com.damla.moonlight.credits5",
        "com.damla.moonlight.credits15",
        "com.damla.moonlight.credits30",
    ]

    private init() {
        self.credits = UserDefaults.standard.integer(forKey: creditsKey)
    }

    var hasCredits: Bool {
        credits > 0
    }

    func useCredit() -> Bool {
        guard credits > 0 else { return false }
        credits -= 1
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
            credits += 5
        case "com.damla.moonlight.credits15":
            credits += 15
        case "com.damla.moonlight.credits30":
            credits += 30
        default:
            break
        }
    }

    /// Display info for product
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
