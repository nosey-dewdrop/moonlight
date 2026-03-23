import SwiftUI

struct HoraryView: View {
    @StateObject private var creditManager = CreditManager.shared
    @State private var question = ""
    @State private var moonData: MoonData?
    @State private var activeRetrogrades: [String] = []
    @State private var elementEnergies: [Element: Double] = [:]
    @State private var freeAnswer: String?
    @State private var aiReading: String?
    @State private var isLoadingAI = false
    @State private var errorMessage: String?
    @State private var hasAsked = false

    private let moonService = MoonService()
    private let astrologyService = AstrologyService()
    private let claudeService = ClaudeService()

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                Text("Horary")
                    .font(.custom(titleFont, size: 16))
                    .foregroundColor(accent)
                    .shadow(color: accent.opacity(0.5), radius: 4)

                Text("Ask the Moon a Question")
                    .font(.custom(bodyFont, size: 11))
                    .foregroundColor(.white.opacity(0.5))

                // Question input
                questionInput

                if hasAsked {
                    // Cosmic context
                    cosmicContext

                    // Free answer
                    if let free = freeAnswer {
                        freeAnswerView(free)
                    }

                    // AI reading
                    aiReadingSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .task {
            await loadCosmicData()
        }
    }

    // MARK: - Question Input

    private var questionInput: some View {
        VStack(spacing: 12) {
            TextField("", text: $question, prompt:
                Text("What does your heart seek?")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.custom(bodyFont, size: 12))
            )
            .font(.custom(bodyFont, size: 12))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(bg.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .textInputAutocapitalization(.sentences)

            PixelButton(hasAsked ? "Ask Again" : "Ask the Stars") {
                askQuestion()
            }
            .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Cosmic Context

    private var cosmicContext: some View {
        VStack(spacing: 12) {
            if let moon = moonData {
                // Moon phase with pixel art character
                ZStack {
                    Image("card_bg_event")
                        .interpolation(.none)
                        .resizable()

                    HStack(spacing: 10) {
                        Image(moon.phase.rawValue)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(moon.phase.displayName)
                                .font(.custom(bodyBoldFont, size: 12))
                                .foregroundColor(.white)
                            Text("\(Int(moon.illumination))% illuminated")
                                .font(.custom(bodyFont, size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                    }
                    .padding(12)
                }

                // Active retrogrades
                if !activeRetrogrades.isEmpty {
                    ZStack {
                        Image("card_bg_event")
                            .interpolation(.none)
                            .resizable()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Active Retrogrades")
                                .font(.custom(titleFont, size: 7))
                                .foregroundColor(Color(hex: "#FF6B6B"))

                            ForEach(activeRetrogrades, id: \.self) { retro in
                                HStack(spacing: 6) {
                                    PixelIcon(name: "icon_retrograde", size: 14)
                                    Text(retro)
                                        .font(.custom(bodyFont, size: 10))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Element energies
                elementEnergyBar
            }
        }
    }

    private var elementEnergyBar: some View {
        ZStack {
            Image("card_bg_event")
                .interpolation(.none)
                .resizable()

            HStack(spacing: 16) {
                ForEach(Element.allCases, id: \.self) { element in
                    let energy = elementEnergies[element] ?? 0.5
                    VStack(spacing: 4) {
                        PixelElementDot(element: element, energy: energy, size: 10)

                        PixelEnergyBar(element: element, energy: energy, height: 40)

                        Text(element.displayName.prefix(2).uppercased())
                            .font(.custom(bodyFont, size: 7))
                            .foregroundColor(element.color.opacity(0.7))
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: - Free Answer

    private func freeAnswerView(_ answer: String) -> some View {
        ZStack {
            Image("card_bg_event")
                .interpolation(.none)
                .resizable()

            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Answer")
                    .font(.custom(titleFont, size: 8))
                    .foregroundColor(accent)

                Text(answer)
                    .font(.custom(bodyBoldFont, size: 14))
                    .foregroundColor(.white)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - AI Reading

    private var aiReadingSection: some View {
        VStack(spacing: 12) {
            if let reading = aiReading {
                ZStack {
                    Image("card_bg_event")
                        .interpolation(.none)
                        .resizable()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Deep Oracle Reading")
                            .font(.custom(titleFont, size: 8))
                            .foregroundColor(accent)

                        Text(reading)
                            .font(.custom(bodyFont, size: 11))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                    }
                    .padding(12)
                }
            } else {
                Button(action: requestDeepReading) {
                    HStack(spacing: 8) {
                        if isLoadingAI {
                            PixelLoading(color: bg)
                        }
                        Text(isLoadingAI ? "Consulting stars..." : "Get Deep Reading")
                            .font(.custom(bodyBoldFont, size: 12))
                            .foregroundColor(bg)

                        Text("(\(creditManager.credits) credits)")
                            .font(.custom(bodyFont, size: 9))
                            .foregroundColor(bg.opacity(0.6))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(accent)
                }
                .disabled(isLoadingAI || !claudeService.hasApiKey)

                if !claudeService.hasApiKey {
                    Text("Set API key in Settings first")
                        .font(.custom(bodyFont, size: 9))
                        .foregroundColor(Color(hex: "#FF6B6B").opacity(0.7))
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.custom(bodyFont, size: 9))
                        .foregroundColor(Color(hex: "#FF6B6B").opacity(0.7))
                }
            }
        }
    }

    // MARK: - Actions

    private func askQuestion() {
        guard let moon = moonData else { return }

        // Generate free yes/no based on moon phase and elements
        let dominantElement = elementEnergies.max(by: { $0.value < $1.value })?.key ?? .water
        let moonFavor = moon.phase.fillFraction // higher = more positive

        // Simple horary: moon phase + dominant element + retrograde count
        let retroPenalty = Double(activeRetrogrades.count) * 0.1
        let score = moonFavor * 0.5 + (elementEnergies[dominantElement] ?? 0.5) * 0.3 - retroPenalty + Double.random(in: -0.15...0.15)

        if score > 0.6 {
            freeAnswer = "The stars say: Yes, the cosmic winds favor this path."
        } else if score > 0.4 {
            freeAnswer = "The stars say: Perhaps, but patience is needed. The timing is uncertain."
        } else {
            freeAnswer = "The stars say: Not now. The moon advises waiting for a clearer sky."
        }

        aiReading = nil
        errorMessage = nil

        withAnimation {
            hasAsked = true
        }
    }

    private func requestDeepReading() {
        guard creditManager.useCredit() else {
            errorMessage = "No credits remaining"
            return
        }

        isLoadingAI = true
        errorMessage = nil

        Task {
            do {
                let language = Locale.current.language.languageCode?.identifier == "tr" ? "Turkish" : "English"

                let reading = try await claudeService.horaryReading(
                    question: question,
                    moonPhase: moonData?.phase ?? .fullMoon,
                    elementEnergies: elementEnergies,
                    activeRetrogrades: activeRetrogrades,
                    language: language
                )

                await MainActor.run {
                    aiReading = reading
                    isLoadingAI = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoadingAI = false
                    creditManager.credits += 1
                }
            }
        }
    }

    private func loadCosmicData() async {
        moonData = moonService.calculateMoonPhase(date: Date())

        do {
            let events = try await astrologyService.fetchEvents()
            activeRetrogrades = events.filter { $0.isActive && $0.type == .retrograde }.map { $0.title }
        } catch {
            print("Failed to load events: \(error)")
        }

        if let moon = moonData {
            elementEnergies = Element.adjustedEnergies(for: moon.phase, activeRetrogrades: activeRetrogrades)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0b0b2e").ignoresSafeArea()
        HoraryView()
    }
}
