import SwiftUI

struct PixelStarsView: View {
    let size: CGSize
    @State private var phase = false

    // Pre-computed opacity pairs: no randomness in body, computed once as static
    private static let dotOpacities: [(lo: Double, hi: Double)] = (0..<20).map { _ in
        (Double.random(in: 0.2...0.4), Double.random(in: 0.6...0.9))
    }
    private static let assetOpacities: [(lo: Double, hi: Double)] = (0..<12).map { _ in
        (Double.random(in: 0.2...0.4), Double.random(in: 0.6...0.9))
    }
    private static let sparkleOpacities: [(lo: Double, hi: Double)] = (0..<14).map { _ in
        (Double.random(in: 0.15...0.35), Double.random(in: 0.5...0.75))
    }

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
        ("atmospheric_star_gold_2", 0.12, 0.04, 20),
        ("atmospheric_star_blue_1", 0.80, 0.07, 20),
        ("atmospheric_star_white_2", 0.48, 0.02, 18),
        ("atmospheric_star_gold_2", 0.25, 0.18, 20),
        ("atmospheric_star_white_2", 0.70, 0.13, 16),
        ("atmospheric_star_blue_1", 0.92, 0.22, 18),
        ("atmospheric_star_gold_2", 0.38, 0.32, 18),
        ("atmospheric_star_white_2", 0.62, 0.45, 20),
        ("atmospheric_star_blue_1", 0.08, 0.50, 16),
        ("atmospheric_star_gold_2", 0.85, 0.40, 18),
        ("atmospheric_star_white_2", 0.55, 0.60, 16),
        ("atmospheric_star_blue_1", 0.18, 0.55, 18),
    ]

    // Big pixel art sparkles - concentrated at the top around the moon
    private let bigSparkles: [(name: String, xFrac: CGFloat, yFrac: CGFloat, sz: CGFloat)] = [
        // Top cluster - around moon area
        ("sparkle_gold", 0.06, 0.04, 34),
        ("sparkle_blue", 0.92, 0.06, 38),
        ("sparkle_gold", 0.35, 0.02, 30),
        ("sparkle_blue", 0.70, 0.08, 32),
        ("sparkle_gold", 0.18, 0.10, 28),
        ("sparkle_blue", 0.55, 0.04, 26),
        ("sparkle_gold", 0.82, 0.12, 30),
        ("sparkle_blue", 0.28, 0.14, 24),
        ("sparkle_gold", 0.48, 0.16, 32),
        ("sparkle_blue", 0.05, 0.18, 28),
        // Mid area - sparser
        ("sparkle_gold", 0.65, 0.30, 24),
        ("sparkle_blue", 0.15, 0.38, 26),
        ("sparkle_gold", 0.85, 0.42, 22),
        ("sparkle_blue", 0.40, 0.50, 24),
    ]

    private let starColor = Theme.accent

    var body: some View {
        ZStack {
            // Tiny yellow dots
            ForEach(0..<positions.count, id: \.self) { i in
                let pos = positions[i]
                let pair = Self.dotOpacities[i]
                Rectangle()
                    .fill(starColor)
                    .frame(width: pos.px, height: pos.px)
                    .opacity(phase ? pair.hi : pair.lo)
                    .position(x: size.width * pos.xFrac, y: size.height * pos.yFrac)
            }

            // Pixel art sparkles (small)
            ForEach(0..<assetStars.count, id: \.self) { i in
                let star = assetStars[i]
                let pair = Self.assetOpacities[i]
                Image(star.name)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: star.sz, height: star.sz)
                    .opacity(phase ? pair.hi : pair.lo)
                    .position(x: size.width * star.xFrac, y: size.height * star.yFrac)
            }

            // Big sparkles
            ForEach(0..<bigSparkles.count, id: \.self) { i in
                let spark = bigSparkles[i]
                let pair = Self.sparkleOpacities[i]
                Image(spark.name)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: spark.sz, height: spark.sz)
                    .opacity(phase ? pair.hi : pair.lo)
                    .position(x: size.width * spark.xFrac, y: size.height * spark.yFrac)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                phase = true
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
    let containerWidth: CGFloat

    @State private var atEnd = false

    var body: some View {
        Image("atmospheric_\(name)")
            .interpolation(.none)
            .resizable()
            .frame(width: width, height: width * 0.4)
            .opacity(0.8)
            .position(
                x: (atEnd ? endX : startX) + containerWidth / 2,
                y: y
            )
            .animation(.linear(duration: duration).repeatForever(autoreverses: true), value: atEnd)
            .onAppear { atEnd = true }
    }
}

struct MoonSceneView: View {
    let moonData: MoonData
    var showMoon: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.bg

                PixelStarsView(size: geometry.size)

                // Back clouds
                DriftingCloud(name: "cloud_1", width: 280, y: geometry.size.height * 0.25, startX: -200, endX: 200, duration: 25, containerWidth: geometry.size.width)
                DriftingCloud(name: "cloud_2", width: 240, y: geometry.size.height * 0.45, startX: 300, endX: -300, duration: 35, containerWidth: geometry.size.width)

                // Moon character
                if showMoon {
                    pixelMoon()
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.28)
                }

                // Front clouds
                DriftingCloud(name: "cloud_3", width: 320, y: geometry.size.height * 0.55, startX: -100, endX: 100, duration: 20, containerWidth: geometry.size.width)
                DriftingCloud(name: "cloud_4", width: 260, y: geometry.size.height * 0.68, startX: 200, endX: -200, duration: 40, containerWidth: geometry.size.width)
                DriftingCloud(name: "cloud_5", width: 350, y: geometry.size.height * 0.80, startX: -300, endX: 300, duration: 30, containerWidth: geometry.size.width)
                DriftingCloud(name: "cloud_6", width: 300, y: geometry.size.height * 0.92, startX: 100, endX: -100, duration: 20, containerWidth: geometry.size.width)
            }
        }
    }

    // MARK: - Pixel Moon

    private func pixelMoon() -> some View {
        Image(moonData.phase.rawValue)
            .interpolation(.none)
            .resizable()
            .frame(width: 180, height: 180)
            .shadow(color: .yellow.opacity(0.2), radius: 20)
    }
}

