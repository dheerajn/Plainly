import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.white.opacity(0.95)
                .ignoresSafeArea()
            
            VStack {
                // List
                if viewModel.historyItems.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock.arrow.circlepath", description: Text("Your past explanations will appear here."))
                } else {
                    List {
                        ForEach(viewModel.historyItems) { item in
                            NavigationLink(destination: ExplanationView(historyItem: item, context: .nested, onClose: {
                                // On close inside nested, we just rely on back button, 
                                // but we provide dismiss if needed.
                            })) {
                                HStack {
                                    Image(systemName: icon(for: item.type))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(color(for: item.type))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading) {
                                        Text(item.displayTitle)
                                            .font(.headline)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                        HStack {
                                            Text(item.isCloud ? "☁️ Cloud" : "🔒 Device")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.secondary.opacity(0.1))
                                                .cornerRadius(4)
                                                .foregroundColor(.primary)
                                            
                                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete(perform: viewModel.deleteItem)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("History")
        .onAppear {
            viewModel.loadHistory()
        }
    }
    
    func icon(for type: HistoryItem.HistoryType) -> String {
        switch type {
        case .text: return "text.alignleft"
        case .url: return "link"
        case .video: return "video.fill"
        case .image: return "photo"
        }
    }
    
    func color(for type: HistoryItem.HistoryType) -> Color {
        switch type {
        case .text: return .blue
        case .url: return .green
        case .video: return .purple
        case .image: return .orange
        }
    }
}
