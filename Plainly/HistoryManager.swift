import Foundation

struct HistoryItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let date: Date
    let inputTitle: String      // Short title (e.g. "YouTube Link" or first few words)
    let originalInput: String   // The full input text or URL
    let resultMarkdown: String  // The generated explanation
    let isCloud: Bool           // True = Gemini, False = On-Device
    let type: HistoryType
    let imageData: Data?        // For persistent images in history
    
    enum HistoryType: String, Codable {
        case text
        case url
        case image
        case video
    }
}

class HistoryManager {
    static let shared = HistoryManager()
    private let fileName = "explanation_history.json"
    
    private init() {}
    
    private var historyFileURL: URL? {
        // Use the Documents Directory for persistent storage
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    func save(_ item: HistoryItem) {
        var items = load()
        items.insert(item, at: 0) // Newest first
        save(items)
    }
    
    func load() -> [HistoryItem] {
        guard let url = historyFileURL, let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([HistoryItem].self, from: data)) ?? []
    }
    
    func delete(id: UUID) {
        var items = load()
        items.removeAll { $0.id == id }
        save(items)
    }
    
    func clearAll() {
        save([])
    }
    
    private func save(_ items: [HistoryItem]) {
        guard let url = historyFileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(items) {
            try? data.write(to: url)
        }
    }
}
