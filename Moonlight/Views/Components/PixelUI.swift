import SwiftUI

// MARK: - Pixel Card Background

struct PixelCard<Content: View>: View {
    let borderColor: Color
    let content: Content

    init(borderColor: Color = .white.opacity(0.15), @ViewBuilder content: () -> Content) {
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        ZStack {
            Image("card_bg")
                .interpolation(.none)
                .resizable()

            content
        }
    }
}

// MARK: - Pixel Button

struct PixelButton: View {
    let title: String
    let action: () -> Void
    let style: PixelButtonStyle

    private let titleFont = "PressStart2P-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    enum PixelButtonStyle {
        case primary   // gold bg, dark text
        case secondary // outline only
    }

    init(_ title: String, style: PixelButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom(bodyBoldFont, size: 12))
                .foregroundColor(style == .primary ? bg : accent)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if style == .primary {
                            accent
                        }
                        // Pixel border: 2px solid lines
                        VStack(spacing: 0) {
                            Rectangle().fill(style == .primary ? accent.opacity(0.8) : accent.opacity(0.5))
                                .frame(height: 2)
                            Spacer()
                            Rectangle().fill(style == .primary ? accent.opacity(0.8) : accent.opacity(0.5))
                                .frame(height: 2)
                        }
                        HStack(spacing: 0) {
                            Rectangle().fill(style == .primary ? accent.opacity(0.8) : accent.opacity(0.5))
                                .frame(width: 2)
                            Spacer()
                            Rectangle().fill(style == .primary ? accent.opacity(0.8) : accent.opacity(0.5))
                                .frame(width: 2)
                        }
                    }
                )
        }
    }
}

// MARK: - Pixel Element Dot (replaces Circle)

struct PixelElementDot: View {
    let element: Element
    let energy: Double
    let size: CGFloat

    var body: some View {
        // 3x3 pixel cross pattern instead of circle
        let px = size / 3
        ZStack {
            // Center column (full height)
            Rectangle()
                .fill(element.color)
                .frame(width: px, height: size)
            // Middle row (full width)
            Rectangle()
                .fill(element.color)
                .frame(width: size, height: px)
        }
        .shadow(color: element.color.opacity(energy > 0.7 ? 0.8 : 0.2), radius: energy > 0.7 ? 6 : 1)
    }
}

// MARK: - Pixel Energy Bar (replaces RoundedRectangle bars)

struct PixelEnergyBar: View {
    let element: Element
    let energy: Double
    let height: CGFloat

    var body: some View {
        let totalBlocks = Int(height / 4)
        let filledBlocks = Int(CGFloat(totalBlocks) * energy)

        VStack(spacing: 1) {
            ForEach(0..<totalBlocks, id: \.self) { i in
                let blockIndex = totalBlocks - 1 - i
                Rectangle()
                    .fill(blockIndex < filledBlocks ? element.color : element.color.opacity(0.15))
                    .frame(width: 12, height: 3)
            }
        }
    }
}

// MARK: - Pixel Loading (replaces ProgressView)

struct PixelLoading: View {
    @State private var dotCount = 0
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(color.opacity(i < dotCount ? 1.0 : 0.2))
                    .frame(width: 4, height: 4)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = (dotCount % 3) + 1
            }
        }
    }
}

// MARK: - Pixel Icon Helper

struct PixelIcon: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Image(name)
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
    }
}

// MARK: - Pixel Text Icons (for small UI icons drawn with font)

struct PixelTextIcon: View {
    let symbol: String
    let color: Color
    let size: CGFloat

    private let font = "PressStart2P-Regular"

    init(_ symbol: String, color: Color = .white, size: CGFloat = 10) {
        self.symbol = symbol
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(symbol)
            .font(.custom(font, size: size))
            .foregroundColor(color)
    }

    // Common pixel text icons
    static func gear(color: Color = .white.opacity(0.5)) -> PixelTextIcon {
        PixelTextIcon("*", color: color, size: 14)
    }
    static func close(color: Color = .white.opacity(0.7)) -> PixelTextIcon {
        PixelTextIcon("X", color: color, size: 10)
    }
    static func show(color: Color = .white.opacity(0.5)) -> PixelTextIcon {
        PixelTextIcon("o", color: color, size: 8)
    }
    static func hide(color: Color = .white.opacity(0.5)) -> PixelTextIcon {
        PixelTextIcon("-", color: color, size: 8)
    }
    static func remove(color: Color = Color(hex: "#FF6B6B")) -> PixelTextIcon {
        PixelTextIcon("x", color: color, size: 8)
    }
}
