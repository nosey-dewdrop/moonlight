import SwiftUI

// MARK: - Moonlight design-system components (Auramour dreamy-mystic)
//
// Reusable, asset-free building blocks: the gradient star sky, glass cards,
// gradient buttons, section headers and a soft loading dots. Everything reads
// its colours and type from Theme so a palette change ripples everywhere.

// MARK: - Gradient star sky

/// Full-screen background: flat editorial ink + a sparse, restrained star field
/// drawn in a single Canvas (cheap, no per-star views, no image assets).
struct GradientSky: View {
    var starCount: Int = 42
    var twinkles: Bool = true

    // Stars generated once; stable for the view's lifetime.
    @State private var stars: [Star] = []

    private struct Star {
        let x: CGFloat        // 0...1
        let y: CGFloat        // 0...1
        let radius: CGFloat
        let baseOpacity: Double
        let phase: Double     // twinkle offset
        let gold: Bool
    }

    var body: some View {
        ZStack {
            Theme.skyGradient.ignoresSafeArea()

            if twinkles {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    Canvas { ctx, size in
                        draw(&ctx, size: size, t: timeline.date.timeIntervalSinceReferenceDate)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
            } else {
                Canvas { ctx, size in
                    draw(&ctx, size: size, t: 0)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear { if stars.isEmpty { stars = Self.makeStars(starCount) } }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        for star in stars {
            let twinkle = twinkles ? (sin(t * 1.6 + star.phase) * 0.35 + 0.65) : 1.0
            let opacity = star.baseOpacity * twinkle
            let r = star.radius
            let rect = CGRect(
                x: star.x * size.width - r,
                y: star.y * size.height - r,
                width: r * 2,
                height: r * 2
            )
            let color = (star.gold ? Theme.accent : Color.white).opacity(opacity)
            ctx.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    private static func makeStars(_ count: Int) -> [Star] {
        (0..<count).map { _ in
            Star(
                x: .random(in: 0...1),
                y: .random(in: 0...1),
                radius: .random(in: 0.5...1.4),
                baseOpacity: .random(in: 0.18...0.65),
                phase: .random(in: 0...(2 * .pi)),
                gold: Double.random(in: 0...1) < 0.12
            )
        }
    }
}

// MARK: - Glass card

struct GlassCard<Content: View>: View {
    var padding: CGFloat = Theme.Space.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .glass(cornerRadius: Theme.Radius.lg)
    }
}

/// Flat raised surface with a hairline border — the fab-minimal card style.
extension View {
    func glass(cornerRadius: CGFloat = Theme.Radius.lg) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.bgRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Buttons

/// Primary gold gradient pill. The one big call to action per screen.
struct MoonButton: View {
    let title: String
    var icon: String? = nil
    var loading: Bool = false
    let action: () -> Void

    init(_ title: String, icon: String? = nil, loading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.loading = loading
        self.action = action
    }

    @State private var pressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                if loading {
                    LoadingDots(color: Theme.bgDeep)
                } else {
                    if let icon { Image(systemName: icon) }
                    Text(title)
                }
            }
            .font(Theme.ui(17, .bold))
            .foregroundColor(Theme.bgDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.goldGradient, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Theme.accent.opacity(0.35), radius: 18, y: 6)
            .scaleEffect(pressed ? 0.97 : 1)
            .opacity(loading ? 0.85 : 1)
        }
        .buttonStyle(.plain)
        .disabled(loading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = true } }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.18)) { pressed = false } }
        )
    }
}

/// Secondary glass pill — quiet alternative action.
struct GhostButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(Theme.ui(16, .semibold))
            .foregroundColor(Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .glass(cornerRadius: Theme.Radius.pill)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.display(22, .semibold))
                .foregroundColor(Theme.text)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.body(14))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Soft loading dots

struct LoadingDots: View {
    var color: Color = Theme.accent
    @State private var t = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(t == i ? 1.0 : 0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(t == i ? 1.0 : 0.7)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.easeInOut(duration: 0.25)) { t = (t + 1) % 3 }
            }
        }
    }
}
