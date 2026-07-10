import SwiftUI

struct HomeView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var moonData: MoonData?
    @State private var events: [AstroEvent] = []
    @State private var showMenu = false
    @State private var showPremium = false
    @State private var usingLocalData = false
    @State private var eventsError = false
    @ObservedObject private var daily = DailyReadingService.shared

    private let moonService = MoonService()
    private let astrologyService = AstrologyService()

    var body: some View {
        ZStack {
            if let moonData = moonData {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        moonCharacter(moonData: moonData)
                            .padding(.top, 100)
                        moonInfo(moonData: moonData)
                        dailyReadingCard
                        astroEventsList
                    }
                }
                .ignoresSafeArea(edges: .top)

                VStack {
                    HStack {
                        Button(action: { showMenu = true }) {
                            Text("=")
                                .font(.custom(Theme.titleFont, size: 24))
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
                    Text(L("yıldızlar okunuyor...", "reading the stars..."))
                        .foregroundColor(.white.opacity(0.6))
                        .font(.custom(Theme.bodyFont, size: 15))
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
        .task {
            await daily.load()
        }
    }

    // MARK: - Moon Info

    private func moonInfo(moonData: MoonData) -> some View {
        VStack(spacing: 10) {
            Text(moonData.phase.displayName)
                .font(.custom(Theme.titleFont, size: 12))
                .foregroundColor(Theme.accent)
                .shadow(color: Theme.accent.opacity(0.5), radius: 4)

            Text(L("%\(Int(moonData.illumination)) aydınlık", "\(Int(moonData.illumination))% illuminated"))
                .font(.custom(Theme.bodyFont, size: 14))
                .foregroundColor(.white.opacity(0.6))

            if usingLocalData {
                Text(L("yaklaşık veri (bağlantı yok)", "approximate data (offline)"))
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(.white.opacity(0.3))
            }

            if locationManager.usingDefaultLocation {
                Text(L("varsayılan konum kullanılıyor", "using default location"))
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(.white.opacity(0.3))
            }

            HStack(spacing: 32) {
                HStack(spacing: 6) {
                    pixelIcon("icon_moonrise", size: 18)
                    Text(moonData.moonrise)
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
                HStack(spacing: 6) {
                    pixelIcon("icon_moonset", size: 18)
                    Text(moonData.moonset)
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Astro Events

    private var dailyReadingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("BUGÜNÜN GÖKYÜZÜ", "TODAY'S SKY"))
                .font(.custom(Theme.titleFont, size: 12))
                .foregroundColor(Theme.accent)
                .tracking(2)

            if let text = daily.reading {
                Text(text)
                    .font(.custom(Theme.bodyFont, size: 14))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            } else if daily.isLoading {
                HStack(spacing: 8) {
                    PixelLoading(color: Theme.accent)
                    Text(L("gökyüzü okunuyor...", "reading the sky..."))
                        .font(.custom(Theme.bodyFont, size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            } else if daily.failed {
                Button(action: { Task { await daily.load() } }) {
                    Text(L("Yüklenemedi — tekrar dene", "Couldn't load — try again"))
                        .font(.custom(Theme.bodyFont, size: 13))
                        .foregroundColor(Theme.accent.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    private var astroEventsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !events.isEmpty {
                Text(L("Gökyüzü Olayları", "Sky Events"))
                    .font(.custom(Theme.bodyBoldFont, size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)

                ForEach(events) { event in
                    astroEventRow(event)
                }
            } else if eventsError {
                VStack(spacing: 8) {
                    Text(L("Gökyüzü olayları yüklenemedi", "Couldn't load sky events"))
                        .font(.custom(Theme.bodyFont, size: 14))
                        .foregroundColor(.white.opacity(0.4))
                    Button(action: { Task { await retryEvents() } }) {
                        Text(L("Tekrar dene", "Try again"))
                            .font(.custom(Theme.bodyFont, size: 13))
                            .foregroundColor(Theme.accent.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            } else {
                Text(L("Aktif gökyüzü olayı yok", "No active sky events"))
                    .font(.custom(Theme.bodyFont, size: 14))
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
                        .font(.custom(Theme.bodyBoldFont, size: 16))
                        .foregroundColor(.white)

                    if event.isActive {
                        Text(L("aktif", "active"))
                            .font(.custom(Theme.bodyFont, size: 15))
                            .foregroundColor(Theme.green)
                    }
                }

                Text(event.description)
                    .font(.custom(Theme.bodyFont, size: 15))
                    .foregroundColor(.white.opacity(0.4))

                if !event.dateRangeText.isEmpty {
                    Text(event.dateRangeText)
                        .font(.custom(Theme.bodyFont, size: 13))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer()
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

    private func pixelIcon(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
    }

    // MARK: - Data Loading

    private func loadData() async {
        locationManager.requestLocation()
        moonData = moonService.calculateMoonPhase(date: Date())

        async let eventsTask: () = retryEvents()

        // Wait for location with timeout, no busy-wait polling
        let locationReady = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                while !(await locationManager.hasLocation) {
                    do {
                        try await Task.sleep(nanoseconds: 200_000_000)
                    } catch {
                        return false // cancelled by timeout — stop polling
                    }
                }
                return true
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }

        await eventsTask

        if locationReady || locationManager.hasLocation {
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
        } else {
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
