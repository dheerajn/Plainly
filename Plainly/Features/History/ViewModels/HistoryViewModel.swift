import SwiftUI
import Combine

class HistoryViewModel: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    
    init() {
        loadHistory()
    }
    
    func loadHistory() {
        self.historyItems = HistoryManager.shared.load()
    }
    
    func deleteItem(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = historyItems[index]
            HistoryManager.shared.delete(id: item.id)
        }
        loadHistory()
    }
}
