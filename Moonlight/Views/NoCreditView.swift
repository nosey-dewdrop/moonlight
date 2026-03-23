import SwiftUI

struct NoCreditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditManager = CreditManager.shared

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("No Credits")
                    .font(.custom(titleFont, size: 14))
                    .foregroundColor(accent)

                Text("Your daily credits are used up.\nGet more to continue reading.")
                    .font(.custom(bodyFont, size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // Purchase options
                VStack(spacing: 10) {
                    if creditManager.products.isEmpty {
                        ForEach(fallbackProducts, id: \.id) { product in
                            purchaseRow(name: product.name, price: product.price, credits: product.credits)
                        }
                    } else {
                        ForEach(creditManager.products, id: \.id) { product in
                            let credits = CreditManager.creditsForProduct(product.id)
                            purchaseRow(name: product.displayName, price: product.displayPrice, credits: credits)
                        }
                    }
                }
                .padding(.horizontal, 16)

                Button(action: {
                    Task { await creditManager.restorePurchases() }
                }) {
                    Text("Restore Purchases")
                        .font(.custom(bodyFont, size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.custom(bodyFont, size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 40)
                }
                .accessibilityLabel("Close")
            }
        }
        .task {
            await creditManager.loadProducts()
        }
    }

    private func purchaseRow(name: String, price: String, credits: Int) -> some View {
        Button(action: {
            // Try to find matching StoreKit product
            if let product = creditManager.products.first(where: { CreditManager.creditsForProduct($0.id) == credits }) {
                Task { try? await creditManager.purchase(product) }
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.custom(bodyBoldFont, size: 12))
                        .foregroundColor(.white)
                    Text("\(credits) readings")
                        .font(.custom(bodyFont, size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Text(price)
                    .font(.custom(bodyBoldFont, size: 12))
                    .foregroundColor(accent)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(bg.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(accent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .accessibilityLabel("Buy \(credits) credits for \(price)")
        .disabled(creditManager.purchaseInProgress)
    }

    private struct FallbackProduct: Identifiable {
        let id: String
        let name: String
        let price: String
        let credits: Int
    }

    private let fallbackProducts = [
        FallbackProduct(id: "credits5", name: "5 Credits", price: "$1.99", credits: 5),
        FallbackProduct(id: "credits15", name: "15 Credits", price: "$4.99", credits: 15),
        FallbackProduct(id: "credits30", name: "30 Credits", price: "$8.99", credits: 30),
    ]
}

#Preview {
    NoCreditView()
}
