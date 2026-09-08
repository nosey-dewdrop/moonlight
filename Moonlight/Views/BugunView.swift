import SwiftUI

// MARK: - Bugün (Today) — the signature screen
//
// One considered idea, not a dashboard: the sky is the screen, the moon is
// alive and shows tonight's *real* phase, and there is exactly one line written
// for THIS person tonight (their moon sign × the real phase). No tab bar, no
// button wall — just breath, type, and one gentle way deeper.

struct BugunView: View {
    @ObservedObject private var profile = UserProfile.shared
    var onOpenChart: () -> Void = {}
    var onOpenProfile: () -> Void = {}

    @State private var moon: MoonData?
    private let moonService = MoonService()

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profile.name.isEmpty ? "" : ", \(profile.name)"
        switch hour {
        case 5..<12:  return L("Günaydın\(name)", "Good morning\(name)")
        case 12..<18: return L("İyi günler\(name)", "Good afternoon\(name)")
        case 18..<23: return L("İyi akşamlar\(name)", "Good evening\(name)")
        default:      return L("İyi geceler\(name)", "Good night\(name)")
        }
    }

    var body: some View {
        ZStack {
            GradientSky()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                hero
                Spacer(minLength: 0)
                deeper
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.bottom, 30)
        }
        .task {
            if moon == nil {
                let lat = LocationManager.shared.latitude
                let lon = LocationManager.shared.longitude
                if let live = try? await moonService.fetchMoonData(latitude: lat, longitude: lon) {
                    moon = live
                } else {
                    moon = moonService.calculateMoonPhase(date: Date())
                }
            }
        }
    }

    // MARK: Top

    private var topBar: some View {
        HStack {
            Text(Self.dayFormatter.string(from: Date()).uppercased())
                .font(Theme.ui(12, .semibold))
                .foregroundColor(Theme.textFaint)
                .tracking(2)
            Spacer()
            Button(action: onOpenProfile) {
                Circle()
                    .fill(Theme.bgRaised)
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                    .overlay(
                        Text(profile.name.prefix(1).uppercased())
                            .font(Theme.ui(15, .semibold))
                            .foregroundColor(Theme.accent)
                    )
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: Theme.Space.lg) {
            MoonOrb(moon: moon)
                .frame(width: 210, height: 210)

            VStack(spacing: 10) {
                Text(greeting)
                    .font(Theme.body(15))
                    .foregroundColor(Theme.textMuted)

                Text(moon?.phase.displayName ?? L("Gökyüzü", "The Sky"))
                    .font(Theme.display(38))
                    .foregroundColor(Theme.text)
                    .multilineTextAlignment(.center)

                if let moon {
                    Text(personalLine(for: moon))
                        .font(Theme.body(16))
                        .foregroundColor(Theme.textMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, Theme.Space.sm)
                        .padding(.top, 2)
                }
            }
        }
    }

    /// One line written for THIS person: the real phase's intention, coloured by
    /// their moon sign when we know it. Deterministic, no runtime LLM cost.
    private func personalLine(for moon: MoonData) -> String {
        let intention = moon.phase.intention
        guard let sign = profile.moonSign else { return intention }
        let name = sign.localizedName
        return L("\(name) Ay’ında: \(intention.lowercasedFirst)",
                 "In \(name) Moon: \(intention.lowercasedFirst)")
    }

    // MARK: Deeper (one gentle affordance, not a button wall)

    private var deeper: some View {
        Button(action: onOpenChart) {
            HStack(spacing: 8) {
                Text(profile.isOnboarded
                     ? L("Haritana in", "Descend to your chart")
                     : L("Haritanı çıkar", "Reveal your chart"))
                Image(systemName: "arrow.down")
            }
            .font(Theme.ui(15, .semibold))
            .foregroundColor(Theme.text)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .glass(cornerRadius: Theme.Radius.pill)
        }
        .buttonStyle(.plain)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEE, d MMMM"
        return f
    }()
}

// MARK: - MoonOrb (Damla's phase art + coded breath glow)

/// The moon is Damla's drawn art, named by phase (`new_moon`, `full_moon`, …).
/// When she redraws the chibi set, the same asset names swap in with no code
/// change. The only thing code owns here is the light around it — a slow breath
/// glow. No invented character, no fake placeholder.
struct MoonOrb: View {
    let moon: MoonData?

    private var assetName: String { moon?.phase.rawValue ?? "full_moon" }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breath = sin(t * 0.9) * 0.5 + 0.5   // 0...1
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                let r = side / 2
                ZStack {
                    // Soft breath glow behind the moon (light effect only)
                    Circle()
                        .fill(
                            RadialGradient(colors: [Theme.accent.opacity(0.22 + 0.08 * breath), .clear],
                                           center: .center,
                                           startRadius: r * 0.35,
                                           endRadius: r * (1.1 + 0.14 * breath))
                        )
                        .scaleEffect(1.3)

                    // Damla's moon art for the real current phase
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .padding(side * 0.08)
                        .shadow(color: Theme.accent.opacity(0.25), radius: 14)
                }
            }
        }
    }
}

// MARK: - Moon phase intention + small string helper

extension MoonPhase {
    /// A short, entertainment-framed intention for the phase (TR/EN).
    var intention: String {
        switch self {
        case .newMoon:        return L("Niyet ekme zamanı.", "Time to plant an intention.")
        case .waxingCrescent: return L("Küçük bir adım büyür.", "A small step starts to grow.")
        case .firstQuarter:   return L("Kararların sınanıyor.", "Your choices are being tested.")
        case .waxingGibbous:  return L("Sabırla ayarla, yaklaşıyor.", "Adjust with patience, it’s near.")
        case .fullMoon:       return L("Hislerin yüksek sesle konuşuyor.", "Your feelings speak loudly.")
        case .waningGibbous:  return L("Paylaş, hazmet, teşekkür et.", "Share, digest, give thanks.")
        case .lastQuarter:    return L("Bırakma vakti, yer aç.", "Time to release and make room.")
        case .waningCrescent: return L("Dinlen, içine dön.", "Rest and turn inward.")
        }
    }
}

extension String {
    /// Lowercases only the first character (for graceful sentence stitching).
    var lowercasedFirst: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
}
