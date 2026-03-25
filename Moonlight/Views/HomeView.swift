import SwiftUI

struct HomeView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var moonData: MoonData?
    @State private var events: [AstroEvent] = []
    @State private var showMenu = false
    @State private var showPremium = false
    @State private var usingLocalData = false
    @State private var eventsError = false

    private let moonService = MoonService()
    private let astrologyService = AstrologyService()

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "PixelifySans-Regular"
    private let bodyBoldFont = "PixelifySans-SemiBold"
    private let readingFont = "PixelifySans-Regular"

    var body: some View {
        ZStack {
            if let moonData = moonData {
                // Scrollable content on top of shared sky background
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Moon character at the top
                        moonCharacter(moonData: moonData)
                            .padding(.top, 100)

                        // Moon info - no card bg, just text floating
                        moonInfo(moonData: moonData)

                        // Astro events
                        astroEventsList
                    }
                }
                .ignoresSafeArea(edges: .top)

                // Top bar: menu left, credits right
                VStack {
                    HStack {
                        Button(action: { showMenu = true }) {
                            Text("=")
                                .font(.custom(titleFont, size: 24))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(12)
                        }
                        .accessibilityLabel("Menu")
                        Spacer()
                        CreditBadge { showPremium = true }
                            .accessibilityLabel("Credits")
                            .padding(.trailing, 12)
                    }
                    .padding(.top, 50)
                    Spacer()
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("yıldızlar okunuyor...")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.custom(bodyFont, size: 12))
                }
            }
        }
        .sheet(isPresented: $showMenu) {
            SettingsView()
        }
        .sheet(isPresented: $showPremium) {
            NoCreditView()
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Moon Info (no card, just text)

    private func moonInfo(moonData: MoonData) -> some View {
        VStack(spacing: 10) {
            Text(moonData.phase.displayName)
                .font(.custom(titleFont, size: 12))
                .foregroundColor(Color(hex: "#FFE566"))
                .shadow(color: Color(hex: "#FFE566").opacity(0.5), radius: 4)

            Text("%\(Int(moonData.illumination)) aydınlık")
                .font(.custom(bodyFont, size: 14))
                .foregroundColor(.white.opacity(0.6))

            if usingLocalData {
                Text("yaklaşık veri (bağlantı yok)")
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }

            HStack(spacing: 32) {
                HStack(spacing: 6) {
                    pixelIcon("icon_moonrise", size: 18)
                    Text(moonData.moonrise)
                        .font(.custom(bodyFont, size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                HStack(spacing: 6) {
                    pixelIcon("icon_moonset", size: 18)
                    Text(moonData.moonset)
                        .font(.custom(bodyFont, size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Astro Events

    private var astroEventsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !events.isEmpty {
                Text("Gökyüzü Olayları")
                    .font(.custom(titleFont, size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)

                ForEach(events) { event in
                    astroEventRow(event)
                }
            } else if eventsError {
                VStack(spacing: 8) {
                    Text("Gökyüzü olayları yüklenemedi")
                        .font(.custom(bodyFont, size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Button(action: { Task { await retryEvents() } }) {
                        Text("Tekrar dene")
                            .font(.custom(bodyFont, size: 9))
                            .foregroundColor(Color(hex: "#FFE566").opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            } else {
                Text("Aktif gökyüzü olayı yok")
                    .font(.custom(bodyFont, size: 10))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
        }
        .padding(.bottom, 40)
    }

    private func astroEventRow(_ event: AstroEvent) -> some View {
        HStack(spacing: 12) {
            pixelIcon("icon_\(event.type.rawValue)", size: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(.custom(bodyBoldFont, size: 13))
                        .foregroundColor(.white)

                    if event.isActive {
                        Text("aktif")
                            .font(.custom(bodyFont, size: 8))
                            .foregroundColor(Color(hex: "#34D399"))
                    }
                }

                Text(event.description)
                    .font(.custom(readingFont, size: 13))
                    .foregroundColor(.white.opacity(0.4))

                if !event.dateRangeText.isEmpty {
                    Text(event.dateRangeText)
                        .font(.custom(bodyFont, size: 9))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#0b0b2e").opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Moon Character

    private func moonCharacter(moonData: MoonData) -> some View {
        Image(moonData.phase.rawValue)
            .interpolation(.none)
            .resizable()
            .frame(width: 180, height: 180)
            .shadow(color: .yellow.opacity(0.2), radius: 20)
    }

    // MARK: - Helpers

    private func pixelIcon(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
    }

    private func loadData() async {
        locationManager.requestLocation()

        // Quick local fallback while API loads
        moonData = moonService.calculateMoonPhase(date: Date())

        // Load events
        await retryEvents()

        // Wait for location (max 5 seconds), then fetch real API data
        var waitAttempts = 0
        while !locationManager.hasLocation && waitAttempts < 50 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            waitAttempts += 1
        }

        do {
            let apiData = try await moonService.fetchMoonData(
                latitude: locationManager.latitude,
                longitude: locationManager.longitude
            )
            moonData = apiData
            usingLocalData = false
        } catch {
            usingLocalData = true
        }
    }

    private func retryEvents() async {
        do {
            events = try await astrologyService.fetchEvents()
            eventsError = false
        } catch {
            eventsError = true
        }
    }
}

#Preview {
    HomeView()
}
