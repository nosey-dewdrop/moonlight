import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var userProfile = UserProfile.shared
    @State private var showHistory = false

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    private let moonService = MoonService()

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            // Pixel art sky background
            if let moonData = moonService.calculateMoonPhase(date: Date()) as MoonData? {
                MoonSceneView(moonData: moonData, showMoon: false)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Text("X")
                                .font(.custom(titleFont, size: 10))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(8)
                        }
                        .accessibilityLabel("Close")
                        Spacer()
                        Text("Settings")
                            .font(.custom(titleFont, size: 14))
                            .foregroundColor(accent)
                        Spacer()
                        Color.clear.frame(width: 28)
                    }
                    .padding(.top, 60)

                    // Birth chart section
                    birthChartSection

                    // Credits section
                    creditsSection

                    // Purchase section
                    purchaseSection

                    // Reading History
                    Button(action: { showHistory = true }) {
                        HStack {
                            Text("Reading History")
                                .font(.custom(bodyFont, size: 11))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(">")
                                .font(.custom(titleFont, size: 8))
                                .foregroundColor(.white.opacity(0.3))
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

                    // Legal
                    legalSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
        }
        .task {
            await creditManager.loadProducts()
        }
        .sheet(isPresented: $showHistory) {
            ReadingHistoryView()
        }
    }

    // MARK: - Birth Chart

    private var birthChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Birth Chart")
                .font(.custom(titleFont, size: 8))
                .foregroundColor(.white.opacity(0.8))

            zodiacPicker("Sun Sign", selection: $userProfile.sunSign)
            zodiacPicker("Rising Sign", selection: $userProfile.risingSign)
            zodiacPicker("Moon Sign", selection: $userProfile.moonSign)

            // Birth time
            VStack(alignment: .leading, spacing: 4) {
                Text("Birth Time")
                    .font(.custom(bodyFont, size: 10))
                    .foregroundColor(.white.opacity(0.5))

                if let time = userProfile.birthTime {
                    HStack {
                        Text({
                            let f = DateFormatter()
                            f.dateFormat = "HH:mm"
                            return f.string(from: time)
                        }())
                            .font(.custom(bodyBoldFont, size: 12))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: { userProfile.birthTime = nil }) {
                            Text("x")
                                .font(.custom(titleFont, size: 8))
                                .foregroundColor(Color(hex: "#FF6B6B"))
                        }
                    }
                } else {
                    DatePicker("", selection: Binding(
                        get: { userProfile.birthTime ?? Date() },
                        set: { userProfile.birthTime = $0 }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .colorScheme(.dark)
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

    private func zodiacPicker(_ label: String, selection: Binding<ZodiacSign?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom(bodyFont, size: 10))
                .foregroundColor(.white.opacity(0.5))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ZodiacSign.allCases, id: \.self) { sign in
                        let isSelected = selection.wrappedValue == sign

                        Button(action: {
                            selection.wrappedValue = isSelected ? nil : sign
                        }) {
                            Text(sign.emoji)
                                .font(.system(size: 18))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(isSelected ? accent.opacity(0.3) : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 2)
                                                .stroke(isSelected ? accent : Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }
                        .accessibilityLabel(sign.displayName)
                    }
                }
            }

            if let sign = selection.wrappedValue {
                Text(sign.displayName)
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(accent.opacity(0.7))
            }
        }
    }

    // MARK: - Credits

    private var creditsSection: some View {
        VStack(spacing: 8) {
            Text("Credits")
                .font(.custom(titleFont, size: 8))
                .foregroundColor(.white.opacity(0.8))

            Text("\(creditManager.totalCredits)")
                .font(.custom(titleFont, size: 24))
                .foregroundColor(accent)
                .shadow(color: accent.opacity(0.5), radius: 6)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(creditManager.dailyCreditsRemaining)")
                        .font(.custom(bodyBoldFont, size: 12))
                        .foregroundColor(.white)
                    Text("daily free")
                        .font(.custom(bodyFont, size: 8))
                        .foregroundColor(.white.opacity(0.4))
                }

                VStack(spacing: 2) {
                    Text("\(creditManager.purchasedCredits)")
                        .font(.custom(bodyBoldFont, size: 12))
                        .foregroundColor(.white)
                    Text("purchased")
                        .font(.custom(bodyFont, size: 8))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
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
                ForEach(CreditManager.fallbackProducts) { product in
                    purchaseRow(name: product.name, price: product.price, credits: product.credits)
                }

                Text("Loading store...")
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(.white.opacity(0.3))
            } else {
                ForEach(creditManager.products) { product in
                    let credits = CreditManager.creditsForProduct(product.id)
                    Button(action: {
                        Task { await creditManager.purchase(product) }
                    }) {
                        purchaseRow(name: "\(credits) Credits", price: product.displayPrice, credits: credits)
                    }
                    .disabled(creditManager.purchaseInProgress)
                }
            }

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
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 10) {
            Button(action: {
                if let url = URL(string: "https://nosey-dewdrop.github.io/moonlight/privacy-policy.html") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("Privacy Policy")
                        .font(.custom(bodyFont, size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(">")
                        .font(.custom(titleFont, size: 8))
                        .foregroundColor(.white.opacity(0.3))
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

            Button(action: {
                if let url = URL(string: "https://nosey-dewdrop.github.io/moonlight/terms.html") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("Terms of Service")
                        .font(.custom(bodyFont, size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(">")
                        .font(.custom(titleFont, size: 8))
                        .foregroundColor(.white.opacity(0.3))
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

            Text("Moonlight v1.0")
                .font(.custom(bodyFont, size: 9))
                .foregroundColor(.white.opacity(0.2))
                .padding(.top, 4)
        }
    }

}

#Preview {
    SettingsView()
}
