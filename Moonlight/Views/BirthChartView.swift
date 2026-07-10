import SwiftUI

// MARK: - Birth chart (the moat, made visible)
//
// Enter real birth data → get a real natal chart from the astrology API.
// No LLM guessing on the data layer: these are actual ephemeris positions.
// fab-minimal presentation: flat ink, hairline cards, editorial type.

struct BirthChartView: View {
    @ObservedObject private var profile = UserProfile.shared
    @Environment(\.dismiss) private var dismiss

    @State private var chart: HoraryChartData?
    @State private var loading = false
    @State private var errorText: String?
    @State private var editingBirthData = false

    var body: some View {
        ZStack {
            GradientSky()

            if profile.isOnboarded && !editingBirthData {
                chartScroll
            } else {
                BirthDataEntry(loading: $loading, errorText: $errorText) {
                    await compute()
                }
            }

            if loading {
                loadingOverlay
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                if editingBirthData {
                    editingBirthData = false
                    errorText = nil
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(Theme.ui(15, .semibold))
                    .foregroundColor(Theme.textMuted)
                    .padding(10)
                    .glass(cornerRadius: Theme.Radius.pill)
            }
            .buttonStyle(.plain)
            .padding(.top, 54)
            .padding(.trailing, 20)
        }
        .task {
            // If they're onboarded but we haven't fetched this session, do it.
            if profile.isOnboarded, chart == nil { await compute(silent: true) }
        }
    }

    // MARK: Result

    private var chartScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                header

                if let error = errorText {
                    errorCard(error)
                }

                bigThree

                if let chart {
                    planetsSection(chart)
                    if !chart.aspects.isEmpty { aspectsSection(chart) }
                }

                disclaimer
            }
            .padding(Theme.Space.lg)
            .padding(.bottom, 40)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.name.isEmpty ? L("Doğum Haritan", "Your Birth Chart")
                 : L("\(profile.name)’in Haritası", "\(profile.name)’s Chart"))
                .font(Theme.display(30))
                .foregroundColor(Theme.text)
            if let birth = profile.birthDate {
                HStack(spacing: 10) {
                    Text(birthLine(birth))
                        .font(Theme.body(14))
                        .foregroundColor(Theme.textMuted)
                    Button(L("Düzenle", "Edit")) {
                        editingBirthData = true
                    }
                    .font(Theme.ui(13))
                    .foregroundColor(Theme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func birthLine(_ date: Date) -> String {
        let d = Theme.shortDateFormatter.string(from: date)
        let place = profile.birthPlaceName
        if profile.hasBirthTime {
            let t = Theme.timeFormatter.string(from: date)
            return [d, t, place].filter { !$0.isEmpty }.joined(separator: " · ")
        }
        return [d, place].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var bigThree: some View {
        HStack(spacing: Theme.Space.sm) {
            bigThreeCard(L("Güneş", "Sun"), "☉", profile.sunSign)
            bigThreeCard(L("Ay", "Moon"), "☾", profile.moonSign)
            bigThreeCard(L("Yükselen", "Rising"), "↑", profile.risingSign)
        }
    }

    private func bigThreeCard(_ label: String, _ glyph: String, _ sign: ZodiacSign?) -> some View {
        VStack(spacing: 6) {
            Text(label.uppercased())
                .font(Theme.ui(11, .semibold))
                .foregroundColor(Theme.textFaint)
                .tracking(1.2)
            Text(sign?.emoji ?? glyph)
                .font(.system(size: 30))
            Text(sign?.localizedName ?? "—")
                .font(Theme.body(15, .medium))
                .foregroundColor(Theme.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Space.md)
        .glass(cornerRadius: Theme.Radius.md)
    }

    private func planetsSection(_ chart: HoraryChartData) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionHeader(title: L("Gezegenler", "Planets"))
            VStack(spacing: 0) {
                ForEach(Array(chart.planets.enumerated()), id: \.offset) { i, p in
                    if let meta = PlanetMeta.map[p.name] {
                        planetRow(meta, p)
                        if i < chart.planets.count - 1 {
                            Divider().overlay(Theme.hairline)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Space.md)
            .padding(.vertical, 4)
            .glass()
        }
    }

    private func planetRow(_ meta: PlanetMeta, _ p: PlanetPosition) -> some View {
        HStack(spacing: 12) {
            Text(meta.glyph)
                .font(.system(size: 18))
                .foregroundColor(Theme.accent)
                .frame(width: 24)
            Text(L(meta.tr, meta.en))
                .font(Theme.body(15))
                .foregroundColor(Theme.text)
            Spacer()
            if p.isRetro {
                Text("℞")
                    .font(Theme.body(13, .semibold))
                    .foregroundColor(Theme.rose)
            }
            Text(signGlyph(p.sign))
                .font(.system(size: 15))
            Text("\(Int(p.degree))°")
                .font(Theme.body(14).monospacedDigit())
                .foregroundColor(Theme.textMuted)
        }
        .padding(.vertical, 12)
    }

    private func aspectsSection(_ chart: HoraryChartData) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionHeader(title: L("Açılar", "Aspects"),
                          subtitle: L("Gezegenlerin birbirine açısı", "How your planets talk to each other"))
            VStack(spacing: 0) {
                let shown = Array(chart.aspects.prefix(8).enumerated())
                ForEach(shown, id: \.offset) { i, a in
                    HStack(spacing: 8) {
                        Text(L(PlanetMeta.map[a.planet1]?.tr ?? a.planet1,
                               PlanetMeta.map[a.planet1]?.en ?? a.planet1))
                        Text(aspectLabel(a.aspect))
                            .foregroundColor(Theme.accent)
                            .font(Theme.body(13, .medium))
                        Text(L(PlanetMeta.map[a.planet2]?.tr ?? a.planet2,
                               PlanetMeta.map[a.planet2]?.en ?? a.planet2))
                        Spacer()
                    }
                    .font(Theme.body(14))
                    .foregroundColor(Theme.text)
                    .padding(.vertical, 11)
                    if i < shown.count - 1 { Divider().overlay(Theme.hairline) }
                }
            }
            .padding(.horizontal, Theme.Space.md)
            .padding(.vertical, 4)
            .glass()
        }
    }

    private var disclaimer: some View {
        Text(L("Astrolojik yorumlar eğlence ve öz-yansıma amaçlıdır; gelecekten haber vermez.",
               "Astrological content is for entertainment and self-reflection; it does not foretell the future."))
            .font(Theme.body(12))
            .foregroundColor(Theme.textFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    private func errorCard(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.error)
            Text(text).font(Theme.body(14)).foregroundColor(Theme.text)
            Spacer()
            Button(L("Tekrar", "Retry")) { Task { await compute() } }
                .font(Theme.ui(14))
                .foregroundColor(Theme.accent)
        }
        .padding(Theme.Space.md)
        .glass(cornerRadius: Theme.Radius.md)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 14) {
                LoadingDots()
                Text(L("Gökyüzü okunuyor…", "Reading the sky…"))
                    .font(Theme.body(15))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(Theme.Space.xl)
            .glass()
        }
    }

    // MARK: Compute

    private func compute(silent: Bool = false) async {
        if !silent { loading = true }
        errorText = nil
        defer { loading = false }
        do {
            chart = try await NatalChartService.shared.computeAndStore(for: profile)
            editingBirthData = false
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func signGlyph(_ sign: String) -> String {
        ZodiacSign(rawValue: sign.lowercased())?.emoji ?? ""
    }

    private func aspectLabel(_ raw: String) -> String {
        switch raw.lowercased() {
        case "conjunction": return L("kavuşum", "conjunction")
        case "opposition": return L("karşıt", "opposition")
        case "trine": return L("üçgen", "trine")
        case "square": return L("kare", "square")
        case "sextile": return L("altmışlık", "sextile")
        default: return raw
        }
    }
}

// MARK: - Planet metadata (glyph + localized name)

struct PlanetMeta {
    let glyph: String
    let tr: String
    let en: String

    static let map: [String: PlanetMeta] = [
        "Sun": PlanetMeta(glyph: "☉", tr: "Güneş", en: "Sun"),
        "Moon": PlanetMeta(glyph: "☾", tr: "Ay", en: "Moon"),
        "Mercury": PlanetMeta(glyph: "☿", tr: "Merkür", en: "Mercury"),
        "Venus": PlanetMeta(glyph: "♀", tr: "Venüs", en: "Venus"),
        "Mars": PlanetMeta(glyph: "♂", tr: "Mars", en: "Mars"),
        "Jupiter": PlanetMeta(glyph: "♃", tr: "Jüpiter", en: "Jupiter"),
        "Saturn": PlanetMeta(glyph: "♄", tr: "Satürn", en: "Saturn"),
        "Uranus": PlanetMeta(glyph: "♅", tr: "Uranüs", en: "Uranus"),
        "Neptune": PlanetMeta(glyph: "♆", tr: "Neptün", en: "Neptune"),
        "Pluto": PlanetMeta(glyph: "♇", tr: "Plüton", en: "Pluto"),
        "Ascendant": PlanetMeta(glyph: "↑", tr: "Yükselen", en: "Ascendant"),
        "MC": PlanetMeta(glyph: "⊤", tr: "Tepe Noktası", en: "Midheaven"),
    ]
}

// MARK: - Birth data entry

private struct BirthDataEntry: View {
    @ObservedObject private var profile = UserProfile.shared
    @Binding var loading: Bool
    @Binding var errorText: String?
    let onSubmit: () async -> Void

    @State private var name = ""
    @State private var date = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    @State private var time = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var unknownTime = false
    @State private var place = ""

    /// When the user is editing (not first onboarding), start from what they
    /// already entered instead of blank fields.
    private func prefillFromProfile() {
        guard let birthDate = profile.birthDate else { return }
        name = profile.name
        date = birthDate
        time = birthDate
        unknownTime = !profile.hasBirthTime
        place = profile.birthPlaceName
    }

    private var canSubmit: Bool { !place.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("Gerçek haritan için", "For your real chart"))
                        .font(Theme.ui(12, .semibold))
                        .foregroundColor(Theme.accent)
                        .tracking(1)
                    Text(L("Seni tanıyalım", "Let’s get you right"))
                        .font(Theme.display(30))
                        .foregroundColor(Theme.text)
                    Text(L("Doğum anın ve yerin, haritanı hesaplamak için gerekli. Sadece senin için.",
                           "Your birth moment and place power the chart. Yours alone."))
                        .font(Theme.body(14))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.top, 12)

                field(L("İsim (opsiyonel)", "Name (optional)")) {
                    TextField("", text: $name, prompt: Text(L("Adın", "Your name")).foregroundColor(Theme.textFaint))
                        .textInputAutocapitalization(.words)
                        .foregroundColor(Theme.text)
                }

                field(L("Doğum tarihi", "Birth date")) {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(Theme.accent)
                        .colorScheme(.dark)
                }

                field(L("Doğum saati", "Birth time")) {
                    VStack(alignment: .leading, spacing: 10) {
                        if !unknownTime {
                            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(Theme.accent)
                                .colorScheme(.dark)
                        }
                        Toggle(isOn: $unknownTime) {
                            Text(L("Saati bilmiyorum", "I don’t know the time"))
                                .font(Theme.body(14))
                                .foregroundColor(Theme.textMuted)
                        }
                        .tint(Theme.accent)
                    }
                }

                field(L("Doğum yeri", "Birth place")) {
                    TextField("", text: $place, prompt: Text(L("Şehir, ülke", "City, country")).foregroundColor(Theme.textFaint))
                        .textInputAutocapitalization(.words)
                        .foregroundColor(Theme.text)
                }

                if let errorText {
                    Text(errorText)
                        .font(Theme.body(13))
                        .foregroundColor(Theme.error)
                }

                MoonButton(L("Haritamı çıkar", "Reveal my chart"), loading: loading) {
                    save()
                    Task { await onSubmit() }
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)

                Text(L("Verilerin cihazında kalır. İstediğin an silebilirsin.",
                       "Your data stays on your device. Delete it anytime."))
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textFaint)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(Theme.Space.lg)
            .padding(.bottom, 40)
        }
        .onAppear { prefillFromProfile() }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Theme.ui(12, .semibold))
                .foregroundColor(Theme.textFaint)
                .tracking(0.5)
            content()
                .font(Theme.body(16))
                .padding(.horizontal, Theme.Space.md)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glass(cornerRadius: Theme.Radius.md)
        }
    }

    private func save() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let dc = cal.dateComponents([.year, .month, .day], from: date)
        var comps = DateComponents()
        comps.year = dc.year; comps.month = dc.month; comps.day = dc.day
        if unknownTime {
            comps.hour = 12; comps.minute = 0
        } else {
            let t = cal.dateComponents([.hour, .minute], from: time)
            comps.hour = t.hour; comps.minute = t.minute
        }
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.birthDate = cal.date(from: comps)
        profile.hasBirthTime = !unknownTime
        profile.birthPlaceName = place.trimmingCharacters(in: .whitespaces)
        // Force re-geocode for the new place.
        profile.birthLatitude = nil
        profile.birthLongitude = nil
        profile.birthTimezoneHours = nil
    }
}
