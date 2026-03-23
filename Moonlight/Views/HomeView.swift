import SwiftUI

struct HomeView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var moonData: MoonData?
    @State private var events: [AstroEvent] = []
    @State private var showSettings = false
    @State private var showPremium = false

    private let moonService = MoonService()
    private let astrologyService = AstrologyService()

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"

    var body: some View {
        ZStack {
            if let moonData = moonData {
                // Scrollable content on top of shared sky background
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Moon character at the top
                        moonCharacter(moonData: moonData)
                            .padding(.top, UIScreen.main.bounds.height * 0.12)

                        // Moon info - no card bg, just text floating
                        moonInfo(moonData: moonData)

                        // Astro events
                        astroEventsList
                    }
                }
                .ignoresSafeArea(edges: .top)

                // Top bar: settings left, credits right
                VStack {
                    HStack {
                        Button(action: { showSettings = true }) {
                            Text("*")
                                .font(.custom(titleFont, size: 14))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(12)
                        }
                        .accessibilityLabel("Settings")
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
                    Text("reading the stars...")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.custom(bodyFont, size: 12))
                }
            }
        }
        .sheet(isPresented: $showSettings) {
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

            Text("\(Int(moonData.illumination))% illuminated")
                .font(.custom(bodyFont, size: 14))
                .foregroundColor(.white.opacity(0.6))

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
            Text("Cosmic Events")
                .font(.custom(titleFont, size: 8))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 20)

            ForEach(events) { event in
                astroEventRow(event)
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
                        Text("active")
                            .font(.custom(bodyFont, size: 8))
                            .foregroundColor(Color(hex: "#34D399"))
                    }
                }

                Text(event.description)
                    .font(.custom(bodyFont, size: 10))
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
        // Request location first
        locationManager.requestLocation()

        // Quick local fallback while API loads
        moonData = moonService.calculateMoonPhase(date: Date())

        // Load events
        do {
            events = try await astrologyService.fetchEvents()
        } catch {
            print("Failed to load events: \(error)")
        }

        // Wait briefly for location, then fetch real API data
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Always try API with real location
        do {
            let apiData = try await moonService.fetchMoonData(
                latitude: locationManager.latitude,
                longitude: locationManager.longitude
            )
            moonData = apiData
        } catch {
            print("USNO API failed, using local calculation: \(error)")
        }
    }
}

#Preview {
    HomeView()
}
