import SwiftUI

struct TarotView: View {
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var userProfile = UserProfile.shared
    @State private var question = ""
    @State private var selectedCards: [DrawnCard] = []
    @State private var shuffledDeck: [TarotCard] = TarotCard.allCards.shuffled()
    @State private var showReading = false
    @State private var aiReading: String?
    @State private var isLoadingAI = false
    @State private var errorMessage: String?
    @State private var showNoCredit = false
    @State private var showPremium = false
    @State private var spreadType: String = "custom"
    @State private var questionError = false

    private let claudeService = ClaudeService()
    private let astrologyService = AstrologyService()

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            // Credit badge top right
            CreditBadge { showPremium = true }
                .accessibilityLabel("Credits")
                .padding(.top, 54)
                .padding(.trailing, 12)
        }
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .sheet(isPresented: $showNoCredit) {
            NoCreditView()
        }
        .sheet(isPresented: $showPremium) {
            NoCreditView()
        }
    }

    // MARK: - Card Selection

    private var cardSelectionView: some View {
        VStack(spacing: 16) {
            Text("Pick up to 3 cards")
                .font(.custom(bodyFont, size: 11))
                .foregroundColor(.white.opacity(0.5))

            // Credits display
            HStack(spacing: 4) {
                Text("\(creditManager.totalCredits)")
                    .font(.custom(titleFont, size: 10))
                    .foregroundColor(accent)
                Text("credits")
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Question input
            TextField("", text: $question, prompt:
                Text("What is your question?")
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
            .submitLabel(.done)
            .onChange(of: question) { _ in
                if questionError { questionError = false }
            }

            if questionError {
                Text("Please enter a question first")
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(Color(hex: "#FF6B6B"))
            }

            // Reveal button
            PixelButton(selectedCards.isEmpty ? "Select Cards Below" : "Reveal \(selectedCards.count) Card\(selectedCards.count > 1 ? "s" : "")") {
                revealCards()
            }
            .accessibilityLabel(selectedCards.isEmpty ? "Select cards below" : "Reveal selected cards")
            .disabled(selectedCards.isEmpty || question.trimmingCharacters(in: .whitespaces).isEmpty)

            // 78 cards grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(shuffledDeck) { card in
                    let isSelected = selectedCards.contains(where: { $0.card.id == card.id })

                    Button(action: { toggleCard(card) }) {
                        ZStack {
                            // Solid opaque background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "#12123a"))

                            // Inner border
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(isSelected ? accent : Color(hex: "#2a2a5e"), lineWidth: 1)
                                .padding(3)

                            // Outer border
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(isSelected ? accent : Color(hex: "#1e1e4e"), lineWidth: isSelected ? 2 : 1)

                            // Corner dots
                            VStack {
                                HStack {
                                    pixelDot(isSelected)
                                    Spacer()
                                    pixelDot(isSelected)
                                }
                                Spacer()
                                HStack {
                                    pixelDot(isSelected)
                                    Spacer()
                                    pixelDot(isSelected)
                                }
                            }
                            .padding(6)

                            // Center symbol
                            Text(isSelected ? "*" : "?")
                                .font(.custom(titleFont, size: 12))
                                .foregroundColor(isSelected ? accent : Color(hex: "#2a2a5e"))
                        }
                        .frame(height: 90)
                    }
                    .accessibilityLabel(isSelected ? "Selected tarot card" : "Tarot card")
                    .disabled(selectedCards.count >= 3 && !isSelected)
                }
            }

            Text("\(selectedCards.count)/3 selected")
                .font(.custom(bodyFont, size: 9))
                .foregroundColor(.white.opacity(0.3))

            // Premium spreads
            premiumSpreadsSection
        }
    }

    // MARK: - Premium Spreads

    private var premiumSpreadsSection: some View {
        VStack(spacing: 12) {
            Text("Premium Spreads")
                .font(.custom(titleFont, size: 8))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 20)

            premiumSpreadRow("Celtic Cross", cards: 10, credits: 10)
            premiumSpreadRow("Five Card Spread", cards: 5, credits: 5)
            premiumSpreadRow("Relationship Spread", cards: 7, credits: 7)
            premiumSpreadRow("Career Path", cards: 9, credits: 9)
        }
    }

    private func premiumSpreadRow(_ name: String, cards: Int, credits: Int) -> some View {
        Button(action: { activatePremiumSpread(name, cards: cards, credits: credits) }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.custom(bodyBoldFont, size: 11))
                        .foregroundColor(.white)
                    Text("\(cards) cards")
                        .font(.custom(bodyFont, size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Text("\(credits) credits")
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(accent)
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
    }

    // MARK: - Reading View

    private var readingView: some View {
        VStack(spacing: 16) {
            // Question
            Text("\"\(question)\"")
                .font(.custom(bodyFont, size: 11))
                .foregroundColor(.white.opacity(0.5))
                .italic()

            // Revealed cards
            ForEach(Array(selectedCards.enumerated()), id: \.element.id) { index, drawn in
                let position = positionName(for: index)

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

            // Draw again
            PixelButton("Draw Again", style: .secondary) {
                resetDraw()
            }

            // AI Reading below Draw Again
            if isLoadingAI {
                HStack(spacing: 8) {
                    PixelLoading(color: accent)
                    Text("Reading the stars...")
                        .font(.custom(bodyFont, size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(12)
            }

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
            }

            if let error = errorMessage {
                Text(error)
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(Color(hex: "#FF6B6B").opacity(0.7))
            }
        }
    }

    // MARK: - Actions

    private func pixelDot(_ active: Bool) -> some View {
        Rectangle()
            .fill(active ? accent : Color(hex: "#2a2a5e"))
            .frame(width: 3, height: 3)
    }

    private func toggleCard(_ card: TarotCard) {
        if let index = selectedCards.firstIndex(where: { $0.card.id == card.id }) {
            withAnimation { selectedCards.remove(at: index) }
        } else if selectedCards.count < 3 {
            let drawn = DrawnCard(card: card, isReversed: Bool.random())
            withAnimation { selectedCards.append(drawn) }
        }
    }

    private func revealCards() {
        guard !isLoadingAI else { return }
        let cost = selectedCards.count
        guard creditManager.useCredits(cost) else {
            showNoCredit = true
            return
        }

        spreadType = "custom"
        withAnimation { showReading = true }
        requestAIReading()
    }

    private func resetDraw() {
        withAnimation {
            showReading = false
            selectedCards = []
            shuffledDeck = TarotCard.allCards.shuffled()
            aiReading = nil
            errorMessage = nil
            question = ""
            spreadType = "custom"
            questionError = false
        }
    }

    private func activatePremiumSpread(_ name: String, cards: Int, credits: Int) {
        guard !question.trimmingCharacters(in: .whitespaces).isEmpty else {
            questionError = true
            return
        }

        guard creditManager.useCredits(credits) else {
            showNoCredit = true
            return
        }

        // Determine spread type
        if name.contains("Celtic") {
            spreadType = "celtic_cross"
        } else if name.contains("Five") {
            spreadType = "five_card"
        } else if name.contains("Relationship") {
            spreadType = "relationship"
        } else if name.contains("Career") {
            spreadType = "career"
        }

        // Auto-select random cards from shuffled deck
        let deck = TarotCard.allCards.shuffled()
        var drawn: [DrawnCard] = []
        for i in 0..<cards {
            drawn.append(DrawnCard(card: deck[i], isReversed: Bool.random()))
        }
        selectedCards = drawn

        withAnimation { showReading = true }
        requestAIReading()
    }

    private func positionName(for index: Int) -> String {
        switch spreadType {
        case "celtic_cross":
            return ["Situation", "Challenge", "Past", "Future", "Above", "Below", "Advice", "External", "Hopes", "Outcome"][index]
        case "five_card":
            return ["Past", "Present", "Hidden", "Advice", "Outcome"][index]
        case "relationship":
            return ["You", "Partner", "Connection", "Challenge", "Strength", "Advice", "Outcome"][index]
        case "career":
            return ["Current", "Obstacle", "Strength", "Weakness", "Goal", "Path", "Environment", "Hopes", "Outcome"][index]
        default:
            if selectedCards.count == 1 { return "Your Card" }
            return ["Past", "Present", "Future"][index]
        }
    }

    private func requestAIReading() {
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
                    question: question,
                    cards: selectedCards,
                    spreadType: spreadType,
                    moonPhase: moonData.phase,
                    elementEnergies: energies,
                    activeRetrogrades: activeRetros,
                    userProfile: userProfile,
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
                    creditManager.refundCredits(selectedCards.count)
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
