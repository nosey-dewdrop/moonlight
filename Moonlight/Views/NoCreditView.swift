import SwiftUI

struct NoCreditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditManager = CreditManager.shared

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "PixelifySans-Regular"
    private let bodyBoldFont = "PixelifySans-SemiBold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    private let moonService = MoonService()

    @State private var saturnOffset: CGFloat = 0
    @State private var venusOffset: CGFloat = 0
    @State private var marsRotation: Double = 0
    @State private var sparkleOpacity1: Double = 0.3
    @State private var sparkleOpacity2: Double = 0.6

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            if let moonData = moonService.calculateMoonPhase(date: Date()) as MoonData? {
                MoonSceneView(moonData: moonData, showMoon: false)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Floating planets
            GeometryReader { geo in
                // Saturn top-right (star of the show)
                Image("planet_saturn")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .opacity(0.8)
                    .offset(y: saturnOffset)
                    .position(x: geo.size.width * 0.78, y: geo.size.height * 0.06)

                // Jupiter top-left
                Image("planet_jupiter")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 72, height: 72)
                    .opacity(0.6)
                    .position(x: geo.size.width * 0.08, y: geo.size.height * 0.08)

                // Venus bottom-right
                Image("planet_venus")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 52, height: 52)
                    .opacity(0.65)
                    .offset(y: venusOffset)
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.82)

                // Mars bottom-left
                Image("planet_mars")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .opacity(0.55)
                    .rotationEffect(.degrees(marsRotation))
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.88)

                // Neptune mid-left
                Image("planet_neptune")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .opacity(0.5)
                    .position(x: geo.size.width * 0.05, y: geo.size.height * 0.5)

                // Sparkles - top area only
                Image("sparkle_gold")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 36, height: 36)
                    .opacity(sparkleOpacity1)
                    .position(x: geo.size.width * 0.35, y: geo.size.height * 0.05)

                Image("sparkle_blue")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .opacity(sparkleOpacity2)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.14)

                Image("sparkle_gold")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .opacity(sparkleOpacity2)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.18)

                Image("sparkle_blue")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .opacity(sparkleOpacity1)
                    .position(x: geo.size.width * 0.7, y: geo.size.height * 0.9)

            }
            .allowsHitTesting(false)

            // Content
            VStack(spacing: 20) {
                Spacer()

                // Coin icon
                ZStack {
                    VStack(spacing: 0) {
                        Rectangle().fill(accent).frame(width: 20, height: 4)
                        Rectangle().fill(accent).frame(width: 28, height: 4)
                        Rectangle().fill(accent).frame(width: 28, height: 4)
                        Rectangle().fill(accent).frame(width: 28, height: 4)
                        Rectangle().fill(accent).frame(width: 28, height: 4)
                        Rectangle().fill(accent).frame(width: 28, height: 4)
                        Rectangle().fill(accent).frame(width: 20, height: 4)
                    }
                    VStack(spacing: 0) {
                        Rectangle().fill(Color(hex: "#D4A017")).frame(width: 12, height: 4)
                        Rectangle().fill(Color(hex: "#D4A017")).frame(width: 20, height: 4)
                        Rectangle().fill(Color(hex: "#D4A017")).frame(width: 20, height: 4)
                        Rectangle().fill(Color(hex: "#D4A017")).frame(width: 12, height: 4)
                    }
                    Rectangle().fill(accent).frame(width: 12, height: 4)
                    Rectangle().fill(accent).frame(width: 4, height: 12)
                }
                .frame(width: 28, height: 28)
                .shadow(color: accent.opacity(0.4), radius: 8)

                Text("Kredin Bitti")
                    .font(.custom(titleFont, size: 16))
                    .foregroundColor(accent)
                    .shadow(color: accent.opacity(0.5), radius: 6)

                Text("Yıldızlar seni bekliyor.\nOkumaya devam et.")
                    .font(.custom(bodyFont, size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // Purchase options
                VStack(spacing: 10) {
                    if creditManager.products.isEmpty {
                        ForEach(CreditManager.fallbackProducts) { product in
                            purchaseRow(name: product.name, price: product.price, credits: product.credits, isAvailable: false)
                        }

                        Text("Mağaza yükleniyor...")
                            .font(.custom(bodyFont, size: 13))
                            .foregroundColor(.white.opacity(0.3))
                    } else {
                        ForEach(creditManager.products, id: \.id) { product in
                            let credits = CreditManager.creditsForProduct(product.id)
                            Button(action: {
                                Task { await creditManager.purchase(product) }
                            }) {
                                purchaseRow(name: "\(credits) Credits", price: product.displayPrice, credits: credits, isAvailable: true)
                            }
                            .disabled(creditManager.purchaseInProgress)
                        }
                    }
                }
                .padding(.horizontal, 20)

                if creditManager.purchaseInProgress {
                    HStack(spacing: 8) {
                        PixelLoading(color: accent)
                        Text("İşleniyor...")
                            .font(.custom(bodyFont, size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                if let error = creditManager.purchaseError {
                    Text(error)
                        .font(.custom(bodyFont, size: 13))
                        .foregroundColor(Color(hex: "#FF6B6B").opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                PixelButton("Satın Alımları Geri Yükle", style: .secondary) {
                    Task { await creditManager.restorePurchases() }
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Kapat")
                        .font(.custom(bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 40)
                }
                .accessibilityLabel("Close")
            }
        }
        .task {
            await creditManager.loadProducts()
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                saturnOffset = 8
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                venusOffset = -6
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                marsRotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                sparkleOpacity1 = 0.8
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                sparkleOpacity2 = 0.9
            }
        }
    }

    private func purchaseRow(name: String, price: String, credits: Int, isAvailable: Bool) -> some View {
        HStack {
            Text(name)
                .font(.custom(bodyBoldFont, size: 15))
                .foregroundColor(.white)

            Spacer()

            Text(price)
                .font(.custom(bodyBoldFont, size: 15))
                .foregroundColor(accent)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(isAvailable ? 1.0 : 0.5)
    }
}

#Preview {
    NoCreditView()
}
