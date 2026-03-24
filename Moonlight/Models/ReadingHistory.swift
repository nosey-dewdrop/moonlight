import Foundation

struct ReadingRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let question: String
    let type: ReadingType // tarot or horary

    enum ReadingType: String, Codable {
        case tarot
        case horary
    }

    init(question: String, type: ReadingType) {
        self.id = UUID()
        self.date = Date()
        self.question = question
        self.type = type
    }
}

class ReadingHistory {
    static let shared = ReadingHistory()
    private let key = "com.damla.moonlight.readingHistory"
    private let maxRecords = 50

    private init() {}

    var records: [ReadingRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ReadingRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    func add(question: String, type: ReadingRecord.ReadingType) {
        var all = records
        all.insert(ReadingRecord(question: question, type: type), at: 0)
        if all.count > maxRecords { all = Array(all.prefix(maxRecords)) }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Returns a prompt-friendly summary of recent readings
    var promptDescription: String {
        let recent = records.prefix(15)
        guard !recent.isEmpty else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"

        let lines = recent.map { record in
            "\(formatter.string(from: record.date)): \"\(record.question)\" (\(record.type.rawValue))"
        }

        return "Bu kişinin son okumaları:\n" + lines.joined(separator: "\n")
    }
}
