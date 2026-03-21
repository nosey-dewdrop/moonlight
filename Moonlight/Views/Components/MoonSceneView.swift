import SwiftUI

// Separate view for twinkling stars - isolates re-renders from clouds
struct PixelStarsView: View {
    let size: CGSize
    @State private var starTwinkle: [Double] = (0..<50).map { _ in Double.random(in: 0.3...1.0) }

    private let starColors: [Color] = [
        Color(hex: "#FFE566"),
        Color(hex: "#FFD700"),
        Color(hex: "#FFFFFF"),
        Color(hex: "#E8E8FF"),
        Color(hex: "#AAC4FF"),
        Color(hex: "#7EB8DA"),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { i in
                let seed = UInt64(i * 7 + 13)
                let x = CGFloat(seed * 31 % UInt64(max(size.width, 1)))
                let y = CGFloat(seed * 53 % UInt64(max(size.height * 0.85, 1)))
                let colorIdx = Int(seed % UInt64(starColors.count))
                let pixelSize: CGFloat = CGFloat(2 + (seed % 3))
                let isCross = seed % 4 == 0

                if isCross {
                    ZStack {
                        Rectangle().fill(starColors[colorIdx]).frame(width: pixelSize * 3, height: pixelSize)
                        Rectangle().fill(starColors[colorIdx]).frame(width: pixelSize, height: pixelSize * 3)
                    }
                    .opacity(i < starTwinkle.count ? starTwinkle[i] : 0.5)
                    .position(x: x, y: y)
                } else {
                    Rectangle()
                        .fill(starColors[colorIdx])
                        .frame(width: pixelSize, height: pixelSize)
                        .opacity(i < starTwinkle.count ? starTwinkle[i] : 0.5)
                        .position(x: x, y: y)
                }
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 2.5)) {
                    for i in 0..<starTwinkle.count {
                        starTwinkle[i] = Double.random(in: 0.3...1.0)
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
