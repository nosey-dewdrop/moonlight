import Foundation

class ClaudeService {
    private let model = "claude-haiku-4-5-20251001"
    private let maxTokens = 1024

    private var apiKey: String {
        Secrets.claudeApiKey
    }

    // MARK: - Tarot Reading

    private func positionNames(for spreadType: String, count: Int) -> [String] {
        switch spreadType {
        case "celtic_cross":
            return ["Situation", "Challenge", "Past", "Future", "Above", "Below", "Advice", "External", "Hopes", "Outcome"]
        case "five_card":
            return ["Past", "Present", "Hidden", "Advice", "Outcome"]
        case "relationship":
            return ["You", "Partner", "Connection", "Challenge", "Strength", "Advice", "Outcome"]
        case "career":
            return ["Current", "Obstacle", "Strength", "Weakness", "Goal", "Path", "Environment", "Hopes", "Outcome"]
        default:
            if count == 1 { return ["Card"] }
            return ["Past", "Present", "Future"]
        }
    }

    func tarotReading(question: String, cards: [DrawnCard], spreadType: String = "custom", moonPhase: MoonPhase, elementEnergies: [Element: Double], activeRetrogrades: [String], userProfile: UserProfile) async throws -> String {
        let positions = positionNames(for: spreadType, count: cards.count)
        let cardDescriptions = cards.enumerated().map { i, drawn in
            let pos = positions[i]
            return "\(pos): \(drawn.card.name) (\(drawn.positionLabel)) - Keywords: \(drawn.card.keywords.joined(separator: ", "))"
        }.joined(separator: "\n")

        let elementDesc = elementEnergies.map { "\($0.key.displayName): \(Int($0.value * 100))%" }
            .joined(separator: ", ")

        let retroDesc = activeRetrogrades.isEmpty ? "None" : activeRetrogrades.joined(separator: ", ")

        let prompt = """
        Sen gizemli bir ay kahinisin. Sıcak, samimi ama bilge bir üslupla konuşursun. Abartılı veya yapmacık değilsin — doğal ve içten konuşursun.

        Soran kişinin sorusu: "\(question)"

        Doğum haritası: \(userProfile.promptDescription)
        Şu anki ay fazı: \(moonPhase.displayName)
        Element enerjileri: \(elementDesc)
        Aktif retrogradlar: \(retroDesc)

        Çekilen tarot kartları:
        \(cardDescriptions)

        Kartları birbirine bağlayarak tutarlı bir yorum yap. Ay fazını, element dengesini ve kişinin burcunu yoruma kat. Her kartın pozisyonuna değin. Mistik ama pratik ol — kişi somut bir şey öğrenmiş olsun.

        KRİTİK KURALLAR:
        - Soranın dilinde cevap ver. Türkçe sorduysa Türkçe, İngilizce sorduysa İngilizce.
        - Asla markdown kullanma (**, ##, * gibi). Düz metin yaz.
        - Asla İngilizce terim karıştırma (Türkçe yazıyorsan).
        - Doğal konuş, abartma, yapmacık olma.
        - \(cards.count > 3 ? 400 : 200) kelimeyi geçme.
        """

        let tokens = cards.count > 3 ? 2048 : maxTokens
        return try await sendMessage(prompt, maxTokens: tokens)
    }

    // MARK: - Horary Reading

    func horaryReading(question: String, moonPhase: MoonPhase, elementEnergies: [Element: Double], activeRetrogrades: [String], chartData: HoraryChartData?, userProfile: UserProfile) async throws -> String {
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
        Sen horary astroloji yapan gizemli bir ay kahinisin. Sıcak, samimi ama bilge konuşursun. Yapmacık değilsin.

        Soran kişinin sorusu: "\(question)"
        Soru zamanı: \(timeStr)

        Doğum haritası: \(userProfile.promptDescription)
        Şu anki ay fazı: \(moonPhase.displayName)
        Element enerjileri: \(elementDesc)
        Aktif retrogradlar: \(retroDesc)
        \(chartSection)

        Horary astroloji yorumu yap. Şunları hesaba kat:
        - Ay fazının sorunun zamanlamasına etkisi
        - Kişinin doğum haritası ve mevcut geçişlerle etkileşimi
        - Hangi elementler güçlü/zayıf ve soruyla ilişkisi
        - Retrogradların geciktirici etkisi
        \(chartData != nil ? "- Horary haritadaki gezegen pozisyonları ve ev yerleşimleri" : "")

        Net bir evet/hayır eğilimi ver, ama nüanslı açıkla. Yıldızlar hayır diyorsa güzelce söyle.

        KRİTİK KURALLAR:
        - Soranın dilinde cevap ver. Türkçe sorduysa Türkçe, İngilizce sorduysa İngilizce.
        - Asla markdown kullanma (**, ##, * gibi). Düz metin yaz.
        - Asla İngilizce terim karıştırma (Türkçe yazıyorsan).
        - Doğal konuş, abartma, yapmacık olma.
        - 200 kelimeyi geçme.
        """

        return try await sendMessage(prompt)
    }

    // MARK: - API Call

    private func sendMessage(_ userMessage: String, maxTokens: Int? = nil) async throws -> String {
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
            "max_tokens": maxTokens ?? self.maxTokens,
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
