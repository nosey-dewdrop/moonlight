import SwiftUI

let moonlightBg = Color(hex: "#0b0b2e")

struct ContentView: View {
    @State private var selectedTab = 1
    @State private var moonData: MoonData?
    @State private var showWelcome = false
    @ObservedObject private var creditManager = CreditManager.shared

    private let titleFont = "PressStart2P-Regular"
    private let accent = Color(hex: "#FFE566")
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
                TarotView()
                    .tabItem {
                        Image(systemName: "suit.diamond")
                        Text("Tarot")
                    }
                    .tag(0)

                HomeView()
                    .tabItem {
                        Image(systemName: "moon.stars")
                        Text("Moon")
                    }
                    .tag(1)

                HoraryView()
                    .tabItem {
                        Image(systemName: "sparkles")
                        Text("Horary")
                    }
                    .tag(2)
            }
            .tint(accent)
        }
        .ignoresSafeArea(edges: .top)
        .task {
            moonData = moonService.calculateMoonPhase(date: Date())
        }
        .onAppear {
            // Style the tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(moonlightBg.opacity(0.95))
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.4)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(accent)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance

            if creditManager.isFirstLaunch {
                showWelcome = true
            }
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView()
        }
    }
}

#Preview {
    ContentView()
}
