import SwiftUI

struct TarotView: View {
    @StateObject private var creditManager = CreditManager.shared
    @State private var drawnCards: [DrawnCard] = []
    @State private var isDrawing = false
    @State private var showSpread = false
    @State private var aiReading: String?
    @State private var isLoadingAI = false
    @State private var errorMessage: String?
    @State private var cardFlipStates: [Bool] = [false, false, false]

    private let claudeService = ClaudeService()
    private let astrologyService = AstrologyService()

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                Text("Tarot")
                    .font(.custom(titleFont, size: 16))
                    .foregroundColor(accent)
                    .shadow(color: accent.opacity(0.5), radius: 4)

                if showSpread {
                    spreadView
                } else {
                    drawPromptView
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Draw Prompt

    private var drawPromptView: some View {
        VStack(spacing: 24) {
            Text("Three Card Spread")
                .font(.custom(bodyBoldFont, size: 14))
                .foregroundColor(.white)

            Text("Past · Present · Future")
                .font(.custom(bodyFont, size: 12))
                .foregroundColor(.white.opacity(0.5))

            // Card back placeholders
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    cardBackView()
                }
            }

            PixelButton(isDrawing ? "Drawing..." : "Draw Cards") {
                drawCards()
            }
            .disabled(isDrawing)

            Text("Free: card names & keywords")
                .font(.custom(bodyFont, size: 9))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.top, 40)
    }

    // MARK: - Spread View

    private var spreadView: some View {
        VStack(spacing: 20) {
            // Three cards
            HStack(spacing: 12) {
                ForEach(Array(drawnCards.enumerated()), id: \.element.id) { index, drawn in
                    drawnCardView(drawn, index: index)
                }
            }

            // Card details
            ForEach(Array(drawnCards.enumerated()), id: \.element.id) { index, drawn in
                cardDetailRow(drawn, position: ["Past", "Present", "Future"][index])
            }

            // AI Reading section
            aiReadingSection

            // Draw again
            PixelButton("Draw Again", style: .secondary) {
                resetDraw()
            }
        }
    }

    // MARK: - Card Views

    private func cardBackView() -> some View {
        ZStack {
            Image("card_bg")
                .interpolation(.none)
                .resizable()

            Text("?")
                .font(.custom(titleFont, size: 20))
                .foregroundColor(accent.opacity(0.3))
        }
        .frame(width: 90, height: 140)
    }

    private func drawnCardView(_ drawn: DrawnCard, index: Int) -> some View {
        VStack(spacing: 6) {
            let position = ["Past", "Present", "Future"][index]

            Text(position)
                .font(.custom(bodyFont, size: 8))
                .foregroundColor(.white.opacity(0.4))

            ZStack {
                Image("card_bg")
                    .interpolation(.none)
                    .resizable()

                VStack(spacing: 4) {
                    if let element = drawn.card.element {
                        PixelElementDot(element: element, energy: 0.8, size: 8)
                    }

                    Text(shortName(drawn.card.name))
                        .font(.custom(bodyFont, size: 9))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)

                    if drawn.isReversed {
                        Text("R")
                            .font(.custom(bodyFont, size: 8))
                            .foregroundColor(Color(hex: "#FF6B6B"))
                    }
                }
                .padding(6)
                .rotation3DEffect(
                    .degrees(drawn.isReversed ? 180 : 0),
                    axis: (x: 0, y: 0, z: 1)
                )
            }
            .frame(width: 90, height: 130)
            .scaleEffect(cardFlipStates[index] ? 1.0 : 0.8)
            .opacity(cardFlipStates[index] ? 1.0 : 0.0)
        }
    }

    private func cardDetailRow(_ drawn: DrawnCard, position: String) -> some View {
        ZStack {
            Image("card_bg_event")
                .interpolation(.none)
                .resizable()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(position): \(drawn.card.name)")
                        .font(.custom(bodyBoldFont, size: 11))
                        .foregroundColor(.white)

                    Spacer()

                    Text(drawn.positionLabel)
                        .font(.custom(bodyFont, size: 9))
                        .foregroundColor(drawn.isReversed ? Color(hex: "#FF6B6B") : Color(hex: "#34D399"))
                }

                Text(drawn.card.keywords.joined(separator: " · "))
                    .font(.custom(bodyFont, size: 10))
                    .foregroundColor(accent.opacity(0.7))

                Text(drawn.meaning)
                    .font(.custom(bodyFont, size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(12)
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
                        Text("Oracle Reading")
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
                Button(action: requestAIReading) {
                    HStack(spacing: 8) {
                        if isLoadingAI {
                            PixelLoading(color: bg)
                        }
                        Text(isLoadingAI ? "Reading stars..." : "Get AI Reading")
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

    private func drawCards() {
        isDrawing = true
        drawnCards = []
        cardFlipStates = [false, false, false]
        aiReading = nil
        errorMessage = nil

        var deck = TarotCard.allCards.shuffled()
        var drawn: [DrawnCard] = []
        for _ in 0..<3 {
            if let card = deck.popLast() {
                drawn.append(DrawnCard(card: card, isReversed: Bool.random()))
            }
        }
        drawnCards = drawn

        // Animate cards appearing one by one
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3 + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    cardFlipStates[i] = true
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { showSpread = true }
            isDrawing = false
        }
    }

    private func resetDraw() {
        withAnimation {
            showSpread = false
            drawnCards = []
            aiReading = nil
            errorMessage = nil
            cardFlipStates = [false, false, false]
        }
    }

    private func requestAIReading() {
        guard creditManager.useCredit() else {
            errorMessage = "No credits remaining"
            return
        }

        isLoadingAI = true
        errorMessage = nil

        Task {
            do {
                let moonData = MoonService().calculateMoonPhase(date: Date())
                let events = try await astrologyService.fetchEvents()
                let activeRetros = events.filter { $0.isActive && $0.type == .retrograde }.map { $0.title }
                let energies = Element.adjustedEnergies(for: moonData.phase, activeRetrogrades: activeRetros)

                let language = Locale.current.language.languageCode?.identifier == "tr" ? "Turkish" : "English"

                let reading = try await claudeService.tarotReading(
                    cards: drawnCards,
                    moonPhase: moonData.phase,
                    elementEnergies: energies,
                    activeRetrogrades: activeRetros,
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
                    // Refund credit on error
                    creditManager.credits += 1
                }
            }
        }
    }

    // MARK: - Helpers

    private func elementBorderColor(_ drawn: DrawnCard) -> Color {
        drawn.card.element?.color ?? accent
    }

    private func shortName(_ name: String) -> String {
        name.replacingOccurrences(of: " of ", with: "\nof\n")
    }
}

#Preview {
    ZStack {
        Color(hex: "#0b0b2e").ignoresSafeArea()
        TarotView()
    }
}
