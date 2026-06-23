import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var userProfile = UserProfile.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var notif = NotificationManager.shared
    @State private var showHistory = false
    @State private var moonData: MoonData?

    private let moonService = MoonService()

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            // Pixel art sky background
            if let moonData = moonData {
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
                                .font(.custom(Theme.titleFont, size: 10))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(8)
                        }
                        .accessibilityLabel("Close")
                        Spacer()
                        Text(L("Ayarlar", "Settings"))
                            .font(.custom(Theme.titleFont, size: 24))
                            .foregroundColor(Theme.accent)
                        Spacer()
                        Color.clear.frame(width: 28)
                    }
                    .padding(.top, 60)

                    // Language section
                    languageSection

                    // Notifications section
                    notificationsSection

                    // Birth chart section
                    birthChartSection

                    // Credits section
                    creditsSection

                    // Purchase section
                    purchaseSection

                    // Reading History
                    Button(action: { showHistory = true }) {
                        HStack {
                            Text(L("Okuma Geçmişi", "Reading History"))
                                .font(.custom(Theme.bodyFont, size: 15))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(">")
                                .font(.custom(Theme.titleFont, size: 16))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.bg.opacity(0.85))
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
            moonData = moonService.calculateMoonPhase(date: Date())
            await creditManager.loadProducts()
            await notif.refreshAuthorizationStatus()
        }
        .sheet(isPresented: $showHistory) {
            ReadingHistoryView()
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Dil", "Language"))
                .font(.custom(Theme.titleFont, size: 16))
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 10) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    let isSelected = loc.language == lang

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            loc.language = lang
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(lang.flag)
                                .font(.system(size: 18))
                            Text(lang.displayName)
                                .font(.custom(Theme.bodyBoldFont, size: 15))
                                .foregroundColor(isSelected ? Theme.bg : .white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected ? Theme.accent : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(isSelected ? Theme.accent : Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .accessibilityLabel(lang.displayName)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Bildirimler", "Notifications"))
                .font(.custom(Theme.titleFont, size: 16))
                .foregroundColor(.white.opacity(0.8))

            if notif.authorizationStatus == .denied {
                Text(L("Bildirimler kapalı. Açmak için telefon ayarlarından izin ver.",
                       "Notifications are off. Enable them in your phone settings."))
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(.white.opacity(0.5))
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text(L("Ayarları Aç", "Open Settings"))
                        .font(.custom(Theme.bodyBoldFont, size: 14))
                        .foregroundColor(Theme.accent)
                }
            } else if !notif.masterEnabled {
                Button(action: {
                    Task { await notif.requestAuthorization() }
                }) {
                    Text(L("Bildirimleri Aç", "Turn On Notifications"))
                        .font(.custom(Theme.bodyBoldFont, size: 15))
                        .foregroundColor(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.accent))
                }
            } else {
                notifToggle(L("Ay fazı değişimi", "Moon phase changes"), isOn: $notif.phaseChanges)
                notifToggle(L("Günlük hatırlatma", "Daily reminder"), isOn: $notif.dailyReminder)
                notifToggle(L("Özel gökyüzü olayları", "Special sky events"), isOn: $notif.astroEvents)
                notifToggle(L("Krediler yenilenince", "When credits refresh"), isOn: $notif.creditsRefresh)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func notifToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.custom(Theme.bodyFont, size: 15))
                .foregroundColor(.white.opacity(0.7))
        }
        .tint(Theme.accent)
    }

    // MARK: - Birth Chart

    private var birthChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Doğum Haritası", "Birth Chart"))
                .font(.custom(Theme.titleFont, size: 16))
                .foregroundColor(.white.opacity(0.8))

            zodiacPicker(L("Güneş Burcu", "Sun Sign"), selection: $userProfile.sunSign)
            zodiacPicker(L("Yükselen Burç", "Rising Sign"), selection: $userProfile.risingSign)
            zodiacPicker(L("Ay Burcu", "Moon Sign"), selection: $userProfile.moonSign)

            // Birth time
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Doğum Saati", "Birth Time"))
                    .font(.custom(Theme.bodyFont, size: 14))
                    .foregroundColor(.white.opacity(0.5))

                if let time = userProfile.birthTime {
                    HStack {
                        Text(Theme.timeFormatter.string(from: time))
                            .font(.custom(Theme.bodyBoldFont, size: 15))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: { userProfile.birthTime = nil }) {
                            Text("x")
                                .font(.custom(Theme.titleFont, size: 16))
                                .foregroundColor(Theme.error)
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
                .fill(Theme.bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func zodiacPicker(_ label: String, selection: Binding<ZodiacSign?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom(Theme.bodyFont, size: 14))
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
                                        .fill(isSelected ? Theme.accent.opacity(0.3) : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 2)
                                                .stroke(isSelected ? Theme.accent : Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }
                        .accessibilityLabel(sign.displayName)
                    }
                }
            }

            if let sign = selection.wrappedValue {
                Text(sign.displayName)
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(Theme.accent.opacity(0.7))
            }
        }
    }

    // MARK: - Credits

    private var creditsSection: some View {
        VStack(spacing: 8) {
            Text(L("Krediler", "Credits"))
                .font(.custom(Theme.titleFont, size: 16))
                .foregroundColor(.white.opacity(0.8))

            Text("\(creditManager.totalCredits)")
                .font(.custom(Theme.titleFont, size: 24))
                .foregroundColor(Theme.accent)
                .shadow(color: Theme.accent.opacity(0.5), radius: 6)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(creditManager.dailyCreditsRemaining)")
                        .font(.custom(Theme.bodyBoldFont, size: 15))
                        .foregroundColor(.white)
                    Text(L("günlük ücretsiz", "daily free"))
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.4))
                }

                VStack(spacing: 2) {
                    Text("\(creditManager.purchasedCredits)")
                        .font(.custom(Theme.bodyBoldFont, size: 15))
                        .foregroundColor(.white)
                    Text(L("satın alınan", "purchased"))
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 10) {
            Text(L("Kredi Al", "Get Credits"))
                .font(.custom(Theme.titleFont, size: 16))
                .foregroundColor(.white.opacity(0.8))

            if creditManager.products.isEmpty {
                ForEach(CreditManager.fallbackProducts) { product in
                    purchaseRow(name: product.name, price: product.price, credits: product.credits)
                }

                Text(L("Mağaza yükleniyor...", "Loading store..."))
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(.white.opacity(0.3))
            } else {
                ForEach(creditManager.products) { product in
                    let credits = CreditManager.creditsForProduct(product.id)
                    Button(action: {
                        Task { await creditManager.purchase(product) }
                    }) {
                        purchaseRow(name: L("\(credits) Kredi", "\(credits) Credits"), price: product.displayPrice, credits: credits)
                    }
                    .disabled(creditManager.purchaseInProgress)
                }
            }

            if creditManager.purchaseInProgress {
                HStack(spacing: 8) {
                    PixelLoading(color: Theme.accent)
                    Text(L("İşleniyor...", "Processing..."))
                        .font(.custom(Theme.bodyFont, size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            if let error = creditManager.purchaseError {
                Text(error)
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(Theme.error.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            PixelButton(L("Satın Alımları Geri Yükle", "Restore Purchases"), style: .secondary) {
                Task { await creditManager.restorePurchases() }
            }
        }
    }

    private func purchaseRow(name: String, price: String, credits: Int) -> some View {
        HStack {
            Text(name)
                .font(.custom(Theme.bodyBoldFont, size: 15))
                .foregroundColor(.white)

            Spacer()

            Text(price)
                .font(.custom(Theme.bodyBoldFont, size: 15))
                .foregroundColor(Theme.accent)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.bg.opacity(0.85))
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
                    Text(L("Gizlilik Politikası", "Privacy Policy"))
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(">")
                        .font(.custom(Theme.titleFont, size: 16))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.bg.opacity(0.85))
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
                    Text(L("Kullanım Koşulları", "Terms of Use"))
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(">")
                        .font(.custom(Theme.titleFont, size: 16))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.bg.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }

            Text("Moonlight v1.0")
                .font(.custom(Theme.bodyFont, size: 13))
                .foregroundColor(.white.opacity(0.2))
                .padding(.top, 4)
        }
    }

}

#Preview {
    SettingsView()
}
