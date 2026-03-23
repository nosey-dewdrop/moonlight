import Foundation

class ClaudeService {
    private let model = "claude-haiku-4-5-20251001"
    private let maxTokens = 1024

    private var apiKey: String {
        Secrets.claudeApiKey
    }

    // MARK: - Tarot Reading

    func tarotReading(question: String, cards: [DrawnCard], moonPhase: MoonPhase, elementEnergies: [Element: Double], activeRetrogrades: [String], userProfile: UserProfile, language: String) async throws -> String {
        let cardDescriptions = cards.enumerated().map { i, drawn in
            let pos = cards.count == 1 ? "Card" : (i == 0 ? "Past" : (i == 1 ? "Present" : "Future"))
            return "\(pos): \(drawn.card.name) (\(drawn.positionLabel)) - Keywords: \(drawn.card.keywords.joined(separator: ", "))"
        }.joined(separator: "\n")

        let elementDesc = elementEnergies.map { "\($0.key.displayName): \(Int($0.value * 100))%" }
            .joined(separator: ", ")

        let retroDesc = activeRetrogrades.isEmpty ? "None" : activeRetrogrades.joined(separator: ", ")

        let prompt = """
        You are a mystical pixel-art moon oracle. You speak in a poetic, enigmatic, yet warm tone — like a wise celestial being made of starlight and ancient code.

        The seeker asks: "\(question)"

        Seeker's birth chart: \(userProfile.promptDescription)
        Current moon phase: \(moonPhase.displayName)
        Element energies: \(elementDesc)
        Active retrogrades: \(retroDesc)

        The seeker drew these tarot cards:
        \(cardDescriptions)

        Give a cohesive reading that weaves the cards together with the current cosmic energies and the seeker's birth chart. Consider how the moon phase, element balance, and the seeker's signs affect the reading. Keep it mystical but practical — the seeker should walk away with actionable insight.

        Respond in \(language). Keep it under 200 words.
        """

        return try await sendMessage(prompt)
    }

    // MARK: - Horary Reading

    func horaryReading(question: String, moonPhase: MoonPhase, elementEnergies: [Element: Double], activeRetrogrades: [String], chartData: HoraryChartData?, userProfile: UserProfile, language: String) async throws -> String {
        let elementDesc = elementEnergies.map { "\($0.key.displayName): \(Int($0.value * 100))%" }
            .joined(separator: ", ")

        let retroDesc = activeRetrogrades.isEmpty ? "None" : activeRetrogrades.joined(separator: ", ")

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timeStr = formatter.string(from: now)

        var chartSection = ""
        if let chart = chartData {
            chartSection = """

            Horary chart data for this moment:
            \(chart.promptDescription)
            """
        }

        let prompt = """
        You are a mystical pixel-art moon oracle practicing horary astrology. You speak in a poetic, enigmatic, yet warm tone — like a wise celestial being made of starlight and ancient code.

        The seeker asks: "\(question)"
        Question asked at: \(timeStr)

        Seeker's birth chart: \(userProfile.promptDescription)
        Current moon phase: \(moonPhase.displayName)
        Element energies: \(elementDesc)
        Active retrogrades: \(retroDesc)
        \(chartSection)

        Provide a horary astrology interpretation. Consider:
        - The moon phase's influence on the question's timing and outcome
        - The seeker's birth chart and how their signs interact with current transits
        - Which elements are strong/weak and how they relate to the question
        - How active retrogrades might delay or complicate matters
        - Traditional horary rules about the moon's condition
        \(chartData != nil ? "- The planetary positions and house placements in the horary chart" : "")

        Give a clear yes/no leaning with nuanced explanation. Be mystical but honest — if the stars say no, say it beautifully.

        Respond in \(language). Keep it under 200 words.
        """

        return try await sendMessage(prompt)
    }

    // MARK: - API Call

    private func sendMessage(_ userMessage: String) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else {
            throw ClaudeError.noApiKey
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw ClaudeError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            switch httpResponse.statusCode {
            case 401:
                throw ClaudeError.apiError(statusCode: 401, message: "Invalid API key")
            case 429:
                throw ClaudeError.apiError(statusCode: 429, message: "Too many requests. Please wait a moment.")
            case 529:
                throw ClaudeError.apiError(statusCode: 529, message: "Service is busy. Please try again.")
            default:
                throw ClaudeError.apiError(statusCode: httpResponse.statusCode, message: "Something went wrong. Please try again.")
            }
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeError.parseError
        }

        return text
    }
}

enum ClaudeError: LocalizedError {
    case noApiKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "No API key configured"
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .apiError(let code, let msg): return "API error (\(code)): \(msg)"
        case .parseError: return "Failed to parse response"
        }
    }
}
