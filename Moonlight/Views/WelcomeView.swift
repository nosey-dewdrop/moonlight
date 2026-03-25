import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showCredits = false
    @State private var showButton = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                if showContent {
                    Text("Hoş geldin")
                        .font(.custom(Theme.bodyFont, size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .transition(.opacity)

                    Text("Moonlight")
                        .font(.custom(Theme.titleFont, size: 20))
                        .foregroundColor(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.6), radius: 8)
                        .transition(.opacity)

                    Text("Ay seni dinliyor.")
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.4))
                        .transition(.opacity)
                }

                if showCredits {
                    VStack(spacing: 12) {
                        Text("10")
                            .font(.custom(Theme.titleFont, size: 36))
                            .foregroundColor(Theme.accent)
                            .shadow(color: Theme.accent.opacity(0.5), radius: 10)

                        Text("başlangıç kredisi")
                            .font(.custom(Theme.bodyFont, size: 15))
                            .foregroundColor(.white.opacity(0.6))

                        Text("+ her gün 3 ücretsiz kredi")
                            .font(.custom(Theme.bodyFont, size: 14))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.bg.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Spacer()

                if showButton {
                    PixelButton("Başla") {
                        dismiss()
                    }
                    .transition(.opacity)
                    .padding(.bottom, 60)
                }
            }
            .padding(.horizontal, 32)
        }
        .task {
            withAnimation(.easeIn(duration: 0.6)) {
                showContent = true
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            withAnimation(.easeIn(duration: 0.5)) {
                showCredits = true
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeIn(duration: 0.4)) {
                showButton = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}
