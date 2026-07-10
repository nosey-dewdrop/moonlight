import SwiftUI

/// The shareable reading card: 1080×1350 (4:5, Instagram-native) navy sky,
/// sharp 2px gold frame, scattered stars, the question, an excerpt of the
/// reading and the Moonlight wordmark. Rendered off-screen with ImageRenderer.
struct ShareCardView: View {
    let question: String
    let reading: String
    let moonPhaseName: String

    private var excerpt: String {
        if reading.count <= 280 { return reading }
        let cut = reading.prefix(280)
        // Cut on the last sentence end so the card never trails mid-word.
        if let lastStop = cut.lastIndex(where: { ".!?".contains($0) }) {
            return String(cut[...lastStop])
        }
        return cut.trimmingCharacters(in: .whitespaces) + "…"
    }

    var body: some View {
        ZStack {
            Theme.bg

            // Star field — deterministic positions so the card is stable.
            GeometryReader { geo in
                ForEach(0..<28, id: \.self) { i in
                    let fx = Double((i * 37 + 11) % 100) / 100.0
                    let fy = Double((i * 53 + 29) % 100) / 100.0
                    Circle()
                        .fill(Color.white.opacity(i % 3 == 0 ? 0.7 : 0.3))
                        .frame(width: i % 4 == 0 ? 6 : 3, height: i % 4 == 0 ? 6 : 3)
                        .position(x: geo.size.width * fx, y: geo.size.height * fy)
                }
            }

            VStack(spacing: 40) {
                Spacer()

                Text(moonPhaseName.uppercased())
                    .font(.custom(Theme.titleFont, size: 34))
                    .foregroundColor(Theme.accent)
                    .tracking(6)

                Rectangle()
                    .fill(Theme.accent.opacity(0.4))
                    .frame(width: 120, height: 2)

                Text("“\(question)”")
                    .font(.custom(Theme.bodyFont, size: 40))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .padding(.horizontal, 90)

                Text(excerpt)
                    .font(.custom(Theme.bodyFont, size: 30))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
                    .padding(.horizontal, 100)

                Spacer()

                VStack(spacing: 8) {
                    Text("Moonlight")
                        .font(.custom(Theme.titleFont, size: 30))
                        .foregroundColor(Theme.accent)
                    Text(Theme.shortDateFormatter.string(from: Date()))
                        .font(.custom(Theme.bodyFont, size: 22))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 70)
            }

            Rectangle()
                .strokeBorder(Theme.accent.opacity(0.8), lineWidth: 2)
                .padding(28)
        }
        .frame(width: 1080, height: 1350)
    }
}

// MARK: - Share button

/// Renders the card and hands a UIImage to the system share sheet.
struct ShareReadingButton: View {
    let question: String
    let reading: String
    let moonPhaseName: String

    @State private var shareImage: UIImage?

    var body: some View {
        Group {
            if let shareImage {
                ShareLink(
                    item: Image(uiImage: shareImage),
                    preview: SharePreview("Moonlight", image: Image(uiImage: shareImage))
                ) {
                    label
                }
            } else {
                // Rendering happens lazily on first appearance; the button is
                // disabled for the few ms it takes so it never shares nothing.
                label.opacity(0.4)
            }
        }
        .task { render() }
    }

    private var label: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 13, weight: .semibold))
            Text(L("Kartı Paylaş", "Share Card"))
                .font(.custom(Theme.bodyBoldFont, size: 13))
        }
        .foregroundColor(Theme.accent)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
    }

    @MainActor
    private func render() {
        guard shareImage == nil else { return }
        let renderer = ImageRenderer(content: ShareCardView(question: question,
                                                            reading: reading,
                                                            moonPhaseName: moonPhaseName))
        renderer.scale = 1
        shareImage = renderer.uiImage
    }
}
