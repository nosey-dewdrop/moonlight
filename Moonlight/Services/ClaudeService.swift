import Foundation

class ClaudeService {
    private let model = "claude-sonnet-4-6"
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
            let pos = i < positions.count ? positions[i] : "Card \(i + 1)"
            return "\(pos): \(drawn.card.name) - Keywords: \(drawn.card.keywords.joined(separator: ", "))"
        }.joined(separator: "\n")

        let elementInfo = elementEnergies.map { "\($0.key.displayName): \(Int($0.value * 100))%" }
            .joined(separator: ", ")

        let retroDesc = activeRetrogrades.isEmpty ? "None" : activeRetrogrades.joined(separator: ", ")

        let prompt = """
        Sen gizemli bir ay kahinisin. Sıcak, samimi ama bilge konuşursun. Tarot okuyorsun.

        Soru: "\(question)"
        Doğum haritası: \(userProfile.promptDescription)
        Ay fazı: \(moonPhase.displayName)
        Element enerjileri: \(elementInfo)
        Retrogradlar: \(retroDesc)

        Kartlar:
        \(cardDescriptions)

        Türkçe kart isimleri: Pentacles=Tılsımlar, Cups=Kupalar, Wands=Asalar, Swords=Kılıçlar, Page=Uşak, Knight=Şövalye, Queen=Kraliçe, King=Kral, Ace=As, Two=İki, Three=Üç, Four=Dört, Five=Beş, Six=Altı, Seven=Yedi, Eight=Sekiz, Nine=Dokuz, Ten=On.

        Kartları hikaye gibi birbirine bağla. Her kartın soruyla ilişkisini göster. Ay fazını ve gezegen etkilerini kat. Kişinin düşünmediği açıyı bul.

        KURALLAR:
        - Soranın dilinde yaz.
        - Markdown kullanma. Düz metin.
        - "Net Cevap:", "Açıklama:" gibi başlık/etiket KULLANMA. Doğal akan hikaye yaz.
        - Dolgu cümle yasak. Her cümle yeni bir şey söylesin.
        - Soranın dilinde yaz. Türkçe yazıyorsan eksiksiz, doğru Türkçe yaz. Ekleri doğru kullan (kendini/seni farkı gibi). Devrik cümle kurma. Cümleler net ve anlaşılır olsun.
        - Kişinin aklına gelmeyecek açıları göster. Sorunun altında yatan asıl meseleyi bul.
        - Genel geçer yorum yapma. Bu soruya, bu zamana, bu gezegen dizilimine özel yorum yap.
        - Gezegen pozisyonlarına ve burçlara spesifik değin.
        - Mantıklı ve tutarlı ol. Saçmalama.
        - \(cards.count > 3 ? 400 : 200) kelimeyi geçme.
        """

        let tokens = cards.count > 3 ? 2048 : maxTokens
        return try await sendMessage(prompt, maxTokens: tokens)
    }

    // MARK: - Horary Reading

    func horaryReading(question: String, moonPhase: MoonPhase, elementEnergies: [Element: Double], activeRetrogrades: [String], chartData: HoraryChartData?, userProfile: UserProfile) async throws -> String {
        let elementInfo = elementEnergies.map { "\($0.key.displayName): \(Int($0.value * 100))%" }
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
        Sen gizemli bir ay kahinisin. Sıcak, samimi ama bilge konuşursun. Horary astroloji yapıyorsun.

        Soru: "\(question)"
        Soru zamanı: \(timeStr)
        Doğum haritası: \(userProfile.promptDescription)
        Ay fazı: \(moonPhase.displayName)
        Element enerjileri: \(elementInfo)
        Retrogradlar: \(retroDesc)
        \(chartSection)

        İlk cümlede cevabını ver. Sonra hikaye gibi anlat — neden, gezegen pozisyonları ne diyor, kişinin düşünmediği açı ne.

        KURALLAR:
        - Soranın dilinde yaz. Türkçe yazıyorsan eksiksiz, doğru Türkçe yaz. Ekleri doğru kullan (kendini/seni farkı gibi). Devrik cümle kurma. Cümleler net ve anlaşılır olsun.
        - Markdown kullanma. Düz metin.
        - "Net Cevap:", "Açıklama:" gibi başlık/etiket KULLANMA. Doğal akan hikaye yaz.
        - Dolgu cümle yasak. Her cümle yeni bir şey söylesin.
        - Kişinin aklına gelmeyecek açıları göster. Sorunun altında yatan asıl meseleyi bul.
        - Genel geçer yorum yapma. Bu soruya, bu zamana, bu gezegen dizilimine özel yorum yap.
        - Mantıklı ve tutarlı ol. Saçmalama.
        - 200 kelimeyi geçme.
        """

        return try await sendMessage(prompt)
    }

    // MARK: - Follow-up Reading (Horary)

    func horaryFollowUp(question: String, previousReading: String, moonPhase: MoonPhase, userProfile: UserProfile) async throws -> String {
        let prompt = """
        Sen gizemli bir ay kahinisin. Daha önce bir horary yorumu yaptın. Şimdi aynı soru için farklı bir açıdan devam ediyorsun.

        Soru: "\(question)"
        Önceki yorum: "\(previousReading)"

        Önceki yorumda DEĞİNMEDİĞİN farklı bir açı bul. Başka bir perspektif sun. Tekrar etme, yeni bir şey söyle.

        KURALLAR:
        - Soranın dilinde yaz. Türkçe yazıyorsan eksiksiz, doğru Türkçe yaz. Ekleri doğru kullan. Devrik cümle kurma.
        - Markdown kullanma. Düz metin.
        - Başlık/etiket KULLANMA.
        - Önceki yorumu tekrarlama. Tamamen farklı bir bakış açısı sun.
        - 150 kelimeyi geçme.
        """

        return try await sendMessage(prompt)
    }

    // MARK: - Clarification Card (Tarot)

    func tarotClarification(question: String, previousCards: [DrawnCard], previousReading: String, clarificationCard: DrawnCard, moonPhase: MoonPhase, userProfile: UserProfile) async throws -> String {
        let prevCardNames = previousCards.map { $0.card.name }.joined(separator: ", ")

        let prompt = """
        Sen gizemli bir ay kahinisin. Daha önce tarot okuması yaptın. Şimdi açıklama kartı çekildi.

        Soru: "\(question)"
        Önceki kartlar: \(prevCardNames)
        Önceki yorum: "\(previousReading)"
        Açıklama kartı: \(clarificationCard.card.name) - \(clarificationCard.card.keywords.joined(separator: ", "))

        Türkçe kart isimleri: Pentacles=Tılsımlar, Cups=Kupalar, Wands=Asalar, Swords=Kılıçlar, Page=Uşak, Knight=Şövalye, Queen=Kraliçe, King=Kral.

        Açıklama kartının önceki okumaya ne eklediğini anlat. Önceki yorumda değinilmeyen farklı bir bakış açısı sun. Yeni kartın eski kartlarla ilişkisini göster.

        KURALLAR:
        - Soranın dilinde yaz. Türkçe yazıyorsan eksiksiz, doğru Türkçe yaz. Ekleri doğru kullan. Devrik cümle kurma.
        - Markdown kullanma. Düz metin.
        - Başlık/etiket KULLANMA.
        - Önceki yorumu tekrarlama. Yeni kartın getirdiği farklı açıyı anlat.
        - 150 kelimeyi geçme.
        """

        return try await sendMessage(prompt)
    }

    // MARK: - API Call

    private func sendMessage(_ userMessage: String, maxTokens: Int? = nil) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else { throw ClaudeError.noBackend }

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
    case noBackend
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noBackend: return "Cannot connect to the reading service. Please try again later."
        case .invalidURL: return "Something went wrong. Please try again."
        case .invalidResponse: return "Could not get a reading. Please try again."
        case .apiError(_, let msg): return msg
        case .parseError: return "Could not read the response. Please try again."
        }
    }
}
