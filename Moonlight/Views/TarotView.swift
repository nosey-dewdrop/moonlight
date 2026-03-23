import SwiftUI

struct TarotView: View {
    @StateObject private var creditManager = CreditManager.shared
    @State private var selectedCards: [DrawnCard] = []
    @State private var shuffledDeck: [TarotCard] = TarotCard.allCards.shuffled()
    @State private var showReading = false
    @State private var aiReading: String?
    @State private var isLoadingAI = false
    @State private var errorMessage: String?

    private let claudeService = ClaudeService()
    private let astrologyService = AstrologyService()

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer().frame(height: 60)

                Text("Tarot")
                    .font(.custom(titleFont, size: 16))
                    .foregroundColor(accent)
                    .shadow(color: accent.opacity(0.5), radius: 4)

                if showReading {
                    readingView
                } else {
                    cardSelectionView
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Card Selection

    private var cardSelectionView: some View {
        VStack(spacing: 16) {
            Text("Pick 3 Cards")
                .font(.custom(bodyBoldFont, size: 12))
                .foregroundColor(.white)

            Text("Past · Present · Future")
                .font(.custom(bodyFont, size: 10))
                .foregroundColor(.white.opacity(0.4))

            // Selected cards indicator
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { i in
                    if i < selectedCards.count {
                        // Selected card slot
                        VStack(spacing: 3) {
                            Text(["Past", "Present", "Future"][i])
                                .font(.custom(bodyFont, size: 7))
                                .foregroundColor(accent.opacity(0.6))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(accent.opacity(0.3))
                                .frame(width: 40, height: 56)
                                .overlay(
                                    Text("*")
                                        .font(.custom(titleFont, size: 10))
                                        .foregroundColor(accent)
                                )
                        }
                    } else {
                        // Empty slot
                        VStack(spacing: 3) {
                            Text(["Past", "Present", "Future"][i])
                                .font(.custom(bodyFont, size: 7))
                                .foregroundColor(.white.opacity(0.2))

                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                .frame(width: 40, height: 56)
                        }
                    }
                }
            }
            .padding(.bottom, 4)

            // 78 cards grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(shuffledDeck) { card in
                    let isSelected = selectedCards.contains(where: { $0.card.id == card.id })

                    Button(action: { toggleCard(card) }) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(bg.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(isSelected ? accent : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                            )
                            .overlay(
                                VStack(spacing: 2) {
                                    if isSelected {
                                        Text("*")
                                            .font(.custom(titleFont, size: 12))
                                            .foregroundColor(accent)
                                    } else {
                                        Text("?")
                                            .font(.custom(titleFont, size: 12))
                                            .foregroundColor(.white.opacity(0.15))
                                    }
                                }
                            )
                            .frame(height: 90)
                    }
                    .disabled(selectedCards.count >= 3 && !isSelected)
                }
            }

            // Reveal button
            if selectedCards.count == 3 {
                PixelButton("Reveal Cards") {
                    withAnimation { showReading = true }
                }
                .padding(.top, 8)
            }

            Text("\(selectedCards.count)/3 selected")
                .font(.custom(bodyFont, size: 9))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Reading View

    private var readingView: some View {
        VStack(spacing: 16) {
            // Three revealed cards
            ForEach(Array(selectedCards.enumerated()), id: \.element.id) { index, drawn in
                let position = ["Past", "Present", "Future"][index]

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
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(bg.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }

            // AI Reading
            aiReadingSection

            // Draw again
            PixelButton("Draw Again", style: .secondary) {
                resetDraw()
            }
        }
    }

    // MARK: - AI Reading

    private var aiReadingSection: some View {
        VStack(spacing: 12) {
            if let reading = aiReading {
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
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(bg.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(accent.opacity(0.3), lineWidth: 1)
                        )
                )
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

    private func toggleCard(_ card: TarotCard) {
        if let index = selectedCards.firstIndex(where: { $0.card.id == card.id }) {
            withAnimation { selectedCards.remove(at: index) }
        } else if selectedCards.count < 3 {
            let drawn = DrawnCard(card: card, isReversed: Bool.random())
            withAnimation { selectedCards.append(drawn) }
        }
    }

    private func resetDraw() {
        withAnimation {
            showReading = false
            selectedCards = []
            shuffledDeck = TarotCard.allCards.shuffled()
            aiReading = nil
            errorMessage = nil
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
                    cards: selectedCards,
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
                    creditManager.credits += 1
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0b0b2e").ignoresSafeArea()
        TarotView()
    }
}
