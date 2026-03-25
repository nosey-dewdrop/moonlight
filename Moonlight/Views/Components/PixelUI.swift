import SwiftUI

// MARK: - Pixel Button

struct PixelButton: View {
    let title: String
    let action: () -> Void
    let style: PixelButtonStyle

    enum PixelButtonStyle {
        case primary
        case secondary
    }

    init(_ title: String, style: PixelButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom(Theme.buttonFont, size: 12))
                .foregroundColor(style == .primary ? Theme.bg : Theme.accent)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if style == .primary {
                            Theme.accent
                        } else {
                            Theme.bg.opacity(0.9)
                        }
                        VStack(spacing: 0) {
                            Rectangle().fill(style == .primary ? Theme.accent.opacity(0.8) : Theme.accent.opacity(0.5))
                                .frame(height: 2)
                            Spacer()
                            Rectangle().fill(style == .primary ? Theme.accent.opacity(0.8) : Theme.accent.opacity(0.5))
                                .frame(height: 2)
                        }
                        HStack(spacing: 0) {
                            Rectangle().fill(style == .primary ? Theme.accent.opacity(0.8) : Theme.accent.opacity(0.5))
                                .frame(width: 2)
                            Spacer()
                            Rectangle().fill(style == .primary ? Theme.accent.opacity(0.8) : Theme.accent.opacity(0.5))
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
