import SwiftUI

struct NoCreditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditManager = CreditManager.shared

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    private let moonService = MoonService()

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            if let moonData = moonService.calculateMoonPhase(date: Date()) as MoonData? {
                MoonSceneView(moonData: moonData, showMoon: false)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

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
                        ForEach(CreditManager.fallbackProducts) { product in
                            purchaseRow(name: product.name, price: product.price, credits: product.credits, isAvailable: false)
                        }

                        Text("Loading store...")
                            .font(.custom(bodyFont, size: 9))
                            .foregroundColor(.white.opacity(0.3))
                    } else {
                        ForEach(creditManager.products, id: \.id) { product in
                            let credits = CreditManager.creditsForProduct(product.id)
                            Button(action: {
                                Task { await creditManager.purchase(product) }
                            }) {
                                purchaseRow(name: "\(credits) Credits", price: product.displayPrice, credits: credits, isAvailable: true)
                            }
                            .disabled(creditManager.purchaseInProgress)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if creditManager.purchaseInProgress {
                    HStack(spacing: 8) {
                        PixelLoading(color: accent)
                        Text("Processing...")
                            .font(.custom(bodyFont, size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                if let error = creditManager.purchaseError {
                    Text(error)
                        .font(.custom(bodyFont, size: 9))
                        .foregroundColor(Color(hex: "#FF6B6B").opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

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

    private func purchaseRow(name: String, price: String, credits: Int, isAvailable: Bool) -> some View {
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
        .opacity(isAvailable ? 1.0 : 0.5)
    }
}

#Preview {
    NoCreditView()
}
