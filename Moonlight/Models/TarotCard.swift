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
    let uprightMeaning: String
    let reversedMeaning: String
    let imageName: String

    static let allCards: [TarotCard] = majorArcana + minorArcana

    // MARK: - Major Arcana (22 cards)

    static let majorArcana: [TarotCard] = [
        TarotCard(id: 0, name: "The Fool", arcana: .major, suit: nil,
                  keywords: ["beginnings", "innocence", "adventure"],
                  uprightMeaning: "New beginnings, spontaneity, a free spirit",
                  reversedMeaning: "Recklessness, fear of the unknown, holding back",
                  imageName: "tarot_fool"),
        TarotCard(id: 1, name: "The Magician", arcana: .major, suit: nil,
                  keywords: ["willpower", "creation", "manifestation"],
                  uprightMeaning: "Manifestation, resourcefulness, inspired action",
                  reversedMeaning: "Manipulation, poor planning, untapped talents",
                  imageName: "tarot_magician"),
        TarotCard(id: 2, name: "The High Priestess", arcana: .major, suit: nil,
                  keywords: ["intuition", "mystery", "subconscious"],
                  uprightMeaning: "Intuition, sacred knowledge, the subconscious mind",
                  reversedMeaning: "Secrets, withdrawal, silence",
                  imageName: "tarot_high_priestess"),
        TarotCard(id: 3, name: "The Empress", arcana: .major, suit: nil,
                  keywords: ["abundance", "nurturing", "fertility"],
                  uprightMeaning: "Femininity, beauty, nature, abundance",
                  reversedMeaning: "Creative block, dependence, emptiness",
                  imageName: "tarot_empress"),
        TarotCard(id: 4, name: "The Emperor", arcana: .major, suit: nil,
                  keywords: ["authority", "structure", "stability"],
                  uprightMeaning: "Authority, establishment, structure, a father figure",
                  reversedMeaning: "Tyranny, rigidity, lack of discipline",
                  imageName: "tarot_emperor"),
        TarotCard(id: 5, name: "The Hierophant", arcana: .major, suit: nil,
                  keywords: ["tradition", "wisdom", "guidance"],
                  uprightMeaning: "Spiritual wisdom, religious beliefs, tradition",
                  reversedMeaning: "Personal beliefs, freedom, challenging the status quo",
                  imageName: "tarot_hierophant"),
        TarotCard(id: 6, name: "The Lovers", arcana: .major, suit: nil,
                  keywords: ["love", "harmony", "choices"],
                  uprightMeaning: "Love, harmony, relationships, values alignment",
                  reversedMeaning: "Self-love, disharmony, imbalance",
                  imageName: "tarot_lovers"),
        TarotCard(id: 7, name: "The Chariot", arcana: .major, suit: nil,
                  keywords: ["determination", "willpower", "victory"],
                  uprightMeaning: "Control, willpower, success, determination",
                  reversedMeaning: "Lack of control, opposition, no direction",
                  imageName: "tarot_chariot"),
        TarotCard(id: 8, name: "Strength", arcana: .major, suit: nil,
                  keywords: ["courage", "patience", "compassion"],
                  uprightMeaning: "Strength, courage, patience, compassion",
                  reversedMeaning: "Self-doubt, weakness, insecurity",
                  imageName: "tarot_strength"),
        TarotCard(id: 9, name: "The Hermit", arcana: .major, suit: nil,
                  keywords: ["solitude", "reflection", "inner guidance"],
                  uprightMeaning: "Soul searching, introspection, being alone",
                  reversedMeaning: "Isolation, loneliness, withdrawal",
                  imageName: "tarot_hermit"),
        TarotCard(id: 10, name: "Wheel of Fortune", arcana: .major, suit: nil,
                  keywords: ["fate", "cycles", "turning point"],
                  uprightMeaning: "Good luck, karma, life cycles, destiny",
                  reversedMeaning: "Bad luck, resistance to change, breaking cycles",
                  imageName: "tarot_wheel"),
        TarotCard(id: 11, name: "Justice", arcana: .major, suit: nil,
                  keywords: ["truth", "fairness", "law"],
                  uprightMeaning: "Justice, fairness, truth, cause and effect",
                  reversedMeaning: "Unfairness, dishonesty, lack of accountability",
                  imageName: "tarot_justice"),
        TarotCard(id: 12, name: "The Hanged Man", arcana: .major, suit: nil,
                  keywords: ["surrender", "perspective", "pause"],
                  uprightMeaning: "Pause, surrender, letting go, new perspectives",
                  reversedMeaning: "Delays, resistance, stalling, indecision",
                  imageName: "tarot_hanged_man"),
        TarotCard(id: 13, name: "Death", arcana: .major, suit: nil,
                  keywords: ["endings", "transformation", "transition"],
                  uprightMeaning: "Endings, change, transformation, transition",
                  reversedMeaning: "Resistance to change, personal transformation",
                  imageName: "tarot_death"),
        TarotCard(id: 14, name: "Temperance", arcana: .major, suit: nil,
                  keywords: ["balance", "moderation", "patience"],
                  uprightMeaning: "Balance, moderation, patience, finding meaning",
                  reversedMeaning: "Imbalance, excess, self-healing",
                  imageName: "tarot_temperance"),
        TarotCard(id: 15, name: "The Devil", arcana: .major, suit: nil,
                  keywords: ["shadow", "attachment", "excess"],
                  uprightMeaning: "Shadow self, attachment, addiction, restriction",
                  reversedMeaning: "Releasing limiting beliefs, exploring dark thoughts",
                  imageName: "tarot_devil"),
        TarotCard(id: 16, name: "The Tower", arcana: .major, suit: nil,
                  keywords: ["upheaval", "revelation", "awakening"],
                  uprightMeaning: "Sudden change, upheaval, chaos, revelation",
                  reversedMeaning: "Personal transformation, fear of change",
                  imageName: "tarot_tower"),
        TarotCard(id: 17, name: "The Star", arcana: .major, suit: nil,
                  keywords: ["hope", "faith", "renewal"],
                  uprightMeaning: "Hope, faith, purpose, renewal, spirituality",
                  reversedMeaning: "Lack of faith, despair, disconnection",
                  imageName: "tarot_star"),
        TarotCard(id: 18, name: "The Moon", arcana: .major, suit: nil,
                  keywords: ["illusion", "intuition", "unconscious"],
                  uprightMeaning: "Illusion, fear, anxiety, subconscious, intuition",
                  reversedMeaning: "Release of fear, repressed emotion, inner confusion",
                  imageName: "tarot_moon"),
        TarotCard(id: 19, name: "The Sun", arcana: .major, suit: nil,
                  keywords: ["joy", "success", "vitality"],
                  uprightMeaning: "Positivity, fun, warmth, success, vitality",
                  reversedMeaning: "Inner child, feeling down, overly optimistic",
                  imageName: "tarot_sun"),
        TarotCard(id: 20, name: "Judgement", arcana: .major, suit: nil,
                  keywords: ["reflection", "reckoning", "rebirth"],
                  uprightMeaning: "Judgement, rebirth, inner calling, absolution",
                  reversedMeaning: "Self-doubt, inner critic, ignoring the call",
                  imageName: "tarot_judgement"),
        TarotCard(id: 21, name: "The World", arcana: .major, suit: nil,
                  keywords: ["completion", "achievement", "wholeness"],
                  uprightMeaning: "Completion, integration, accomplishment, travel",
                  reversedMeaning: "Seeking personal closure, shortcuts, delays",
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
            let numberedData: [(String, [String], String, String)] = [
                ("Ace", ["new beginning", "potential", "opportunity"],
                 "A powerful new beginning in the realm of \(suitLower)",
                 "Missed opportunity, delays in \(suitLower) matters"),
                ("Two", ["balance", "partnership", "duality"],
                 "Partnership and balance in \(suitLower) energy",
                 "Imbalance, indecision in \(suitLower) matters"),
                ("Three", ["growth", "collaboration", "creativity"],
                 "Growth and expansion through \(suitLower)",
                 "Overextension, lack of progress"),
                ("Four", ["stability", "foundation", "rest"],
                 "Stability and contemplation in \(suitLower)",
                 "Restlessness, stagnation"),
                ("Five", ["conflict", "challenge", "change"],
                 "Challenge and conflict in \(suitLower) realm",
                 "Resolution, compromise, moving past conflict"),
                ("Six", ["harmony", "generosity", "nostalgia"],
                 "Harmony and giving in \(suitLower) energy",
                 "Strings attached, one-sided generosity"),
                ("Seven", ["assessment", "perseverance", "vision"],
                 "Assessment and patience in \(suitLower)",
                 "Impatience, lack of long-term vision"),
                ("Eight", ["movement", "speed", "mastery"],
                 "Rapid movement and mastery of \(suitLower)",
                 "Slowdown, scattered energy in \(suitLower)"),
                ("Nine", ["fulfillment", "attainment", "solitude"],
                 "Near completion and fulfillment in \(suitLower)",
                 "Inner work needed, unfulfillment"),
                ("Ten", ["completion", "ending", "legacy"],
                 "Completion and culmination of \(suitLower) cycle",
                 "Carrying too much, need to release"),
            ]

            for (numName, keywords, upright, reversed) in numberedData {
                cards.append(TarotCard(
                    id: nextId, name: "\(numName) of \(suitWord)", arcana: .minor, suit: suit,
                    keywords: keywords, uprightMeaning: upright, reversedMeaning: reversed,
                    imageName: "tarot_\(suitLower)_\(numName.lowercased())"
                ))
                nextId += 1
            }

            // Court cards
            for (i, court) in courtNames.enumerated() {
                cards.append(TarotCard(
                    id: nextId, name: "\(court) of \(suitWord)", arcana: .minor, suit: suit,
                    keywords: courtKeywords[i],
                    uprightMeaning: "\(court) energy channeled through \(suitLower)",
                    reversedMeaning: "Immature or blocked \(court.lowercased()) energy in \(suitLower)",
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
    let isReversed: Bool

    var meaning: String {
        isReversed ? card.reversedMeaning : card.uprightMeaning
    }

    var positionLabel: String {
        isReversed ? "Reversed" : "Upright"
    }
}
