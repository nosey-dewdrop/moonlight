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

                PlaceholderView(title: "Horary", description: "Ask the stars")
                    .tag(1)

                PlaceholderView(title: "Astrology", description: "Birth chart")
                    .tag(2)

                PlaceholderView(title: "Tarot", description: "Daily card")
                    .tag(3)

                PlaceholderView(title: "Dictionary", description: "Terms")
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .ignoresSafeArea()
        .task {
            moonData = moonService.calculateMoonPhase(date: Date())
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.custom("PressStart2P-Regular", size: 16))
                .foregroundColor(Color(hex: "#FFE566"))

            Text(description)
                .font(.custom("Silkscreen-Regular", size: 14))
                .foregroundColor(.white.opacity(0.5))

            Text("coming soon")
                .font(.custom("Silkscreen-Regular", size: 10))
                .foregroundColor(.white.opacity(0.3))
                .padding(.top, 8)
        }
    }
}

#Preview {
    ContentView()
}
