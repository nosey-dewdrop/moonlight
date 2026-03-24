import SwiftUI

let moonlightBg = Color(hex: "#0b0b2e")

struct ContentView: View {
    @State private var selectedTab = 1
    @State private var moonData: MoonData?
    @State private var showWelcome = false
    @ObservedObject private var creditManager = CreditManager.shared

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let accent = Color(hex: "#FFE566")
    private let moonService = MoonService()

    var body: some View {
        ZStack {
            moonlightBg.ignoresSafeArea()

            // Shared sky background behind all tabs
            if let moonData = moonData {
                MoonSceneView(moonData: moonData, showMoon: false)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Page-style swipe tabs (transparent background)
                TabView(selection: $selectedTab) {
                    TarotView()
                        .tag(0)

                    HomeView()
                        .tag(1)

                    HoraryView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom pixel tab bar
                HStack {
                    tabButton(icon: "tarot", label: "Tarot", tag: 0)
                    Spacer()
                    tabButton(icon: "moon", label: "Moon", tag: 1)
                    Spacer()
                    tabButton(icon: "horary", label: "Horary", tag: 2)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .background(moonlightBg.opacity(0.95))
            }
        }
        .ignoresSafeArea()
        .task {
            moonData = moonService.calculateMoonPhase(date: Date())
        }
        .onAppear {
            if creditManager.isFirstLaunch {
                showWelcome = true
            }
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView()
        }
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tag }
        }) {
            VStack(spacing: 4) {
                Text(tabIcon(for: icon))
                    .font(.custom(titleFont, size: 12))
                    .foregroundColor(selectedTab == tag ? accent : .white.opacity(0.3))

                Text(label)
                    .font(.custom(bodyFont, size: 8))
                    .foregroundColor(selectedTab == tag ? accent : .white.opacity(0.3))
            }
        }
    }

    private func tabIcon(for name: String) -> String {
        switch name {
        case "tarot": return "<>"
        case "moon": return "()"
        case "horary": return "**"
        default: return "?"
        }
    }
}

#Preview {
    ContentView()
}
