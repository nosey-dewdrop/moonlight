import SwiftUI

struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var moonData: MoonData?
    @State private var events: [AstroEvent] = []
    @State private var isLoading = true

    private let moonService = MoonService()
    private let astrologyService = AstrologyService()

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#0a0a1a")
                .ignoresSafeArea()

            if let moonData = moonData {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Moon scene
                        MoonSceneView(moonData: moonData)
                            .frame(height: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 0))

                        // Moon info card
                        moonInfoCard(moonData: moonData)
                            .padding(.top, -20)

                        // Astro events
                        astroEventsList
                            .padding(.top, 16)
                    }
                }
                .ignoresSafeArea(edges: .top)
            } else {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Reading the stars...")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.custom("Georgia", size: 16))
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Moon Info Card

    private func moonInfoCard(moonData: MoonData) -> some View {
        VStack(spacing: 12) {
            // Phase name
            Text(moonData.phase.displayName)
                .font(.custom("Georgia-Bold", size: 28))
                .foregroundColor(.white)

            // Illumination
            Text("\(Int(moonData.illumination))% illuminated")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.white.opacity(0.7))

            // Moonrise / Moonset
            HStack(spacing: 32) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle")
                        .foregroundColor(Color(hex: "#FFE566"))
                    Text(moonData.moonrise)
                        .foregroundColor(.white.opacity(0.8))
                }

                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(Color(hex: "#A78BFA"))
                    Text(moonData.moonset)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .font(.custom("Georgia", size: 14))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Astro Events List

    private var astroEventsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cosmic Events")
                .font(.custom("Georgia-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            ForEach(events) { event in
                astroEventRow(event)
            }
        }
        .padding(.bottom, 32)
    }

    private func astroEventRow(_ event: AstroEvent) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: event.type.icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: event.type.color))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(hex: event.type.color).opacity(0.15))
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.custom("Georgia-Bold", size: 15))
                        .foregroundColor(.white)

                    if event.isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#34D399"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#34D399").opacity(0.15))
                            )
                    }
                }

                Text(event.description)
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(.white.opacity(0.5))

                if !event.dateRangeText.isEmpty {
                    Text(event.dateRangeText)
                        .font(.custom("Georgia", size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Data Loading

    private func loadData() async {
        // Calculate moon phase
        moonData = moonService.calculateMoonPhase(date: Date())

        // Load astro events
        do {
            events = try await astrologyService.fetchEvents()
        } catch {
            print("Failed to load events: \(error)")
        }

        // Request location for future API calls
        locationManager.requestLocation()
    }
}

#Preview {
    HomeView()
}
