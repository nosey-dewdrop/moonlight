import SwiftUI

/// Branded loading screen shown over the app while the first data loads,
/// so the user sees Moonlight instead of a black screen.
struct SplashView: View {
    @State private var glow = false
    @State private var appear = false

    var body: some View {
        ZStack {
            Color(hex: "#0b0b2e").ignoresSafeArea()

            // Soft starfield wash
            RadialGradient(
                colors: [Theme.purpleAccent.opacity(0.18), .clear],
                center: .center, startRadius: 10, endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("full_moon")
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .shadow(color: Theme.accent.opacity(glow ? 0.7 : 0.3),
                            radius: glow ? 28 : 14)
                    .scaleEffect(appear ? 1 : 0.85)
                    .opacity(appear ? 1 : 0)

                Text("Moonlight")
                    .font(.custom(Theme.titleFont, size: 22))
                    .foregroundColor(Theme.accent)
                    .opacity(appear ? 1 : 0)

                Text("✦")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(glow ? 0.8 : 0.3))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

#Preview {
    SplashView()
}
