import SwiftUI

struct MoonSceneView: View {
    let moonData: MoonData
    var showMoon: Bool = true
    @State private var cloudOffset1: CGFloat = -200
    @State private var cloudOffset2: CGFloat = 300
    @State private var cloudOffset3: CGFloat = -100
    @State private var cloudOffset4: CGFloat = 200
    @State private var cloudOffset5: CGFloat = -300
    @State private var starTwinkle: [Double] = (0..<50).map { _ in Double.random(in: 0.3...1.0) }
    @State private var blinkFrame: Int = 0
    @State private var glowFrame: Int = 0

    private let bgColor = Color(hex: "#0b0b2e")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Solid pixel-art-friendly dark background
                bgColor

                // Pixel art stars
                pixelStars(size: geometry.size)

                // Back clouds (big, dreamy)
                pixelCloud("cloud_1", width: 280, x: cloudOffset1, y: geometry.size.height * 0.25)
                pixelCloud("cloud_2", width: 240, x: cloudOffset2, y: geometry.size.height * 0.45)

                // Moon character (upper third)
                if showMoon {
                    pixelMoon()
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.28)
                }

                // Front clouds (bigger, layered)
                pixelCloud("cloud_3", width: 320, x: cloudOffset3, y: geometry.size.height * 0.55)
                pixelCloud("cloud_4", width: 260, x: cloudOffset4, y: geometry.size.height * 0.68)
                pixelCloud("cloud_5", width: 350, x: cloudOffset5, y: geometry.size.height * 0.80)
                pixelCloud("cloud_6", width: 300, x: -cloudOffset3, y: geometry.size.height * 0.92)
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Pixel Stars (code-drawn, crisp pixel art)

    private let starColors: [Color] = [
        Color(hex: "#FFE566"), // gold
        Color(hex: "#FFD700"), // bright gold
        Color(hex: "#FFFFFF"), // white
        Color(hex: "#E8E8FF"), // cool white
        Color(hex: "#AAC4FF"), // soft blue
        Color(hex: "#7EB8DA"), // blue
    ]

    private func pixelStars(size: CGSize) -> some View {
        return ZStack {
            ForEach(0..<50, id: \.self) { i in
                let seed = UInt64(i * 7 + 13)
                let x = CGFloat(seed * 31 % UInt64(max(size.width, 1)))
                let y = CGFloat(seed * 53 % UInt64(max(size.height * 0.85, 1)))
                let colorIdx = Int(seed % UInt64(starColors.count))
                let pixelSize: CGFloat = CGFloat(2 + (seed % 3))
                let isCross = seed % 4 == 0

                if isCross {
                    // Cross-shaped pixel star (3x3 with only center + cardinal)
                    pixelCrossStar(color: starColors[colorIdx], size: pixelSize)
                        .opacity(i < starTwinkle.count ? starTwinkle[i] : 0.5)
                        .position(x: x, y: y)
                } else {
                    // Simple dot star
                    Rectangle()
                        .fill(starColors[colorIdx])
                        .frame(width: pixelSize, height: pixelSize)
                        .opacity(i < starTwinkle.count ? starTwinkle[i] : 0.5)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private func pixelCrossStar(color: Color, size: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(color).frame(width: size * 3, height: size) // horizontal
            Rectangle().fill(color).frame(width: size, height: size * 3) // vertical
        }
    }

    // MARK: - Pixel Moon

    private func pixelMoon() -> some View {
        let phaseName = moonData.phase.rawValue
        let image = loadAsset("characters/\(phaseName)")

        return Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .frame(width: 180, height: 180)
            .shadow(color: .yellow.opacity(0.2), radius: 20)
    }

    // MARK: - Pixel Cloud

    private func pixelCloud(_ name: String, width: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Image(uiImage: loadAsset("atmospheric/\(name)"))
            .interpolation(.none)
            .resizable()
            .frame(width: width, height: width * 0.4)
            .opacity(0.8)
            .position(x: x + UIScreen.main.bounds.width / 2, y: y)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Star twinkle
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                for i in 0..<starTwinkle.count {
                    starTwinkle[i] = Double.random(in: 0.2...1.0)
                }
            }
        }

        // Cloud drift
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: true)) { cloudOffset1 = 200 }
        withAnimation(.linear(duration: 35).repeatForever(autoreverses: true)) { cloudOffset2 = -300 }
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) { cloudOffset3 = 100 }
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: true)) { cloudOffset4 = -200 }
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: true)) { cloudOffset5 = 300 }
    }

    // MARK: - Asset Loading

    private func loadAsset(_ path: String) -> UIImage {
        // Try bundle first, fallback to absolute path for development
        if let bundlePath = Bundle.main.path(forResource: path.replacingOccurrences(of: "/", with: "_"), ofType: "png") {
            return UIImage(contentsOfFile: bundlePath) ?? UIImage()
        }
        let fullPath = "/Users/damummyphus/moonlight/assets/\(path).png"
        return UIImage(contentsOfFile: fullPath) ?? UIImage()
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
