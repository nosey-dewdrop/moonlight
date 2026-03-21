import SwiftUI

struct MoonSceneView: View {
    let moonData: MoonData
    @State private var starOpacity: Double = 0.5
    @State private var moonGlow: Double = 0.8
    @State private var cloudOffset1: CGFloat = -200
    @State private var cloudOffset2: CGFloat = 300
    @State private var cloudOffset3: CGFloat = -100
    @State private var cloudOffset4: CGFloat = 200
    @State private var cloudOffset5: CGFloat = -300

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient

                // Stars layer
                StarsLayer()
                    .opacity(starOpacity)

                // Back cloud layers (behind moon)
                CloudLayer(
                    color: Color(hex: "#2a1a4e"),
                    width: geometry.size.width * 1.5,
                    height: 40,
                    yPosition: geometry.size.height * 0.35,
                    offset: cloudOffset1
                )

                CloudLayer(
                    color: Color(hex: "#3d2a6e"),
                    width: geometry.size.width * 1.3,
                    height: 35,
                    yPosition: geometry.size.height * 0.55,
                    offset: cloudOffset2
                )

                // Moon
                MoonShape(phase: moonData.phase)
                    .frame(width: 140, height: 140)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.4)
                    .shadow(color: .yellow.opacity(0.3), radius: 30)
                    .shadow(color: .yellow.opacity(moonGlow * 0.2), radius: 60)

                // Front cloud layers (in front of moon)
                CloudLayer(
                    color: Color(hex: "#4a3580").opacity(0.7),
                    width: geometry.size.width * 1.4,
                    height: 30,
                    yPosition: geometry.size.height * 0.65,
                    offset: cloudOffset3
                )

                CloudLayer(
                    color: Color(hex: "#6b5b95").opacity(0.5),
                    width: geometry.size.width * 1.6,
                    height: 45,
                    yPosition: geometry.size.height * 0.75,
                    offset: cloudOffset4
                )

                CloudLayer(
                    color: Color(hex: "#8b7bb5").opacity(0.3),
                    width: geometry.size.width * 1.8,
                    height: 50,
                    yPosition: geometry.size.height * 0.85,
                    offset: cloudOffset5
                )
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: moonData.phase.sceneColors.map { Color(hex: $0) },
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func startAnimations() {
        // Stars twinkling
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            starOpacity = 1.0
        }

        // Moon glow pulsing
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            moonGlow = 1.0
        }

        // Cloud drift animations - each layer at different speed for parallax
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: true)) {
            cloudOffset1 = 200
        }
        withAnimation(.linear(duration: 35).repeatForever(autoreverses: true)) {
            cloudOffset2 = -300
        }
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
            cloudOffset3 = 100
        }
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: true)) {
            cloudOffset4 = -200
        }
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: true)) {
            cloudOffset5 = 300
        }
    }
}

// MARK: - Moon Shape

struct MoonShape: View {
    let phase: MoonPhase

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2

            // Draw the moon base (dark side)
            let moonCircle = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))

            if phase == .newMoon {
                // New moon: just a faint outline
                context.stroke(moonCircle, with: .color(.gray.opacity(0.3)), lineWidth: 1)
                return
            }

            // Full moon glow
            context.fill(moonCircle, with: .color(Color(hex: "#FFE566")))

            // Draw shadow for partial phases
            if phase != .fullMoon {
                var shadowPath = Path()
                let fillFraction = phase.fillFraction

                // Create the shadow shape
                shadowPath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(90),
                    clockwise: phase.isWaxing
                )

                let ovalWidth = radius * abs(1.0 - fillFraction * 2.0)
                let ovalRect = CGRect(
                    x: center.x - ovalWidth,
                    y: center.y - radius,
                    width: ovalWidth * 2,
                    height: radius * 2
                )
                shadowPath.addEllipse(in: ovalRect)

                // Use even-odd rule for correct shadow
                context.fill(shadowPath, with: .color(Color(hex: "#1a1a3e").opacity(0.95)))
            }

            // Add crater details
            let craterPositions: [(CGFloat, CGFloat, CGFloat)] = [
                (0.3, 0.35, 0.08),
                (0.6, 0.5, 0.06),
                (0.45, 0.7, 0.05),
                (0.55, 0.3, 0.04),
                (0.35, 0.55, 0.03),
            ]

            for (px, py, pr) in craterPositions {
                let craterCenter = CGPoint(
                    x: center.x - radius + radius * 2 * px,
                    y: center.y - radius + radius * 2 * py
                )
                let craterRadius = radius * pr
                let crater = Path(ellipseIn: CGRect(
                    x: craterCenter.x - craterRadius,
                    y: craterCenter.y - craterRadius,
                    width: craterRadius * 2,
                    height: craterRadius * 2
                ))
                context.fill(crater, with: .color(Color(hex: "#E6CC00").opacity(0.4)))
            }
        }
    }
}

// MARK: - Stars Layer

struct StarsLayer: View {
    var body: some View {
        Canvas { context, size in
            // Deterministic star positions using a fixed seed approach
            let starPositions: [(CGFloat, CGFloat, CGFloat)] = generateStarPositions(
                count: 60,
                width: size.width,
                height: size.height
            )

            for (x, y, starSize) in starPositions {
                let starRect = CGRect(
                    x: x - starSize / 2,
                    y: y - starSize / 2,
                    width: starSize,
                    height: starSize
                )
                let star = Path(ellipseIn: starRect)
                let brightness = 0.5 + starSize / 6.0
                context.fill(star, with: .color(.white.opacity(brightness)))
            }
        }
    }

    private func generateStarPositions(count: Int, width: CGFloat, height: CGFloat) -> [(CGFloat, CGFloat, CGFloat)] {
        var positions: [(CGFloat, CGFloat, CGFloat)] = []
        var seed: UInt64 = 42

        for _ in 0..<count {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let x = CGFloat(seed % UInt64(max(width, 1))) + CGFloat.random(in: -2...2)
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let y = CGFloat(seed % UInt64(max(height, 1)))
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let size = CGFloat(seed % 3) + 1.0
            positions.append((abs(x), abs(y), size))
        }

        return positions
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
