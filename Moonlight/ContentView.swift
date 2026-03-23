import SwiftUI

let moonlightBg = Color(hex: "#0b0b2e")

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var moonData: MoonData?

    private let moonService = MoonService()

    var body: some View {
        ZStack {
            moonlightBg.ignoresSafeArea()

            // Shared sky background behind all tabs (clouds + stars only, no moon)
            if let moonData = moonData {
                MoonSceneView(moonData: moonData, showMoon: false)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                TarotView()
                    .tag(1)

                HoraryView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .ignoresSafeArea()
        .task {
            // Quick local calculation first
            moonData = moonService.calculateMoonPhase(date: Date())
            // Then try real API
            if let apiData = try? await moonService.fetchMoonData(latitude: 41.01, longitude: 28.98) {
                moonData = apiData
            }
        }
    }
}

#Preview {
    ContentView()
}
