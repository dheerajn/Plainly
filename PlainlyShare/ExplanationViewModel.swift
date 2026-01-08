import SwiftUI
import Combine

@MainActor
class ExplanationViewModel: ObservableObject {
    @Published var explanation: ExplanationResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedMode: ExplanationMode = .onDevice
    @Published var loadingText: String = "Loading..."
    @Published var displayInput: String?
    @Published var displayImageData: Data?
    
    private let textService = TextExplanationService()
    private let geminiService = GeminiService()
    private let youtubeRegexPattern = #"(?i)((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?"#

    init(input: ShareInput? = nil, historyItem: HistoryItem? = nil) {
        if let item = historyItem {
            // Restore from History
            self.explanation = ExplanationResult(markdown: item.resultMarkdown)
            self.displayInput = item.originalInput
            self.displayImageData = item.imageData
            self.isLoading = false
            self.selectedMode = item.isCloud ? .gemini : .onDevice
            self.loadingText = "Restored from History"
        } else if let input = input {
            configureMode(for: input)
            updateDisplayInput(for: input)
        }
    }
    
    private func updateDisplayInput(for input: ShareInput) {
        switch input {
        case .text(let text): self.displayInput = text
        case .url(let url): self.displayInput = url.absoluteString
        case .videoData: self.displayInput = "Uploaded Video"
        case .imageData: self.displayInput = "Uploaded Image"
        }
    }
    
    private func configureMode(for input: ShareInput) {
        switch input {
        case .url: self.selectedMode = .gemini
        case .videoData, .imageData: self.selectedMode = .gemini
        case .text(let text):
            self.selectedMode = isYouTubeURL(text) ? .gemini : .onDevice
        }
    }
    
    // MARK: - Cache
    private var resultCache: [ExplanationMode: String] = [:]
    private var hasSavedToHistory = false

    func processInput(_ input: ShareInput?) async {
        guard let input = input else {
            self.isLoading = false
            self.errorMessage = "No input found."
            return
        }
        
        // Check Cache first
        if let cachedResult = resultCache[selectedMode] {
            self.explanation = ExplanationResult(markdown: cachedResult)
            self.isLoading = false
            self.errorMessage = nil
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.explanation = nil
        updateLoadingText(for: input)
        
        do {
            let markdown: String
            switch input {
            case .text(let text):
                if let youtubeURL = extractYouTubeURL(from: text) {
                    markdown = try await geminiService.explainVideo(url: youtubeURL)
                } else if selectedMode == .gemini {
                    markdown = try await geminiService.explainText(text: text)
                } else {
                    let result = try await textService.explain(text: text)
                    markdown = result.markdown
                }
            case .url(let url):
                if isYouTubeURL(url.absoluteString) {
                    markdown = try await geminiService.explainVideo(url: url)
                } else {
                    markdown = try await geminiService.explainText(text: url.absoluteString)
                }
            case .videoData(let data):
                markdown = try await geminiService.explainVideoData(data: data)
            case .imageData(let data):
                markdown = try await geminiService.explainImage(data: data)
            }
            
            // Update Cache
            resultCache[selectedMode] = markdown
            
            self.explanation = ExplanationResult(markdown: markdown)
            self.isLoading = false
            
            // SAVE TO HISTORY (Only if it's the first save for this session/request)
            if !hasSavedToHistory {
                saveToHistory(input: input, markdown: markdown)
                hasSavedToHistory = true
            }
            
        } catch {
            self.errorMessage = "Failed: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    private func saveToHistory(input: ShareInput, markdown: String) {
        let historyType: HistoryItem.HistoryType
        let historyText: String
        
        switch input {
        case .text(let text):
            historyType = .text
            historyText = text
        case .url(let url):
            historyType = .url
            historyText = url.absoluteString
        case .videoData:
            historyType = .video
            historyText = "Video File Upload"
        case .imageData:
            historyType = .image
            historyText = "Image File Upload"
        }
        
        let item = HistoryItem(
            date: Date(),
            inputTitle: historyType == .text ? String(historyText.prefix(40)) : historyType.rawValue.capitalized,
            originalInput: historyText,
            resultMarkdown: markdown,
            isCloud: self.selectedMode == .gemini,
            type: historyType,
            imageData: {
                if case .imageData(let data) = input { return data }
                return nil
            }()
        )
        
        HistoryManager.shared.save(item)
    }
    
    func retry(input: ShareInput?) {
        Task { await processInput(input) }
    }
    
    func refresh(input: ShareInput?) {
        resultCache.removeAll()
        Task { await processInput(input) }
    }

    private func updateLoadingText(for input: ShareInput) {
        switch input {
        case .url: loadingText = "Reading Link..."
        case .videoData: loadingText = "Analyzing Video..."
        case .imageData: loadingText = "Analyzing Image..."
        case .text: loadingText = "Processing..."
        }
    }
    
    func isYouTubeURL(_ text: String) -> Bool {
        return extractYouTubeURL(from: text) != nil
    }
    
    private func extractYouTubeURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let regex = try? NSRegularExpression(pattern: youtubeRegexPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                 if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
                     return url
                 }
            }
        }
        return nil
    }
    
    func shouldShowModePicker(for input: ShareInput?) -> Bool {
        guard let input = input else { return false }
        if case .text(let text) = input {
            return !isYouTubeURL(text)
        }
        return false
    }
}
