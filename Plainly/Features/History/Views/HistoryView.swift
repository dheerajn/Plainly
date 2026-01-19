import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            AppBackground()
            
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
                                    if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: AppLayout.smallIconSize, height: AppLayout.smallIconSize)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: icon(for: item.type))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.background)
                                            .frame(width: AppLayout.smallIconSize, height: AppLayout.smallIconSize)
                                            .background(color(for: item.type))
                                            .clipShape(Circle())
                                    }
                                    
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
                                                .cornerRadius(AppLayout.extraSmallCornerRadius)
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
        case .document: return "doc.text.fill"
        case .code: return "curlybraces"
        }
    }
    
    func color(for type: HistoryItem.HistoryType) -> Color {
        switch type {
        case .text: return .primary.opacity(0.8)
        case .url: return .primary.opacity(0.6)
        case .video: return .primary.opacity(0.4)
        case .image: return .primary.opacity(0.2)
        case .document: return .primary.opacity(0.7)
        case .code: return .primary.opacity(0.5)
        }
    }
}
