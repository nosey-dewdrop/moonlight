import SwiftUI

struct PixelStarsView: View {
    let size: CGSize
    @State private var twinkle: [Double] = (0..<20).map { _ in Double.random(in: 0.3...0.8) }

    // Hand-placed stars scattered across the sky, no lines, no patterns
    private let positions: [(xFrac: CGFloat, yFrac: CGFloat, px: CGFloat)] = [
        (0.10, 0.05, 2), (0.82, 0.03, 3), (0.45, 0.08, 2),
        (0.22, 0.14, 2), (0.68, 0.11, 3), (0.93, 0.17, 2),
        (0.05, 0.22, 2), (0.52, 0.20, 2), (0.35, 0.28, 3),
        (0.78, 0.30, 2), (0.15, 0.38, 2), (0.60, 0.42, 2),
        (0.88, 0.36, 3), (0.40, 0.48, 2), (0.08, 0.55, 2),
        (0.72, 0.52, 2), (0.28, 0.60, 3), (0.55, 0.65, 2),
        (0.90, 0.58, 2), (0.18, 0.70, 2),
    ]

    private let assetStars: [(name: String, xFrac: CGFloat, yFrac: CGFloat, sz: CGFloat)] = [
        ("atmospheric_sparkle_1", 0.12, 0.04, 20),
        ("atmospheric_star_gold_1", 0.80, 0.07, 24),
        ("atmospheric_sparkle_3", 0.48, 0.02, 16),
        ("atmospheric_star_gold_2", 0.25, 0.18, 20),
        ("atmospheric_sparkle_2", 0.70, 0.13, 18),
        ("atmospheric_star_gold_3", 0.92, 0.22, 20),
        ("atmospheric_sparkle_1", 0.38, 0.32, 16),
        ("atmospheric_star_gold_1", 0.62, 0.45, 22),
        ("atmospheric_sparkle_3", 0.08, 0.50, 18),
        ("atmospheric_star_gold_2", 0.85, 0.40, 16),
    ]

    private let starColor = Color(hex: "#FFE566")

    var body: some View {
        ZStack {
            // Tiny yellow dots
            ForEach(0..<positions.count, id: \.self) { i in
                let pos = positions[i]
                Rectangle()
                    .fill(starColor)
                    .frame(width: pos.px, height: pos.px)
                    .opacity(i < twinkle.count ? twinkle[i] : 0.5)
                    .position(x: size.width * pos.xFrac, y: size.height * pos.yFrac)
            }

            // Pixel art sparkles
            ForEach(0..<assetStars.count, id: \.self) { i in
                let star = assetStars[i]
                Image(star.name)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: star.sz, height: star.sz)
                    .opacity(i < twinkle.count ? twinkle[i] : 0.5)
                    .position(x: size.width * star.xFrac, y: size.height * star.yFrac)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 2.0)) {
                    for i in 0..<twinkle.count {
                        twinkle[i] = Double.random(in: 0.2...0.9)
                    }
                }
            }
        }
    }
}

struct DriftingCloud: View {
    let name: String
    let width: CGFloat
    let y: CGFloat
    let startX: CGFloat
    let endX: CGFloat
    let duration: Double

    @State private var atEnd = false

    var body: some View {
        let image = Self.loadCloudAsset(name)
        Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .frame(width: width, height: width * 0.4)
            .opacity(0.8)
            .position(
                x: (atEnd ? endX : startX) + UIScreen.main.bounds.width / 2,
                y: y
            )
            .animation(.linear(duration: duration).repeatForever(autoreverses: true), value: atEnd)
            .onAppear { atEnd = true }
    }

    static func loadCloudAsset(_ name: String) -> UIImage {
        if let bundlePath = Bundle.main.path(forResource: "atmospheric_\(name)", ofType: "png") {
            return UIImage(contentsOfFile: bundlePath) ?? UIImage()
        }
        let fullPath = "/Users/damummyphus/moonlight/assets/atmospheric/\(name).png"
        return UIImage(contentsOfFile: fullPath) ?? UIImage()
    }
}

struct MoonSceneView: View {
    let moonData: MoonData
    var showMoon: Bool = true

    private let bgColor = Color(hex: "#0b0b2e")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                bgColor

                PixelStarsView(size: geometry.size)

                // Back clouds
                DriftingCloud(name: "cloud_1", width: 280, y: geometry.size.height * 0.25, startX: -200, endX: 200, duration: 25)
                DriftingCloud(name: "cloud_2", width: 240, y: geometry.size.height * 0.45, startX: 300, endX: -300, duration: 35)

                // Moon character
                if showMoon {
                    pixelMoon()
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.28)
                }

                // Front clouds
                DriftingCloud(name: "cloud_3", width: 320, y: geometry.size.height * 0.55, startX: -100, endX: 100, duration: 20)
                DriftingCloud(name: "cloud_4", width: 260, y: geometry.size.height * 0.68, startX: 200, endX: -200, duration: 40)
                DriftingCloud(name: "cloud_5", width: 350, y: geometry.size.height * 0.80, startX: -300, endX: 300, duration: 30)
                DriftingCloud(name: "cloud_6", width: 300, y: geometry.size.height * 0.92, startX: 100, endX: -100, duration: 20)
            }
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

    // MARK: - Asset Loading

    private func loadAsset(_ path: String) -> UIImage {
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
