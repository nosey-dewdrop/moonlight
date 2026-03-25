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
    @State private var showCreditSheet = false
    @State private var spreadType: String = "custom"
    @State private var questionError = false
    @State private var showClarificationPicker = false
    @State private var clarificationQuestion = ""
    @State private var isLoadingClarification = false
    @State private var currentSpreadCredits = 1

    private let claudeService = ClaudeService()
    private let astrologyService = AstrologyService()

    private var availableCards: [TarotCard] {
        let usedIds = Set(selectedCards.map { $0.card.id })
        return shuffledDeck.filter { !usedIds.contains($0.id) }
    }

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)

                    Text("Tarot")
                        .font(.custom(Theme.titleFont, size: 16))
                        .foregroundColor(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 4)

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
            CreditBadge { showCreditSheet = true }
                .accessibilityLabel("Credits")
                .padding(.top, 54)
                .padding(.trailing, 12)
        }
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .sheet(isPresented: $showCreditSheet) {
            NoCreditView()
        }
    }

    // MARK: - Card Selection

    private var cardSelectionView: some View {
        VStack(spacing: 16) {
            Text("3'e kadar kart seç (okuma başı 1 kredi)")
                .font(.custom(Theme.bodyFont, size: 15))
                .foregroundColor(.white.opacity(0.5))

            // Credits display
            HStack(spacing: 4) {
                Text("\(creditManager.totalCredits)")
                    .font(.custom(Theme.titleFont, size: 10))
                    .foregroundColor(Theme.accent)
                Text("kredi")
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Question input
            TextField("", text: $question, prompt:
                Text("Sorun ne?")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.custom(Theme.bodyFont, size: 15))
            )
            .font(.custom(Theme.bodyFont, size: 15))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.bg.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .onChange(of: question) {
                if questionError { questionError = false }
            }

            if questionError {
                Text("Önce bir soru yaz")
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(Theme.error)
            }

            // Reveal button
            PixelButton(selectedCards.isEmpty ? "Aşağıdan Kart Seç" : "\(selectedCards.count) Kart Aç") {
                if question.trimmingCharacters(in: .whitespaces).isEmpty {
                    questionError = true
                } else {
                    revealCards()
                }
            }
            .accessibilityLabel(selectedCards.isEmpty ? "Select cards below" : "Reveal selected cards")
            .disabled(selectedCards.isEmpty || isLoadingAI)

            // 78 cards grid
            LazyVGrid(columns: Self.columns, spacing: 8) {
                ForEach(shuffledDeck) { card in
                    let isSelected = selectedCards.contains(where: { $0.card.id == card.id })

                    Button(action: { toggleCard(card) }) {
                        ZStack {
                            // Solid opaque background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.cardBg)

                            // Inner border
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(isSelected ? Theme.accent : Theme.cardBorder, lineWidth: 1)
                                .padding(3)

                            // Outer border
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(isSelected ? Theme.accent : Theme.cardOuterBorder, lineWidth: isSelected ? 2 : 1)

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
                                .font(.custom(Theme.titleFont, size: 12))
                                .foregroundColor(isSelected ? Theme.accent : Theme.cardBorder)
                        }
                        .frame(height: 90)
                    }
                    .accessibilityLabel(isSelected ? "Selected tarot card" : "Tarot card")
                    .disabled(selectedCards.count >= 3 && !isSelected)
                }
            }

            Text("\(selectedCards.count)/3 seçildi")
                .font(.custom(Theme.bodyFont, size: 13))
                .foregroundColor(.white.opacity(0.3))

            // Premium spreads
            premiumSpreadsSection
        }
    }

    // MARK: - Premium Spreads

    private var premiumSpreadsSection: some View {
        VStack(spacing: 12) {
            Text("Premium Açılımlar")
                .font(.custom(Theme.titleFont, size: 16))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 20)

            premiumSpreadRow("Kelt Haçı", cards: 10, credits: 10)
            premiumSpreadRow("Beş Kart Açılımı", cards: 5, credits: 5)
            premiumSpreadRow("İlişki Açılımı", cards: 7, credits: 7)
            premiumSpreadRow("Kariyer Yolu", cards: 9, credits: 9)
        }
    }

    private func premiumSpreadRow(_ name: String, cards: Int, credits: Int) -> some View {
        Button(action: { activatePremiumSpread(name, cards: cards, credits: credits) }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.custom(Theme.bodyBoldFont, size: 15))
                        .foregroundColor(.white)
                    Text("\(cards) kart")
                        .font(.custom(Theme.bodyFont, size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Text("\(credits) kredi")
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(Theme.accent)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.bg.opacity(0.85))
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
                .font(.custom(Theme.bodyFont, size: 15))
                .foregroundColor(.white.opacity(0.5))
                .italic()

            // Revealed cards
            ForEach(Array(selectedCards.enumerated()), id: \.element.id) { index, drawn in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(positionName(for: index))
                            .font(.custom(Theme.bodyFont, size: 13))
                            .foregroundColor(Theme.accent.opacity(0.5))
                        Text(drawn.card.name)
                            .font(.custom(Theme.bodyBoldFont, size: 14))
                            .foregroundColor(.white)
                    }

                    Text(drawn.card.keywords.joined(separator: " · "))
                        .font(.custom(Theme.bodyFont, size: 13))
                        .foregroundColor(Theme.accent.opacity(0.7))

                    Text(drawn.card.meaning)
                        .font(.custom(Theme.bodyFont, size: 13))
                        .foregroundColor(.white.opacity(0.6))

                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(minHeight: 90)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.bg.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }

            // AI Reading
            if isLoadingAI {
                HStack(spacing: 8) {
                    PixelLoading(color: Theme.accent)
                    Text("Yıldızlar okunuyor...")
                        .font(.custom(Theme.bodyFont, size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(12)
            }

            if let reading = aiReading {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Yorum")
                        .font(.custom(Theme.titleFont, size: 16))
                        .foregroundColor(Theme.accent)

                    Text(reading)
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(5)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.bg.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                        )
                )

                // Two buttons side by side
                if isLoadingClarification {
                    HStack(spacing: 8) {
                        PixelLoading(color: Theme.accent)
                        Text("Açıklama kartı çekiliyor...")
                            .font(.custom(Theme.bodyFont, size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(12)
                }

                HStack(spacing: 10) {
                    PixelButton("Devam") {
                        drawClarificationCard()
                    }
                    .disabled(isLoadingAI || isLoadingClarification || showClarificationPicker)
                    PixelButton("Tamam", style: .secondary) {
                        resetDraw()
                    }
                    .disabled(isLoadingAI || isLoadingClarification)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(Theme.error.opacity(0.7))
            }

            // Clarification picker
            if showClarificationPicker {
                VStack(spacing: 12) {
                    Text("Takip sorusu (isteğe bağlı)")
                        .font(.custom(Theme.bodyFont, size: 14))
                        .foregroundColor(.white.opacity(0.5))

                    TextField("", text: $clarificationQuestion, prompt:
                        Text("Neyi daha çok merak ediyorsun?")
                            .foregroundColor(.white.opacity(0.3))
                            .font(.custom(Theme.bodyFont, size: 15))
                    )
                    .font(.custom(Theme.bodyFont, size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.bg.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )

                    Text("Açıklama kartı seç (1 kredi)")
                        .font(.custom(Theme.bodyFont, size: 14))
                        .foregroundColor(Theme.accent.opacity(0.7))

                    LazyVGrid(columns: Self.columns, spacing: 8) {
                        ForEach(availableCards) { card in
                            Button(action: { submitClarification(card: card) }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.cardBg)
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Theme.cardOuterBorder, lineWidth: 1)
                                        .padding(3)
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Theme.cardOuterBorder, lineWidth: 1)
                                    VStack {
                                        HStack {
                                            pixelDot(false); Spacer(); pixelDot(false)
                                        }
                                        Spacer()
                                        HStack {
                                            pixelDot(false); Spacer(); pixelDot(false)
                                        }
                                    }
                                    .padding(6)
                                    Text("?")
                                        .font(.custom(Theme.titleFont, size: 12))
                                        .foregroundColor(Theme.cardBorder)
                                }
                                .frame(height: 90)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func pixelDot(_ active: Bool) -> some View {
        Rectangle()
            .fill(active ? Theme.accent : Theme.cardBorder)
            .frame(width: 3, height: 3)
    }

    private func toggleCard(_ card: TarotCard) {
        if let index = selectedCards.firstIndex(where: { $0.card.id == card.id }) {
            _ = withAnimation { selectedCards.remove(at: index) }
        } else if selectedCards.count < 3 {
            let drawn = DrawnCard(card: card)
            withAnimation { selectedCards.append(drawn) }
        }
    }

    private func revealCards() {
        guard !isLoadingAI else { return }
        guard creditManager.useCredit() else {
            showCreditSheet = true
            return
        }

        spreadType = "custom"
        currentSpreadCredits = 1
        withAnimation { showReading = true }
        requestAIReading()
    }

    private func drawClarificationCard() {
        guard creditManager.hasCredits else {
            showCreditSheet = true
            return
        }
        showClarificationPicker = true
    }

    private func submitClarification(card: TarotCard) {
        guard !isLoadingClarification else { return }
        guard creditManager.useCredit() else {
            showCreditSheet = true
            return
        }

        let clarification = DrawnCard(card: card)
        selectedCards.append(clarification)
        showClarificationPicker = false
        isLoadingClarification = true
        errorMessage = nil

        Task {
            do {
                let moonData = MoonService().calculateMoonPhase(date: Date())
                let previousReading = aiReading ?? ""
                let fullQuestion = clarificationQuestion.isEmpty ? question : "\(question) — Follow-up: \(clarificationQuestion)"

                let reading = try await claudeService.tarotClarification(
                    question: fullQuestion,
                    previousCards: Array(selectedCards.dropLast()),
                    previousReading: previousReading,
                    clarificationCard: clarification,
                    moonPhase: moonData.phase,
                    userProfile: userProfile
                )

                await MainActor.run {
                    aiReading = (aiReading ?? "") + "\n\n" + reading
                    isLoadingClarification = false
                    clarificationQuestion = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = userFriendlyError(error)
                    isLoadingClarification = false
                    creditManager.refundCredit()
                }
            }
        }
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
            showClarificationPicker = false
            clarificationQuestion = ""
            isLoadingClarification = false
            currentSpreadCredits = 1
        }
    }

    private func activatePremiumSpread(_ name: String, cards: Int, credits: Int) {
        guard !isLoadingAI else { return }
        guard !question.trimmingCharacters(in: .whitespaces).isEmpty else {
            questionError = true
            return
        }

        guard creditManager.useCredits(credits) else {
            showCreditSheet = true
            return
        }

        currentSpreadCredits = credits

        // Determine spread type (Turkish labels)
        if name.contains("Kelt") {
            spreadType = "celtic_cross"
        } else if name.contains("Beş") {
            spreadType = "five_card"
        } else if name.contains("İlişki") {
            spreadType = "relationship"
        } else if name.contains("Kariyer") {
            spreadType = "career"
        }

        // Auto-select random cards from shuffled deck
        let deck = TarotCard.allCards.shuffled()
        var drawn: [DrawnCard] = []
        for i in 0..<min(cards, deck.count) {
            drawn.append(DrawnCard(card: deck[i]))
        }
        selectedCards = drawn

        withAnimation { showReading = true }
        requestAIReading()
    }

    private func positionName(for index: Int) -> String {
        let names: [String]
        switch spreadType {
        case "celtic_cross":
            names = ["Durum", "Engel", "Geçmiş", "Gelecek", "Üst", "Alt", "Tavsiye", "Dış Etki", "Umutlar", "Sonuç"]
        case "five_card":
            names = ["Geçmiş", "Şimdi", "Gizli", "Tavsiye", "Sonuç"]
        case "relationship":
            names = ["Sen", "Partner", "Bağ", "Engel", "Güç", "Tavsiye", "Sonuç"]
        case "career":
            names = ["Şimdi", "Engel", "Güç", "Zayıflık", "Hedef", "Yol", "Çevre", "Umutlar", "Sonuç"]
        default:
            names = ["Geçmiş", "Şimdi", "Gelecek"]
        }
        if index < names.count {
            return names[index]
        }
        return "Açıklama"
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

                let reading = try await claudeService.tarotReading(
                    question: question,
                    cards: selectedCards,
                    spreadType: spreadType,
                    moonPhase: moonData.phase,
                    elementEnergies: energies,
                    activeRetrogrades: activeRetros,
                    userProfile: userProfile
                )

                await MainActor.run {
                    aiReading = reading
                    isLoadingAI = false
                    ReadingHistory.shared.add(question: question, type: .tarot)
                }
            } catch {
                await MainActor.run {
                    errorMessage = userFriendlyError(error)
                    isLoadingAI = false
                    creditManager.refundCredits(currentSpreadCredits)
                }
            }
        }
    }

    private func userFriendlyError(_ error: Error) -> String {
        if let claudeError = error as? ClaudeError {
            return claudeError.errorDescription ?? "Bir şeyler ters gitti. Tekrar dene."
        }
        if (error as NSError).code == NSURLErrorTimedOut {
            return "İstek zaman aşımına uğradı. Tekrar dene."
        }
        if (error as NSError).code == NSURLErrorNotConnectedToInternet {
            return "İnternet bağlantısı yok. Ağını kontrol et."
        }
        return "Bir şeyler ters gitti. Tekrar dene."
    }
}

#Preview {
    ZStack {
        Color(hex: "#0b0b2e").ignoresSafeArea()
        TarotView()
    }
}
