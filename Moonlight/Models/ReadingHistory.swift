import Foundation

struct ReadingRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let question: String
    let type: ReadingType
    var isFavorite: Bool

    enum ReadingType: String, Codable {
        case tarot
        case horary
    }

    init(question: String, type: ReadingType) {
        self.id = UUID()
        self.date = Date()
        self.question = question
        self.type = type
        self.isFavorite = false
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

    var favorites: [ReadingRecord] {
        records.filter { $0.isFavorite }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    func add(question: String, type: ReadingRecord.ReadingType) {
        var all = records
        all.insert(ReadingRecord(question: question, type: type), at: 0)
        if all.count > maxRecords { all = Array(all.prefix(maxRecords)) }
        save(all)
    }

    func delete(id: UUID) {
        var all = records
        all.removeAll { $0.id == id }
        save(all)
    }

    func toggleFavorite(id: UUID) {
        var all = records
        if let index = all.firstIndex(where: { $0.id == id }) {
            all[index].isFavorite.toggle()
        }
        save(all)
    }

    private func save(_ records: [ReadingRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
