import Foundation

enum Arcana: String, Codable {
    case major
    case minor
}

enum Suit: String, Codable, CaseIterable {
    case wands
    case cups
    case swords
    case pentacles

    var displayName: String {
        rawValue.capitalized
    }
}

struct TarotCard: Identifiable, Codable {
    let id: Int
    let name: String
    let arcana: Arcana
    let suit: Suit?
    let keywords: [String]
    let meaning: String
    let imageName: String

    static let allCards: [TarotCard] = majorArcana + minorArcana

    // MARK: - Major Arcana (22 cards)

    static let majorArcana: [TarotCard] = [
        TarotCard(id: 0, name: "The Fool", arcana: .major, suit: nil,
                  keywords: ["beginnings", "innocence", "adventure"],
                  meaning: "New beginnings, spontaneity, a free spirit",
                  imageName: "tarot_fool"),
        TarotCard(id: 1, name: "The Magician", arcana: .major, suit: nil,
                  keywords: ["willpower", "creation", "manifestation"],
                  meaning: "Manifestation, resourcefulness, inspired action",
                  imageName: "tarot_magician"),
        TarotCard(id: 2, name: "The High Priestess", arcana: .major, suit: nil,
                  keywords: ["intuition", "mystery", "subconscious"],
                  meaning: "Intuition, sacred knowledge, the subconscious mind",
                  imageName: "tarot_high_priestess"),
        TarotCard(id: 3, name: "The Empress", arcana: .major, suit: nil,
                  keywords: ["abundance", "nurturing", "fertility"],
                  meaning: "Femininity, beauty, nature, abundance",
                  imageName: "tarot_empress"),
        TarotCard(id: 4, name: "The Emperor", arcana: .major, suit: nil,
                  keywords: ["authority", "structure", "stability"],
                  meaning: "Authority, establishment, structure, a father figure",
                  imageName: "tarot_emperor"),
        TarotCard(id: 5, name: "The Hierophant", arcana: .major, suit: nil,
                  keywords: ["tradition", "wisdom", "guidance"],
                  meaning: "Spiritual wisdom, religious beliefs, tradition",
                  imageName: "tarot_hierophant"),
        TarotCard(id: 6, name: "The Lovers", arcana: .major, suit: nil,
                  keywords: ["love", "harmony", "choices"],
                  meaning: "Love, harmony, relationships, values alignment",
                  imageName: "tarot_lovers"),
        TarotCard(id: 7, name: "The Chariot", arcana: .major, suit: nil,
                  keywords: ["determination", "willpower", "victory"],
                  meaning: "Control, willpower, success, determination",
                  imageName: "tarot_chariot"),
        TarotCard(id: 8, name: "Strength", arcana: .major, suit: nil,
                  keywords: ["courage", "patience", "compassion"],
                  meaning: "Strength, courage, patience, compassion",
                  imageName: "tarot_strength"),
        TarotCard(id: 9, name: "The Hermit", arcana: .major, suit: nil,
                  keywords: ["solitude", "reflection", "inner guidance"],
                  meaning: "Soul searching, introspection, being alone",
                  imageName: "tarot_hermit"),
        TarotCard(id: 10, name: "Wheel of Fortune", arcana: .major, suit: nil,
                  keywords: ["fate", "cycles", "turning point"],
                  meaning: "Good luck, karma, life cycles, destiny",
                  imageName: "tarot_wheel"),
        TarotCard(id: 11, name: "Justice", arcana: .major, suit: nil,
                  keywords: ["truth", "fairness", "law"],
                  meaning: "Justice, fairness, truth, cause and effect",
                  imageName: "tarot_justice"),
        TarotCard(id: 12, name: "The Hanged Man", arcana: .major, suit: nil,
                  keywords: ["surrender", "perspective", "pause"],
                  meaning: "Pause, surrender, letting go, new perspectives",
                  imageName: "tarot_hanged_man"),
        TarotCard(id: 13, name: "Death", arcana: .major, suit: nil,
                  keywords: ["endings", "transformation", "transition"],
                  meaning: "Endings, change, transformation, transition",
                  imageName: "tarot_death"),
        TarotCard(id: 14, name: "Temperance", arcana: .major, suit: nil,
                  keywords: ["balance", "moderation", "patience"],
                  meaning: "Balance, moderation, patience, finding meaning",
                  imageName: "tarot_temperance"),
        TarotCard(id: 15, name: "The Devil", arcana: .major, suit: nil,
                  keywords: ["shadow", "attachment", "excess"],
                  meaning: "Shadow self, attachment, addiction, restriction",
                  imageName: "tarot_devil"),
        TarotCard(id: 16, name: "The Tower", arcana: .major, suit: nil,
                  keywords: ["upheaval", "revelation", "awakening"],
                  meaning: "Sudden change, upheaval, chaos, revelation",
                  imageName: "tarot_tower"),
        TarotCard(id: 17, name: "The Star", arcana: .major, suit: nil,
                  keywords: ["hope", "faith", "renewal"],
                  meaning: "Hope, faith, purpose, renewal, spirituality",
                  imageName: "tarot_star"),
        TarotCard(id: 18, name: "The Moon", arcana: .major, suit: nil,
                  keywords: ["illusion", "intuition", "unconscious"],
                  meaning: "Illusion, fear, anxiety, subconscious, intuition",
                  imageName: "tarot_moon"),
        TarotCard(id: 19, name: "The Sun", arcana: .major, suit: nil,
                  keywords: ["joy", "success", "vitality"],
                  meaning: "Positivity, fun, warmth, success, vitality",
                  imageName: "tarot_sun"),
        TarotCard(id: 20, name: "Judgement", arcana: .major, suit: nil,
                  keywords: ["reflection", "reckoning", "rebirth"],
                  meaning: "Judgement, rebirth, inner calling, absolution",
                  imageName: "tarot_judgement"),
        TarotCard(id: 21, name: "The World", arcana: .major, suit: nil,
                  keywords: ["completion", "achievement", "wholeness"],
                  meaning: "Completion, integration, accomplishment, travel",
                  imageName: "tarot_world"),
    ]

    // MARK: - Minor Arcana (56 cards)

    static let minorArcana: [TarotCard] = {
        var cards: [TarotCard] = []
        var nextId = 22

        let courtNames = ["Page", "Knight", "Queen", "King"]
        let courtKeywords: [[String]] = [
            ["curiosity", "message", "new energy"],
            ["action", "adventure", "pursuit"],
            ["nurturing", "mastery", "intuition"],
            ["leadership", "authority", "wisdom"],
        ]

        for suit in Suit.allCases {
            let suitWord = suit.displayName
            let suitLower = suit.rawValue

            // Numbered cards (Ace through 10)
            let numberedData: [(String, [String], String)] = [
                ("Ace", ["new beginning", "potential", "opportunity"],
                 "A powerful new beginning in the realm of \(suitLower)"),
                ("Two", ["balance", "partnership", "duality"],
                 "Partnership and balance in \(suitLower) energy"),
                ("Three", ["growth", "collaboration", "creativity"],
                 "Growth and expansion through \(suitLower)"),
                ("Four", ["stability", "foundation", "rest"],
                 "Stability and contemplation in \(suitLower)"),
                ("Five", ["conflict", "challenge", "change"],
                 "Challenge and conflict in \(suitLower) realm"),
                ("Six", ["harmony", "generosity", "nostalgia"],
                 "Harmony and giving in \(suitLower) energy"),
                ("Seven", ["assessment", "perseverance", "vision"],
                 "Assessment and patience in \(suitLower)"),
                ("Eight", ["movement", "speed", "mastery"],
                 "Rapid movement and mastery of \(suitLower)"),
                ("Nine", ["fulfillment", "attainment", "solitude"],
                 "Near completion and fulfillment in \(suitLower)"),
                ("Ten", ["completion", "ending", "legacy"],
                 "Completion and culmination of \(suitLower) cycle"),
            ]

            for (numName, keywords, meaning) in numberedData {
                cards.append(TarotCard(
                    id: nextId, name: "\(numName) of \(suitWord)", arcana: .minor, suit: suit,
                    keywords: keywords, meaning: meaning,
                    imageName: "tarot_\(suitLower)_\(numName.lowercased())"
                ))
                nextId += 1
            }

            // Court cards
            for (i, court) in courtNames.enumerated() {
                cards.append(TarotCard(
                    id: nextId, name: "\(court) of \(suitWord)", arcana: .minor, suit: suit,
                    keywords: courtKeywords[i],
                    meaning: "\(court) energy channeled through \(suitLower)",
                    imageName: "tarot_\(suitLower)_\(court.lowercased())"
                ))
                nextId += 1
            }
        }

        return cards
    }()
}

struct DrawnCard: Identifiable {
    let id = UUID()
    let card: TarotCard
}
