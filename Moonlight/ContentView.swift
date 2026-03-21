import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)

            // Placeholder tabs for future features
            PlaceholderView(title: "Horary", icon: "questionmark.circle", description: "Ask the stars a question")
                .tag(1)

            PlaceholderView(title: "Astrology", icon: "sparkles", description: "Birth chart & transits")
                .tag(2)

            PlaceholderView(title: "Tarot", icon: "rectangle.stack", description: "Daily card draw")
                .tag(3)

            PlaceholderView(title: "Dictionary", icon: "book", description: "Astrology terms")
                .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        ZStack {
            Color(hex: "#0a0a1a")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "#A78BFA"))

                Text(title)
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(.white)

                Text(description)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.5))

                Text("Coming soon")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    ContentView()
}
