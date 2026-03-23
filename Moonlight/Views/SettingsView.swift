import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditManager = CreditManager.shared
    @State private var apiKeyInput = ""
    @State private var showApiKey = false
    @State private var hasApiKey = false

    private let claudeService = ClaudeService()

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Text("Settings")
                            .font(.custom(titleFont, size: 14))
                            .foregroundColor(accent)
                        Spacer()
                        Color.clear.frame(width: 16)
                    }
                    .padding(.top, 60)

                    // API Key section
                    apiKeySection

                    // Credits section
                    creditsSection

                    // Purchase section
                    purchaseSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            hasApiKey = claudeService.hasApiKey
        }
        .task {
            await creditManager.loadProducts()
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Claude API Key")
                .font(.custom(titleFont, size: 8))
                .foregroundColor(.white.opacity(0.8))

            if hasApiKey {
                HStack {
                    Text(showApiKey ? (claudeService.apiKey ?? "") : "sk-ant-••••••••••••")
                        .font(.custom(bodyFont, size: 10))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)

                    Spacer()

                    Button(action: { showApiKey.toggle() }) {
                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Button(action: removeKey) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#FF6B6B"))
                    }
                }
            } else {
                HStack(spacing: 8) {
                    TextField("", text: $apiKeyInput, prompt:
                        Text("sk-ant-...")
                            .foregroundColor(.white.opacity(0.2))
                            .font(.custom(bodyFont, size: 11))
                    )
                    .font(.custom(bodyFont, size: 11))
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button(action: saveKey) {
                        Text("Save")
                            .font(.custom(bodyBoldFont, size: 10))
                            .foregroundColor(bg)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(accent)
                            .cornerRadius(4)
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Credits

    private var creditsSection: some View {
        VStack(spacing: 8) {
            Text("Credits")
                .font(.custom(titleFont, size: 8))
                .foregroundColor(.white.opacity(0.8))

            Text("\(creditManager.credits)")
                .font(.custom(titleFont, size: 24))
                .foregroundColor(accent)
                .shadow(color: accent.opacity(0.5), radius: 6)

            Text("1 credit = 1 AI reading")
                .font(.custom(bodyFont, size: 9))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(accent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 10) {
            Text("Buy Credits")
                .font(.custom(titleFont, size: 8))
                .foregroundColor(.white.opacity(0.8))

            if creditManager.products.isEmpty {
                // Fallback display when products haven't loaded (sandbox/dev)
                ForEach(fallbackProducts, id: \.id) { product in
                    purchaseRow(name: product.name, price: product.price, credits: product.credits)
                }
            } else {
                ForEach(creditManager.products) { product in
                    let credits = CreditManager.creditsForProduct(product.id)
                    Button(action: {
                        Task { try? await creditManager.purchase(product) }
                    }) {
                        purchaseRow(name: "\(credits) Credits", price: product.displayPrice, credits: credits)
                    }
                    .disabled(creditManager.purchaseInProgress)
                }
            }

            Button(action: {
                Task { await creditManager.restorePurchases() }
            }) {
                Text("Restore Purchases")
                    .font(.custom(bodyFont, size: 10))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 8)
            }
        }
    }

    private func purchaseRow(name: String, price: String, credits: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom(bodyBoldFont, size: 12))
                    .foregroundColor(.white)
                Text("\(credits) AI readings")
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Text(price)
                .font(.custom(bodyBoldFont, size: 12))
                .foregroundColor(accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(accent.opacity(0.5), lineWidth: 1)
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func saveKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        claudeService.saveApiKey(key)
        apiKeyInput = ""
        hasApiKey = true
    }

    private func removeKey() {
        claudeService.removeApiKey()
        hasApiKey = false
        showApiKey = false
    }

    // MARK: - Fallback products for dev/sandbox

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
    SettingsView()
}
