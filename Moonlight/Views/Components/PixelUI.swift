import SwiftUI

// MARK: - Pixel Button

struct PixelButton: View {
    let title: String
    let action: () -> Void
    let style: PixelButtonStyle

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
                        } else {
                            bg.opacity(0.9)
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
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                dotCount = (dotCount % 3) + 1
            }
        }
    }
}
