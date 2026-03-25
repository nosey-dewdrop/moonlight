import SwiftUI

struct HoraryView: View {
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var userProfile = UserProfile.shared
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var question = ""
    @State private var aiReading: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasAsked = false
    @State private var showNoCredit = false
    @State private var activeAITask: Task<Void, Never>?

    private let moonService = MoonService()
    private let astrologyService = AstrologyService()
    private let claudeService = ClaudeService()
    private let chartService = HoraryChartService()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer().frame(height: 60)

                    Text("Horary")
                        .font(.custom(Theme.titleFont, size: 16))
                        .foregroundColor(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 4)

                    Text("Ay'a Bir Soru Sor")
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.5))

                // Question input
                questionInput

                if hasAsked {
                    // AI reading
                    if let reading = aiReading {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Yorum")
                                .font(.custom(Theme.titleFont, size: 16))
                                .foregroundColor(Theme.accent)

                            Text(reading)
                                .font(.custom(Theme.bodyFont, size: 15))
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(5)

                            Text("Bu yorum yalnızca eğlence amacıyladır!")
                                .font(.custom(Theme.bodyFont, size: 11))
                                .foregroundColor(.white.opacity(0.2))
                                .padding(.top, 6)
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
                        HStack(spacing: 10) {
                            PixelButton("Devam") {
                                requestFollowUp()
                            }
                            .disabled(isLoading)
                            PixelButton("Tamam", style: .secondary) {
                                resetQuestion()
                            }
                            .disabled(isLoading)
                        }
                    }

                    if isLoading {
                        HStack(spacing: 8) {
                            PixelLoading(color: Theme.accent)
                            Text("Yıldızlara danışılıyor...")
                                .font(.custom(Theme.bodyFont, size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(12)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.custom(Theme.bodyFont, size: 13))
                            .foregroundColor(Theme.error.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
            // Credit badge top right
            CreditBadge { showNoCredit = true }
                .accessibilityLabel("Credits")
                .padding(.top, 54)
                .padding(.trailing, 12)
        }
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .onDisappear {
            activeAITask?.cancel()
        }
        .sheet(isPresented: $showNoCredit) {
            NoCreditView()
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }

    // MARK: - Question Input

    private var questionInput: some View {
        VStack(spacing: 12) {
            TextField("", text: $question, prompt:
                Text("Aklından ne geçiyor?")
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
            .accessibilityLabel("Enter your question")
            .onSubmit {
                if !question.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading {
                    askQuestion()
                }
            }

            PixelButton("Yıldızlara Sor (1 kredi)") {
                askQuestion()
            }
            .accessibilityLabel("Ask the stars")
            .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
    }

    // MARK: - Actions

    private func askQuestion() {
        guard !isLoading else { return }
        guard creditManager.useCredit() else {
            showNoCredit = true
            return
        }

        isLoading = true
        errorMessage = nil
        withAnimation { hasAsked = true }
        activeAITask?.cancel()

        activeAITask = Task {
            do {
                let moonData = moonService.calculateMoonPhase(date: Date())
                let events = try await astrologyService.fetchEvents()
                let activeRetros = events.filter { $0.isActive && $0.type == .retrograde }.map { $0.title }
                let energies = Element.adjustedEnergies(for: moonData.phase, activeRetrogrades: activeRetros)

                // Fetch horary chart from FreeAstrologyAPI
                let lat = locationManager.latitude
                let lon = locationManager.longitude
                let chartData = try? await chartService.fetchChart(latitude: lat, longitude: lon)

                try Task.checkCancellation()

                let reading = try await claudeService.horaryReading(
                    question: question,
                    moonPhase: moonData.phase,
                    elementEnergies: energies,
                    activeRetrogrades: activeRetros,
                    chartData: chartData,
                    userProfile: userProfile
                )

                await MainActor.run {
                    aiReading = reading
                    isLoading = false
                    ReadingHistory.shared.add(question: question, type: .horary)
                }
            } catch is CancellationError {
                // Task cancelled, no action needed
            } catch {
                await MainActor.run {
                    errorMessage = userFriendlyError(error)
                    isLoading = false
                    creditManager.refundCredit()
                }
            }
        }
    }

    private func requestFollowUp() {
        guard !isLoading else { return }
        guard creditManager.useCredit() else {
            showNoCredit = true
            return
        }

        guard let previousReading = aiReading else {
            creditManager.refundCredit()
            return
        }

        isLoading = true
        errorMessage = nil
        activeAITask?.cancel()

        activeAITask = Task {
            do {
                let moonData = moonService.calculateMoonPhase(date: Date())

                let followUp = try await claudeService.horaryFollowUp(
                    question: question,
                    previousReading: previousReading,
                    moonPhase: moonData.phase,
                    userProfile: userProfile
                )

                await MainActor.run {
                    aiReading = (aiReading ?? "") + "\n\n" + followUp
                    isLoading = false
                }
            } catch is CancellationError {
                // Task cancelled, no action needed
            } catch {
                await MainActor.run {
                    errorMessage = userFriendlyError(error)
                    isLoading = false
                    creditManager.refundCredit()
                }
            }
        }
    }

    private func resetQuestion() {
        withAnimation {
            hasAsked = false
            aiReading = nil
            errorMessage = nil
            question = ""
        }
    }

    private func userFriendlyError(_ error: Error) -> String {
        if let claudeError = error as? ClaudeError {
            return claudeError.localizedDescription
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
        Theme.bg.ignoresSafeArea()
        HoraryView()
    }
}
